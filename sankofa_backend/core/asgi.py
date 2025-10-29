"""ASGI config for core project."""
from __future__ import annotations

import os

from channels.routing import ProtocolTypeRouter, URLRouter
from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings.production")

django_asgi_app = get_asgi_application()

from sankofa_backend.apps.accounts.middleware import JWTAuthMiddlewareStack  # noqa: E402
from sankofa_backend.apps.groups.routing import websocket_urlpatterns  # noqa: E402

application = ProtocolTypeRouter(
    {
        "http": django_asgi_app,
        "websocket": JWTAuthMiddlewareStack(URLRouter(websocket_urlpatterns)),
    }
)
