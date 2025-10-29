from __future__ import annotations

from datetime import timedelta
from decimal import Decimal

from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient, APITestCase

from sankofa_backend.apps.accounts.models import User
from sankofa_backend.apps.admin_api.models import AuditLog
from sankofa_backend.apps.disputes.models import Dispute, DisputeMessage, SupportArticle
from sankofa_backend.apps.groups.models import Group, GroupInvite, GroupMembership
from sankofa_backend.apps.savings.models import SavingsGoal
from sankofa_backend.apps.transactions.models import Transaction, Wallet


class AdminApiTests(APITestCase):
    def setUp(self) -> None:
        self.staff_user = User.objects.create_user(
            phone_number="+233201111111",
            password="adminpass",
            full_name="Admin User",
            email="admin@example.com",
            is_staff=True,
        )
        self.member = User.objects.create_user(
            phone_number="+233202222222",
            password="memberpass",
            full_name="Member User",
            email="member@example.com",
        )
        Wallet.objects.ensure_for_user(self.member)

        now = timezone.now()
        self.group = Group.objects.create(
            name="Downtown Susu",
            description="Weekly contributions",
            frequency="weekly",
            location="Accra",
            requires_approval=False,
            is_public=True,
            target_member_count=10,
            contribution_amount=Decimal("200.00"),
            cycle_number=1,
            total_cycles=6,
            next_payout_date=now + timedelta(days=7),
            payout_order="[]",
            owner=self.staff_user,
        )
        GroupMembership.objects.create(
            group=self.group,
            user=self.member,
            display_name="Member User",
        )
        GroupInvite.objects.create(
            group=self.group,
            name="Prospective Member",
            phone_number="+233203333333",
        )

        self.goal = SavingsGoal.objects.create(
            user=self.member,
            title="Travel Fund",
            target_amount=Decimal("1000.00"),
            current_amount=Decimal("250.00"),
            deadline=now + timedelta(days=45),
            category="travel",
        )

        self.pending_deposit = Transaction.objects.create(
            user=self.member,
            transaction_type=Transaction.TYPE_DEPOSIT,
            status=Transaction.STATUS_PENDING,
            amount=Decimal("500.00"),
            description="Initial deposit",
            occurred_at=now - timedelta(days=1),
            reference="DEP-001",
            channel="Mobile Money",
            group=self.group,
        )
        self.failed_withdrawal = Transaction.objects.create(
            user=self.member,
            transaction_type=Transaction.TYPE_WITHDRAWAL,
            status=Transaction.STATUS_FAILED,
            amount=Decimal("1600.00"),
            description="Large withdrawal",
            occurred_at=now,
            reference="WD-002",
            channel="Bank Transfer",
        )

        self.support_article = SupportArticle.objects.create(
            slug="faq-contribution-missing-payment",
            category="Wallet & Cashflow",
            title="Reconcile a missing contribution payment",
            summary="Checklist for verifying MoMo receipts when contributions fail to post.",
            link="https://support.sankofa/disputes/missing-contribution",
            tags=["MoMo", "Ledger"],
        )

        self.dispute = Dispute.objects.create(
            title="Missing Contribution",
            description="Member reports a missing contribution.",
            category="Wallet & Cashflow",
            severity=Dispute.Severity.CRITICAL,
            priority=Dispute.Priority.HIGH,
            channel=Dispute.Channel.MOBILE_APP,
            user=self.member,
            group=self.group,
            assigned_to=self.staff_user,
            sla_due=now + timedelta(hours=6),
            related_article=self.support_article,
        )
        DisputeMessage.objects.create(
            dispute=self.dispute,
            author=self.member,
            role=DisputeMessage.Role.MEMBER,
            channel="Mobile App",
            message="I sent my contribution but it is missing.",
        )

        self.client = APIClient()

    def authenticate(self):
        response = self.client.post(
            reverse("admin-api:admin-auth-token"),
            {"identifier": self.staff_user.email, "password": "adminpass"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        token = response.data["access"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

    def test_admin_login_requires_staff(self):
        response = self.client.post(
            reverse("admin-api:admin-auth-token"),
            {"identifier": self.member.phone_number, "password": "memberpass"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_user_list_requires_authentication(self):
        url = reverse("admin-api:admin-users-list")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_user_list_and_update_flow(self):
        self.authenticate()
        list_url = reverse("admin-api:admin-users-list")
        response = self.client.get(list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(response.data["count"], 2)
        user_id = response.data["results"][0]["id"]

        detail_url = reverse("admin-api:admin-users-detail", args=[user_id])
        detail_response = self.client.get(detail_url)
        self.assertEqual(detail_response.status_code, status.HTTP_200_OK)
        self.assertIn("recent_transactions", detail_response.data)

        patch_response = self.client.patch(detail_url, {"kyc_status": "approved"}, format="json")
        self.assertEqual(patch_response.status_code, status.HTTP_200_OK)
        self.assertEqual(patch_response.data["kyc_status"], "approved")

        audit_log = AuditLog.objects.filter(
            action="user.updated",
            target_id=str(user_id),
        ).first()
        self.assertIsNotNone(audit_log)
        self.assertEqual(audit_log.changes.get("kyc_status"), "approved")

    def test_dashboard_metrics(self):
        self.authenticate()
        url = reverse("admin-api:admin-dashboard")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("kpis", response.data)
        self.assertIn("active_members", response.data["kpis"])
        self.assertIn("current", response.data["kpis"]["active_members"])
        self.assertIn("previous", response.data["kpis"]["active_members"])
        self.assertIn("notifications", response.data)
        self.assertIn("upcoming_payouts", response.data)
        if response.data["upcoming_payouts"]:
            sample = response.data["upcoming_payouts"][0]
            self.assertIn("description", sample)
            self.assertIn("status", sample)

    def test_groups_list_includes_membership_and_invite_counts(self):
        self.authenticate()
        url = reverse("admin-api:admin-groups-list")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 1)
        group_payload = response.data["results"][0]
        self.assertEqual(group_payload["member_count"], 1)
        self.assertEqual(group_payload["pending_invites"], 1)
        self.assertIn("members", group_payload)
        self.assertEqual(len(group_payload["members"]), 1)
        self.assertEqual(group_payload["members"][0]["phone_number"], self.member.phone_number)

        search_response = self.client.get(url, {"search": "Downtown"})
        self.assertEqual(search_response.data["count"], 1)

    def test_admin_can_create_update_and_delete_public_group(self):
        self.authenticate()
        url = reverse("admin-api:admin-groups-list")
        next_payout = (timezone.now() + timedelta(days=3)).isoformat()
        payload = {
            "name": "Sunrise Traders",
            "description": "Market women collective",
            "frequency": "weekly",
            "location": "Kumasi",
            "contribution_amount": "150.00",
            "target_member_count": 8,
            "next_payout_date": next_payout,
        }

        response = self.client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        group_id = response.data["id"]
        self.assertTrue(Group.objects.filter(pk=group_id).exists())
        self.assertTrue(response.data["is_public"])

        patch_payload = {"location": "Kumasi Central", "target_member_count": 10}
        detail_url = reverse("admin-api:admin-groups-detail", args=[group_id])
        patch_response = self.client.patch(detail_url, patch_payload, format="json")
        self.assertEqual(patch_response.status_code, status.HTTP_200_OK)
        self.assertEqual(patch_response.data["location"], "Kumasi Central")
        self.assertEqual(patch_response.data["target_member_count"], 10)

        delete_response = self.client.delete(detail_url)
        self.assertEqual(delete_response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Group.objects.filter(pk=group_id).exists())

    def test_admin_disputes_list_and_detail(self):
        self.authenticate()
        list_url = reverse("admin-api:admin-disputes-list")
        response = self.client.get(list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(response.data["count"], 1)
        sample = response.data["results"][0]
        self.assertIn("case_number", sample)
        self.assertEqual(sample["member_name"], self.member.full_name)

        detail_url = reverse("admin-api:admin-disputes-detail", args=[self.dispute.pk])
        detail_response = self.client.get(detail_url)
        self.assertEqual(detail_response.status_code, status.HTTP_200_OK)
        self.assertIn("messages", detail_response.data)
        self.assertEqual(detail_response.data["messages"][0]["message"], "I sent my contribution but it is missing.")

    def test_admin_support_articles_list(self):
        self.authenticate()
        url = reverse("admin-api:admin-support-articles-list")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(response.data), 1)

    def test_admin_can_manage_group_invites_and_members(self):
        self.authenticate()
        url = reverse("admin-api:admin-groups-list")
        next_payout = (timezone.now() + timedelta(days=5)).isoformat()
        create_response = self.client.post(
            url,
            {
                "name": "Evening Circle",
                "description": "Retail Susu",
                "contribution_amount": "75.00",
                "target_member_count": 5,
                "next_payout_date": next_payout,
            },
            format="json",
        )
        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)
        group_id = create_response.data["id"]

        invite_url = reverse("admin-api:admin-groups-create-invites", args=[group_id])
        invite_response = self.client.post(
            invite_url,
            {"invites": [{"name": "New Member", "phone_number": "+233209999999"}]},
            format="json",
        )
        self.assertEqual(invite_response.status_code, status.HTTP_200_OK)
        invites = invite_response.data["invites"]
        self.assertEqual(len(invites), 1)
        invite_id = invites[0]["id"]

        approve_url = reverse("admin-api:admin-groups-approve-invite", args=[group_id, invite_id])
        approve_response = self.client.post(approve_url, {}, format="json")
        self.assertEqual(approve_response.status_code, status.HTTP_200_OK)
        self.assertEqual(approve_response.data["member_count"], 1)
        self.assertEqual(len(approve_response.data["members"]), 1)
        self.assertEqual(approve_response.data["invites"][0]["status"], GroupInvite.STATUS_ACCEPTED)

        decline_url = reverse("admin-api:admin-groups-decline-invite", args=[group_id, invite_id])
        decline_response = self.client.post(decline_url, {}, format="json")
        self.assertEqual(decline_response.status_code, status.HTTP_200_OK)
        self.assertEqual(decline_response.data["invites"][0]["status"], GroupInvite.STATUS_DECLINED)

        remove_url = reverse("admin-api:admin-groups-remove-member", args=[group_id, approve_response.data["members"][0]["id"]])
        remove_response = self.client.delete(remove_url)
        self.assertEqual(remove_response.status_code, status.HTTP_200_OK)
        self.assertEqual(remove_response.data["member_count"], 0)

    def test_savings_goals_list_filters_by_user(self):
        self.authenticate()
        url = reverse("admin-api:admin-savings-goals-list")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(response.data["count"], 1)

        filter_response = self.client.get(url, {"user": str(self.member.id)})
        self.assertEqual(filter_response.status_code, status.HTTP_200_OK)
        self.assertEqual(filter_response.data["count"], 1)
        goal_payload = filter_response.data["results"][0]
        self.assertEqual(goal_payload["title"], "Travel Fund")

    def test_transactions_endpoint_supports_filters(self):
        self.authenticate()
        url = reverse("admin-api:admin-transactions-list")
        response = self.client.get(url, {"type": Transaction.TYPE_DEPOSIT})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(response.data["count"], 1)
        for result in response.data["results"]:
            self.assertEqual(result["transaction_type"], Transaction.TYPE_DEPOSIT)

        search_response = self.client.get(url, {"search": "WD-002"})
        self.assertEqual(search_response.data["count"], 1)
        self.assertEqual(search_response.data["results"][0]["transaction_type"], Transaction.TYPE_WITHDRAWAL)

    def test_cashflow_queue(self):
        self.authenticate()
        url = reverse("admin-api:admin-cashflow-queues")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("deposits", response.data)
        self.assertIn("withdrawals", response.data)
        self.assertEqual(len(response.data["deposits"]), 1)
        self.assertEqual(len(response.data["withdrawals"]), 1)

        deposit_entry = response.data["deposits"][0]
        self.assertEqual(deposit_entry["reference"], "DEP-001")
        self.assertEqual(deposit_entry["risk"], "Low")

        withdrawal_entry = response.data["withdrawals"][0]
        self.assertEqual(withdrawal_entry["reference"], "WD-002")
        self.assertEqual(withdrawal_entry["risk"], "High")
