from __future__ import annotations

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .models import PhoneOTP, User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    ordering = ("phone_number",)
    list_display = ("phone_number", "full_name", "email", "kyc_status", "is_active")
    search_fields = ("phone_number", "full_name", "email")
    fieldsets = (
        (None, {"fields": ("phone_number", "password")}),
        ("Personal info", {"fields": ("full_name", "email", "kyc_status")}),
        (
            "Permissions",
            {
                "fields": (
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                )
            },
        ),
        ("Important dates", {"fields": ("last_login", "date_joined")}),
    )
    readonly_fields = ("last_login", "date_joined")
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("phone_number", "full_name", "email", "password1", "password2"),
            },
        ),
    )
    filter_horizontal = ("groups", "user_permissions")


@admin.register(PhoneOTP)
class PhoneOTPAdmin(admin.ModelAdmin):
    list_display = ("phone_number", "purpose", "code", "created_at", "expires_at", "verified_at")
    list_filter = ("purpose", "created_at", "verified_at")
    search_fields = ("phone_number", "code")
