"""Shared utility views."""
from __future__ import annotations

from django.http import JsonResponse
from django.views.decorators.http import require_GET


@require_GET
def health_check(_request):
    """Return a simple health payload for uptime checks."""
    return JsonResponse({"status": "ok"})
