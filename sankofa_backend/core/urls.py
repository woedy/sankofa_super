"""core URL Configuration."""
from __future__ import annotations

from django.contrib import admin
from django.urls import include, path
from rest_framework_simplejwt.views import TokenRefreshView

from sankofa_backend.apps.common.views import health_check

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/health/", health_check, name="health-check"),
    path("api/auth/", include(("sankofa_backend.apps.accounts.urls", "accounts"), namespace="accounts")),
    path("api/auth/token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("api/groups/", include(("sankofa_backend.apps.groups.urls", "groups"), namespace="groups")),
    path("api/savings/", include(("sankofa_backend.apps.savings.urls", "savings"), namespace="savings")),
]
