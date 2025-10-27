from __future__ import annotations

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin
from django.utils.html import format_html

from .models import PhoneOTP, User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    ordering = ("phone_number",)
    list_display = (
        "phone_number",
        "full_name",
        "email",
        "kyc_status",
        "wallet_balance_display",
        "kyc_submitted_at",
        "is_active",
    )
    search_fields = ("phone_number", "full_name", "email")
    list_filter = ("kyc_status", "is_staff", "is_active")
    fieldsets = (
        (None, {"fields": ("phone_number", "password")}),
        (
            "Personal info",
            {
                "fields": (
                    "full_name",
                    "email",
                    "kyc_status",
                    "kyc_submitted_at",
                    "wallet_balance_display",
                    "wallet_updated_at_display",
                    "ghana_card_front",
                    "ghana_card_back",
                    "ghana_card_front_preview",
                    "ghana_card_back_preview",
                )
            },
        ),
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
    readonly_fields = (
        "last_login",
        "date_joined",
        "ghana_card_front",
        "ghana_card_back",
        "kyc_submitted_at",
        "wallet_balance_display",
        "wallet_updated_at_display",
        "ghana_card_front_preview",
        "ghana_card_back_preview",
    )
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

    @admin.display(description="Wallet balance")
    def wallet_balance_display(self, obj: User):
        balance = obj.wallet_balance
        return f"GH₵ {balance:.2f}"

    @admin.display(description="Wallet updated")
    def wallet_updated_at_display(self, obj: User):
        timestamp = obj.wallet_updated_at
        return timestamp.strftime("%Y-%m-%d %H:%M") if timestamp else "-"

    @admin.display(description="Ghana Card (front)")
    def ghana_card_front_preview(self, obj: User):
        if not obj.ghana_card_front:
            return "—"
        return format_html(
            '<a href="{url}" target="_blank">View front</a>',
            url=obj.ghana_card_front.url,
        )

    @admin.display(description="Ghana Card (back)")
    def ghana_card_back_preview(self, obj: User):
        if not obj.ghana_card_back:
            return "—"
        return format_html(
            '<a href="{url}" target="_blank">View back</a>',
            url=obj.ghana_card_back.url,
        )


@admin.register(PhoneOTP)
class PhoneOTPAdmin(admin.ModelAdmin):
    list_display = ("phone_number", "purpose", "code", "created_at", "expires_at", "verified_at")
    list_filter = ("purpose", "created_at", "verified_at")
    search_fields = ("phone_number", "code")
