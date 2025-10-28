from __future__ import annotations

from django.contrib import admin

from .models import SavingsContribution, SavingsGoal, SavingsRedemption


@admin.register(SavingsGoal)
class SavingsGoalAdmin(admin.ModelAdmin):
    list_display = (
        "title",
        "user",
        "target_amount",
        "current_amount",
        "deadline",
        "category",
        "created_at",
    )
    list_filter = ("category", "deadline", "created_at")
    search_fields = ("title", "user__phone_number")
    autocomplete_fields = ("user",)
    ordering = ("deadline", "title")


@admin.register(SavingsContribution)
class SavingsContributionAdmin(admin.ModelAdmin):
    list_display = (
        "goal",
        "user",
        "amount",
        "channel",
        "recorded_at",
    )
    list_filter = ("channel", "recorded_at")
    search_fields = ("goal__title", "user__phone_number")
    autocomplete_fields = ("goal", "user")
    ordering = ("-recorded_at",)


@admin.register(SavingsRedemption)
class SavingsRedemptionAdmin(admin.ModelAdmin):
    list_display = (
        "goal",
        "user",
        "amount",
        "channel",
        "recorded_at",
    )
    list_filter = ("channel", "recorded_at")
    search_fields = ("goal__title", "user__phone_number")
    autocomplete_fields = ("goal", "user")
    ordering = ("-recorded_at",)
