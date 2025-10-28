from __future__ import annotations

from datetime import timedelta
from decimal import Decimal

from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient, APITestCase

from sankofa_backend.apps.accounts.models import User
from sankofa_backend.apps.admin_api.models import AuditLog
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

    def test_groups_list_includes_membership_and_invite_counts(self):
        self.authenticate()
        url = reverse("admin-api:admin-groups-list")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 1)
        group_payload = response.data["results"][0]
        self.assertEqual(group_payload["member_count"], 1)
        self.assertEqual(group_payload["pending_invites"], 1)

        search_response = self.client.get(url, {"search": "Downtown"})
        self.assertEqual(search_response.data["count"], 1)

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
