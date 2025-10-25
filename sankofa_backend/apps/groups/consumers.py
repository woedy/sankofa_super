"""Channels consumer streaming group activity updates."""
from __future__ import annotations

from typing import Any

from asgiref.sync import sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from django.contrib.auth.models import AnonymousUser

from .models import GroupMembership
from .realtime import group_channel_name


class GroupActivityConsumer(AsyncJsonWebsocketConsumer):
    """Streams membership and savings activity to connected group members."""

    async def connect(self) -> None:  # pragma: no cover - exercised via tests
        user = self.scope.get("user")
        if user is None or isinstance(user, AnonymousUser) or user.is_anonymous:
            await self.close(code=4401)
            return

        group_id = self.scope["url_route"]["kwargs"]["group_id"]
        self.group_id = str(group_id)
        self.group_name = group_channel_name(self.group_id)

        is_member = await self._user_can_subscribe(user_id=user.id, group_id=self.group_id)
        if not is_member:
            await self.close(code=4403)
            return

        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, code: int) -> None:  # pragma: no cover - exercised via framework
        if hasattr(self, "group_name"):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def group_activity(self, event: dict[str, Any]) -> None:
        await self.send_json({"type": event["event"], "payload": event.get("payload", {})})

    @sync_to_async
    def _user_can_subscribe(self, *, user_id: str, group_id: str) -> bool:
        return GroupMembership.objects.filter(group_id=group_id, user_id=user_id).exists()
