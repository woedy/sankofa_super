"""core URL Configuration."""
from __future__ import annotations

from django.contrib import admin
from django.urls import path

from sankofa_backend.apps.common.views import health_check

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/health/", health_check, name="health-check"),
]
