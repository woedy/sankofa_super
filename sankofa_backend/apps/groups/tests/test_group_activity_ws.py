from __future__ import annotations

from decimal import Decimal

from asgiref.sync import async_to_sync, sync_to_async
from channels.testing import WebsocketCommunicator
from django.contrib.auth import get_user_model
from django.test import TransactionTestCase, override_settings
from django.utils import timezone
from rest_framework_simplejwt.tokens import AccessToken

from core.asgi import application
from sankofa_backend.apps.groups.models import Group, GroupMembership
from sankofa_backend.apps.groups.realtime import broadcast_group_event, group_channel_name


@override_settings(
    CHANNEL_LAYERS={"default": {"BACKEND": "channels.layers.InMemoryChannelLayer"}}
)
class GroupActivityConsumerTests(TransactionTestCase):
    def setUp(self):
        User = get_user_model()
        self.user = User.objects.create_user(
            phone_number="+233200000001",
            password="testpass123",
        )
        self.other_user = User.objects.create_user(
            phone_number="+233200000002",
            password="testpass123",
        )
        self.group = Group.objects.create(
            name="Evening Susu",
            description="Rotating savings",
            frequency="Weekly",
            location="Accra",
            requires_approval=False,
            is_public=True,
            target_member_count=5,
            contribution_amount=Decimal("100.00"),
            cycle_number=1,
            total_cycles=5,
            next_payout_date=timezone.now(),
            payout_order="",
        )
        GroupMembership.objects.create(
            group=self.group,
            user=self.user,
            display_name="Ama",
        )

    def _build_token(self, user):
        return str(AccessToken.for_user(user))

    def test_member_receives_group_events(self):
        token = self._build_token(self.user)
        payload = {"message": "hello"}

        async def scenario():
            communicator = WebsocketCommunicator(
                application, f"/ws/groups/{self.group.id}/?token={token}"
            )
            connected, _ = await communicator.connect()
            self.assertTrue(connected)

            await sync_to_async(broadcast_group_event, thread_sensitive=True)(
                group_id=self.group.id,
                event="group.test",
                payload=payload,
            )

            response = await communicator.receive_json_from()
            await communicator.disconnect()
            return response

        response = async_to_sync(scenario)()
        self.assertEqual(response["type"], "group.test")
        self.assertEqual(response["payload"], payload)

    def test_non_members_are_rejected(self):
        token = self._build_token(self.other_user)

        async def scenario():
            communicator = WebsocketCommunicator(
                application, f"/ws/groups/{self.group.id}/?token={token}"
            )
            connected, _ = await communicator.connect()
            await communicator.disconnect()
            return connected

        connected = async_to_sync(scenario)()
        self.assertFalse(connected)

    def test_group_channel_name_helper(self):
        channel_name = group_channel_name(self.group.id)
        expected = f"group_activity_{self.group.id}"
        self.assertEqual(channel_name, expected)
