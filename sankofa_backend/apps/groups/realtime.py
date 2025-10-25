"""Helpers for broadcasting group activity over Channels."""
from __future__ import annotations

import logging
import uuid
from typing import Any

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer


logger = logging.getLogger(__name__)

GROUP_CHANNEL_PREFIX = "group_activity"


def group_channel_name(group_id: uuid.UUID | str) -> str:
    """Return the channel-layer group name for a Susu group."""

    return f"{GROUP_CHANNEL_PREFIX}_{group_id}"


def broadcast_group_event(*, group_id: uuid.UUID | str, event: str, payload: dict[str, Any]) -> None:
    """Broadcast a JSON event to all websocket subscribers for the group."""

    channel_layer = get_channel_layer()
    if channel_layer is None:  # pragma: no cover - defensive guard for misconfigured layers
        return

    try:
        async_to_sync(channel_layer.group_send)(
            group_channel_name(group_id),
            {
                "type": "group.activity",
                "event": event,
                "payload": payload,
            },
        )
    except Exception:  # pragma: no cover - best-effort broadcast shouldn't break request flow
        logger.warning("Failed to broadcast group event", exc_info=True)
