"""Custom authentication middleware for Channels consumers."""
from __future__ import annotations

from urllib.parse import parse_qs

from asgiref.sync import sync_to_async
from django.contrib.auth.models import AnonymousUser
from django.db import close_old_connections
from rest_framework_simplejwt.authentication import JWTAuthentication


class JWTAuthMiddleware:
    """Populate ``scope['user']`` from a JWT ``token`` query parameter."""

    def __init__(self, inner):
        self.inner = inner
        self._jwt_auth = JWTAuthentication()

    async def __call__(self, scope, receive, send):
        scope["user"] = await sync_to_async(_authenticate, thread_sensitive=True)(scope, self._jwt_auth)
        return await self.inner(scope, receive, send)


def _authenticate(scope, jwt_auth: JWTAuthentication):
    close_old_connections()
    query_string = scope.get("query_string", b"").decode()
    params = parse_qs(query_string)
    token = params.get("token", [None])[0]

    if not token:
        return AnonymousUser()

    try:
        validated = jwt_auth.get_validated_token(token)
        user = jwt_auth.get_user(validated)
    except Exception:  # pragma: no cover - invalid tokens fall back to anonymous
        return AnonymousUser()

    return user


def JWTAuthMiddlewareStack(inner):
    from channels.auth import AuthMiddlewareStack

    return JWTAuthMiddleware(AuthMiddlewareStack(inner))
