from __future__ import annotations

from decimal import Decimal
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from sankofa_backend.apps.groups.models import Group, GroupInvite, GroupMembership

User = get_user_model()


class GroupAPITests(APITestCase):
    def setUp(self) -> None:
        self.user = User.objects.create_user(phone_number="0240000000", full_name="Test User")
        self.client.force_authenticate(self.user)

    def _create_group(self, **overrides) -> Group:
        now = timezone.now()
        defaults = {
            "name": "Unity Savers Group",
            "description": "Weekly circle",
            "frequency": "Weekly contributions",
            "location": "Accra",
            "requires_approval": True,
            "is_public": False,
            "target_member_count": 5,
            "contribution_amount": "200.00",
            "cycle_number": 2,
            "total_cycles": 5,
            "next_payout_date": now + timedelta(days=7),
            "payout_order": "Rotating (Weekly)",
        }
        defaults.update(overrides)
        return Group.objects.create(**defaults)

    def test_list_returns_member_and_public_groups(self):
        group_member = self._create_group(name="Member Circle")
        GroupMembership.objects.create(
            group=group_member,
            user=self.user,
            display_name=self.user.full_name,
        )

        group_public = self._create_group(name="Public Circle", is_public=True)
        GroupInvite.objects.create(
            group=group_public,
            name="Ama Darko",
            phone_number="+233200000001",
            status=GroupInvite.STATUS_PENDING,
        )

        url = reverse("groups:group-list")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        payload = response.json()
        self.assertEqual(len(payload), 2)

        member_group = next(item for item in payload if item["name"] == "Member Circle")
        self.assertIn(str(self.user.id), member_group["memberIds"])
        self.assertIn(self.user.full_name, member_group["memberNames"])

        public_group = next(item for item in payload if item["name"] == "Public Circle")
        self.assertEqual(public_group["invites"][0]["name"], "Ama Darko")
        self.assertTrue(public_group["isPublic"])

    def test_join_public_group_adds_membership(self):
        other_user = User.objects.create_user(phone_number="0241111111", full_name="Kwame")
        group = self._create_group(name="Open Circle", is_public=True)
        GroupMembership.objects.create(group=group, user=other_user, display_name="Kwame")

        url = reverse("groups:group-join", kwargs={"pk": group.pk})
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertIn(str(self.user.id), data["memberIds"])
        self.assertEqual(group.memberships.count(), 2)

    def test_join_fails_when_group_full(self):
        group = self._create_group(name="Full Circle", is_public=True, target_member_count=1)
        GroupMembership.objects.create(
            group=group,
            user=User.objects.create_user(phone_number="0242222222", full_name="Akosua"),
            display_name="Akosua",
        )

        url = reverse("groups:group-join", kwargs={"pk": group.pk})
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.json()["detail"], "This group is already at capacity.")

    def test_leave_group_removes_membership(self):
        group = self._create_group(name="Exit Circle", is_public=True)
        GroupMembership.objects.create(group=group, user=self.user, display_name=self.user.full_name)

        url = reverse("groups:group-leave", kwargs={"pk": group.pk})
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertNotIn(str(self.user.id), response.json()["memberIds"])
        self.assertFalse(group.memberships.filter(user=self.user).exists())

    def test_create_group_persists_invites_and_membership(self):
        payload = {
            "name": "Akwaba Circle",
            "description": "Private susu for market day",
            "contributionAmount": "150.00",
            "frequency": "Weekly",
            "startDate": (timezone.now() + timedelta(days=3)).isoformat(),
            "invites": [
                {"name": "Ama Darko", "phoneNumber": "+233200000001"},
                {"name": "Yaw Mensah", "phoneNumber": "+233200000002"},
            ],
        }

        response = self.client.post(reverse("groups:group-list"), data=payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        data = response.json()

        group = Group.objects.get(pk=data["id"])
        self.assertEqual(group.name, "Akwaba Circle")
        self.assertEqual(group.target_member_count, 3)
        self.assertEqual(group.contribution_amount, Decimal("150.00"))
        self.assertTrue(group.memberships.filter(user=self.user).exists())
        self.assertEqual(group.invites.count(), 2)

    def test_remind_invite_updates_metadata(self):
        group = self._create_group(name="Reminder Circle", is_public=False)
        invite = GroupInvite.objects.create(
            group=group,
            name="Kweku Boateng",
            phone_number="+233200000010",
        )

        url = reverse("groups:group-remind-invite", kwargs={"pk": group.pk, "invite_id": invite.pk})
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        invite.refresh_from_db()
        self.assertIsNotNone(invite.last_reminded_at)
        self.assertEqual(invite.reminder_count, 1)

    def test_update_invite_status_changes_state(self):
        group = self._create_group(name="Status Circle", is_public=False)
        invite = GroupInvite.objects.create(
            group=group,
            name="Afia",
            phone_number="+233200000020",
        )

        url = reverse("groups:group-update-invite-status", kwargs={"pk": group.pk, "invite_id": invite.pk})
        response = self.client.post(url, data={"status": GroupInvite.STATUS_DECLINED}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        invite.refresh_from_db()
        self.assertEqual(invite.status, GroupInvite.STATUS_DECLINED)
        self.assertIsNotNone(invite.responded_at)

    def test_promote_invite_creates_membership(self):
        group = self._create_group(name="Promotion Circle", is_public=False)
        invite = GroupInvite.objects.create(
            group=group,
            name="Yaw",
            phone_number="+233200000030",
        )

        url = reverse("groups:group-promote-invite", kwargs={"pk": group.pk, "invite_id": invite.pk})
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        invite.refresh_from_db()
        self.assertEqual(invite.status, GroupInvite.STATUS_ACCEPTED)
        self.assertTrue(
            GroupMembership.objects.filter(group=group, user__phone_number="+233200000030").exists()
        )
