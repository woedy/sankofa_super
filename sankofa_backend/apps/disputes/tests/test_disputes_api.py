from __future__ import annotations

from datetime import timedelta

from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient, APITestCase

from sankofa_backend.apps.accounts.models import User
from sankofa_backend.apps.disputes.models import Dispute, DisputeMessage
from sankofa_backend.apps.groups.models import Group


class DisputeApiTests(APITestCase):
    def setUp(self) -> None:
        self.member = User.objects.create_user(
            phone_number="+233500000001",
            password="memberpass",
            full_name="Member One",
            email="member1@example.com",
        )
        self.other_member = User.objects.create_user(
            phone_number="+233500000002",
            password="memberpass",
            full_name="Member Two",
            email="member2@example.com",
        )
        self.staff_user = User.objects.create_user(
            phone_number="+233500000010",
            password="staffpass",
            full_name="Admin User",
            email="admin@example.com",
            is_staff=True,
        )
        now = timezone.now()
        self.group = Group.objects.create(
            name="Downtown Investors",
            description="Weekly contributions",
            frequency="weekly",
            location="Accra",
            requires_approval=False,
            is_public=True,
            target_member_count=10,
            contribution_amount="200.00",
            cycle_number=1,
            total_cycles=6,
            next_payout_date=now + timedelta(days=7),
            payout_order="[]",
            owner=self.staff_user,
        )
        self.client = APIClient()

    def authenticate(self, user: User):
        self.client.force_authenticate(user=user)

    def test_requires_authentication(self):
        url = reverse("disputes:disputes-list")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_member_can_create_and_list_disputes(self):
        self.authenticate(self.member)
        list_url = reverse("disputes:disputes-list")
        payload = {
            "title": "Missing payout",
            "description": "My payout did not arrive",
            "category": "Wallet & Cashflow",
            "severity": Dispute.Severity.HIGH,
            "priority": Dispute.Priority.HIGH,
            "channel": Dispute.Channel.MOBILE_APP,
            "group": str(self.group.pk),
            "initial_message": "I am missing my GH₵ 200 contribution.",
        }
        response = self.client.post(list_url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        dispute_id = response.data["id"]
        self.assertTrue(Dispute.objects.filter(pk=dispute_id).exists())
        dispute = Dispute.objects.get(pk=dispute_id)
        self.assertEqual(dispute.messages.count(), 1)

        list_response = self.client.get(list_url)
        self.assertEqual(list_response.status_code, status.HTTP_200_OK)
        self.assertEqual(list_response.data["count"], 1)
        self.assertEqual(list_response.data["results"][0]["title"], "Missing payout")

    def test_member_only_sees_own_disputes(self):
        self.authenticate(self.member)
        dispute = Dispute.objects.create(
            title="Duplicate deduction",
            description="Charged twice",
            category="Wallet",
            severity=Dispute.Severity.MEDIUM,
            priority=Dispute.Priority.MEDIUM,
            channel=Dispute.Channel.MOBILE_APP,
            user=self.other_member,
        )
        DisputeMessage.objects.create(
            dispute=dispute,
            author=self.other_member,
            role=DisputeMessage.Role.MEMBER,
            channel="Mobile App",
            message="My wallet shows two deductions.",
        )

        list_url = reverse("disputes:disputes-list")
        response = self.client.get(list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 0)
