from __future__ import annotations

from django.contrib import admin

from .models import Group, GroupInvite, GroupInviteReminder, GroupMembership


@admin.register(Group)
class GroupAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "owner",
        "is_public",
        "requires_approval",
        "target_member_count",
        "cycle_number",
        "total_cycles",
        "next_payout_date",
    )
    list_filter = ("is_public", "requires_approval")
    search_fields = ("name", "description", "location", "owner__phone_number", "owner__full_name")
    ordering = ("name",)
    autocomplete_fields = ("owner",)


@admin.register(GroupMembership)
class GroupMembershipAdmin(admin.ModelAdmin):
    list_display = ("group", "user", "display_name", "joined_at")
    list_filter = ("group", "joined_at")
    search_fields = ("display_name", "user__phone_number", "group__name")
    autocomplete_fields = ("group", "user")
    ordering = ("group", "joined_at")


@admin.register(GroupInvite)
class GroupInviteAdmin(admin.ModelAdmin):
    list_display = (
        "group",
        "name",
        "phone_number",
        "status",
        "kyc_completed",
        "sent_at",
        "responded_at",
    )
    list_filter = ("status", "kyc_completed", "sent_at")
    search_fields = ("name", "phone_number", "group__name")
    autocomplete_fields = ("group",)
    ordering = ("-sent_at",)


@admin.register(GroupInviteReminder)
class GroupInviteReminderAdmin(admin.ModelAdmin):
    list_display = ("invite", "reminded_at")
    list_filter = ("reminded_at",)
    autocomplete_fields = ("invite",)
    ordering = ("-reminded_at",)
