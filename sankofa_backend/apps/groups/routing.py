"""Websocket URL routes for group activity."""
from __future__ import annotations

from django.urls import path

from . import consumers


websocket_urlpatterns = [
    path("ws/groups/<uuid:group_id>/", consumers.GroupActivityConsumer.as_asgi()),
]
