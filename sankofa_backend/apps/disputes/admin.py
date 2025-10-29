from django.contrib import admin

from .models import Dispute, DisputeAttachment, DisputeMessage, SupportArticle


@admin.register(Dispute)
class DisputeAdmin(admin.ModelAdmin):
    list_display = ("case_number", "title", "status", "severity", "user", "assigned_to", "opened_at", "sla_due")
    search_fields = ("case_number", "title", "user__full_name", "user__phone_number")
    list_filter = ("status", "severity", "priority", "channel")


@admin.register(DisputeMessage)
class DisputeMessageAdmin(admin.ModelAdmin):
    list_display = ("dispute", "author_name", "role", "channel", "created_at")
    search_fields = ("dispute__case_number", "author_name", "message")


@admin.register(DisputeAttachment)
class DisputeAttachmentAdmin(admin.ModelAdmin):
    list_display = ("dispute", "file_name", "content_type", "size", "uploaded_at")
    search_fields = ("dispute__case_number", "file_name")


@admin.register(SupportArticle)
class SupportArticleAdmin(admin.ModelAdmin):
    list_display = ("title", "category", "slug")
    search_fields = ("title", "category", "slug")
