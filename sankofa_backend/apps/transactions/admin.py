from __future__ import annotations

from django.contrib import admin

from .models import Transaction, Wallet


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "transaction_type",
        "status",
        "amount",
        "occurred_at",
        "channel",
        "reference",
        "balance_after",
    )
    list_filter = ("transaction_type", "status", "occurred_at")
    search_fields = ("user__phone_number", "description", "reference", "counterparty")
    autocomplete_fields = ("user", "group", "savings_goal")
    ordering = ("-occurred_at",)
    readonly_fields = ("balance_after", "platform_balance_after", "created_at", "updated_at")


@admin.register(Wallet)
class WalletAdmin(admin.ModelAdmin):
    list_display = ("__str__", "balance", "currency", "updated_at")
    search_fields = ("name", "user__phone_number")
    list_filter = ("is_platform",)
    readonly_fields = ("created_at", "updated_at")
    autocomplete_fields = ("user",)
