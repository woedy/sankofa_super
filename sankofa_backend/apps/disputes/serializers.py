from __future__ import annotations

from typing import Any

from django.utils import timezone
from rest_framework import serializers

from ..groups.models import Group
from .models import Dispute, DisputeAttachment, DisputeMessage, SupportArticle


class SupportArticleSerializer(serializers.ModelSerializer):
    class Meta:
        model = SupportArticle
        fields = ("id", "slug", "category", "title", "summary", "link", "tags")
        read_only_fields = fields


class DisputeAttachmentSerializer(serializers.ModelSerializer):
    download_url = serializers.SerializerMethodField()

    class Meta:
        model = DisputeAttachment
        fields = ("id", "file_name", "content_type", "size", "uploaded_at", "download_url")
        read_only_fields = fields

    def get_download_url(self, obj: DisputeAttachment) -> str:
        request = self.context.get("request")
        if request is None:
            return obj.file.url
        return request.build_absolute_uri(obj.file.url)


class DisputeMessageSerializer(serializers.ModelSerializer):
    timestamp = serializers.DateTimeField(source="created_at", read_only=True)

    class Meta:
        model = DisputeMessage
        fields = (
            "id",
            "author_name",
            "role",
            "channel",
            "message",
            "timestamp",
            "is_internal",
        )
        read_only_fields = ("id", "timestamp")


class DisputeSerializer(serializers.ModelSerializer):
    member_name = serializers.CharField(read_only=True)
    member_phone = serializers.CharField(source="user.phone_number", read_only=True)
    member_id = serializers.UUIDField(source="user_id", read_only=True)
    group_name = serializers.SerializerMethodField()
    group_id = serializers.UUIDField(read_only=True)
    assigned_to_name = serializers.SerializerMethodField()
    assigned_to_id = serializers.UUIDField(read_only=True)
    messages = DisputeMessageSerializer(many=True, read_only=True)
    attachments = DisputeAttachmentSerializer(many=True, read_only=True)
    related_article = SupportArticleSerializer(read_only=True)
    related_article_id = serializers.UUIDField(read_only=True)
    case_number = serializers.CharField(read_only=True)
    opened_at = serializers.DateTimeField(read_only=True)
    last_updated = serializers.DateTimeField(read_only=True)
    sla_due = serializers.DateTimeField(required=False, allow_null=True)

    class Meta:
        model = Dispute
        fields = (
            "id",
            "case_number",
            "title",
            "description",
            "status",
            "severity",
            "priority",
            "category",
            "channel",
            "member_name",
            "member_phone",
            "member_id",
            "group",
            "group_name",
            "group_id",
            "assigned_to",
            "assigned_to_name",
            "assigned_to_id",
            "opened_at",
            "last_updated",
            "sla_due",
            "sla_status",
            "resolution_notes",
            "related_article",
            "related_article_id",
            "messages",
            "attachments",
        )
        read_only_fields = (
            "id",
            "case_number",
            "member_name",
            "member_phone",
            "member_id",
            "group_name",
            "group_id",
            "assigned_to_name",
            "assigned_to_id",
            "opened_at",
            "last_updated",
            "sla_status",
            "messages",
            "attachments",
            "related_article",
            "related_article_id",
        )

    def get_group_name(self, obj: Dispute) -> str | None:
        return obj.group.name if obj.group else None

    def get_assigned_to_name(self, obj: Dispute) -> str | None:
        if obj.assigned_to:
            return obj.assigned_to.full_name or obj.assigned_to.phone_number
        return None

    def to_representation(self, instance: Dispute) -> dict[str, Any]:
        instance.refresh_sla_status()
        return super().to_representation(instance)


class DisputeCreateSerializer(serializers.ModelSerializer):
    initial_message = serializers.CharField(write_only=True)
    channel = serializers.ChoiceField(choices=Dispute.Channel.choices)
    group = serializers.PrimaryKeyRelatedField(queryset=Group.objects.all(), allow_null=True, required=False)

    class Meta:
        model = Dispute
        fields = (
            "title",
            "description",
            "category",
            "severity",
            "priority",
            "channel",
            "group",
            "initial_message",
        )

    def create(self, validated_data: dict[str, Any]) -> Dispute:
        message_text = validated_data.pop("initial_message")
        user = self.context["request"].user
        dispute = Dispute.objects.create(user=user, **validated_data)
        DisputeMessage.objects.create(
            dispute=dispute,
            author=user,
            role=DisputeMessage.Role.MEMBER,
            channel=validated_data.get("channel", "Mobile App"),
            message=message_text,
        )
        return dispute


class DisputeMessageCreateSerializer(serializers.Serializer):
    message = serializers.CharField()
    channel = serializers.CharField(required=False, allow_blank=True)
    role = serializers.ChoiceField(choices=DisputeMessage.Role.choices, required=False)
    is_internal = serializers.BooleanField(default=False)

    def create(self, validated_data: dict[str, Any]) -> DisputeMessage:
        dispute: Dispute = self.context["dispute"]
        author = self.context.get("author")
        role = validated_data.get("role")
        if not role:
            role = DisputeMessage.Role.SUPPORT if author and getattr(author, "is_staff", False) else DisputeMessage.Role.MEMBER
        message = DisputeMessage.objects.create(
            dispute=dispute,
            author=author,
            role=role,
            channel=validated_data.get("channel", ""),
            message=validated_data["message"],
            is_internal=validated_data.get("is_internal", False),
        )
        dispute.refresh_sla_status()
        return message


class DisputeUpdateSerializer(serializers.ModelSerializer):
    sla_due = serializers.DateTimeField(required=False, allow_null=True)

    class Meta:
        model = Dispute
        fields = (
            "status",
            "severity",
            "priority",
            "assigned_to",
            "sla_due",
            "sla_status",
            "resolution_notes",
            "related_article",
        )

    def update(self, instance: Dispute, validated_data: dict[str, Any]) -> Dispute:
        instance = super().update(instance, validated_data)
        instance.refresh_sla_status()
        if "resolution_notes" in validated_data and instance.status == Dispute.Status.RESOLVED:
            instance.metadata.setdefault("resolution_logged_at", timezone.now().isoformat())
            instance.save(update_fields=["metadata"])
        return instance
