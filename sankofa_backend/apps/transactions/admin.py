from __future__ import annotations

from django.contrib import admin

from .models import Transaction


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "transaction_type",
        "status",
        "amount",
        "occurred_at",
        "channel",
    )
    list_filter = ("transaction_type", "status", "occurred_at")
    search_fields = ("user__phone_number", "description", "reference")
    autocomplete_fields = ("user", "group", "savings_goal")
    ordering = ("-occurred_at",)
