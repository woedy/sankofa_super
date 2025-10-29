from __future__ import annotations

import uuid
from datetime import timedelta

from django.conf import settings
from django.db import models
from django.utils import timezone


def generate_case_number() -> str:
    timestamp = timezone.now().strftime("%Y%m%d%H%M%S")
    suffix = uuid.uuid4().hex[:4].upper()
    return f"DIS-{timestamp}-{suffix}"


class SupportArticle(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    slug = models.SlugField(unique=True)
    category = models.CharField(max_length=128)
    title = models.CharField(max_length=255)
    summary = models.TextField()
    link = models.URLField()
    tags = models.JSONField(default=list, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["title"]

    def __str__(self) -> str:  # pragma: no cover - admin display helper
        return self.title


class Dispute(models.Model):
    class Status(models.TextChoices):
        OPEN = "Open", "Open"
        IN_REVIEW = "In Review", "In Review"
        ESCALATED = "Escalated", "Escalated"
        RESOLVED = "Resolved", "Resolved"

    class Severity(models.TextChoices):
        CRITICAL = "Critical", "Critical"
        HIGH = "High", "High"
        MEDIUM = "Medium", "Medium"
        LOW = "Low", "Low"

    class Priority(models.TextChoices):
        HIGH = "High", "High"
        MEDIUM = "Medium", "Medium"
        LOW = "Low", "Low"

    class Channel(models.TextChoices):
        MOBILE_APP = "Mobile App", "Mobile App"
        USSD = "USSD", "USSD"
        PHONE = "Phone", "Phone"
        EMAIL = "Email", "Email"
        WHATSAPP = "WhatsApp", "WhatsApp"
        SYSTEM = "System", "System"

    class SlaStatus(models.TextChoices):
        ON_TRACK = "On Track", "On Track"
        AT_RISK = "At Risk", "At Risk"
        BREACHED = "Breached", "Breached"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    case_number = models.CharField(max_length=40, unique=True, default=generate_case_number, editable=False)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    status = models.CharField(max_length=32, choices=Status.choices, default=Status.OPEN)
    severity = models.CharField(max_length=32, choices=Severity.choices, default=Severity.MEDIUM)
    priority = models.CharField(max_length=32, choices=Priority.choices, default=Priority.MEDIUM)
    category = models.CharField(max_length=128)
    channel = models.CharField(max_length=32, choices=Channel.choices, default=Channel.MOBILE_APP)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name="disputes", on_delete=models.CASCADE)
    group = models.ForeignKey("groups.Group", related_name="disputes", on_delete=models.SET_NULL, null=True, blank=True)
    assigned_to = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="assigned_disputes",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    opened_at = models.DateTimeField(auto_now_add=True)
    last_updated = models.DateTimeField(auto_now=True)
    sla_due = models.DateTimeField(null=True, blank=True)
    sla_status = models.CharField(max_length=32, choices=SlaStatus.choices, default=SlaStatus.ON_TRACK)
    resolution_notes = models.TextField(blank=True)
    related_article = models.ForeignKey(
        SupportArticle,
        related_name="disputes",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ["-opened_at"]

    def __str__(self) -> str:  # pragma: no cover - admin helper
        return f"{self.case_number}: {self.title}"

    @property
    def member_name(self) -> str:
        return self.user.full_name or self.user.phone_number

    def compute_sla_status(self) -> str:
        if not self.sla_due:
            return self.SlaStatus.ON_TRACK
        now = timezone.now()
        if now > self.sla_due:
            return self.SlaStatus.BREACHED
        if self.sla_due - now <= timedelta(hours=6):
            return self.SlaStatus.AT_RISK
        return self.SlaStatus.ON_TRACK

    def refresh_sla_status(self) -> None:
        computed = self.compute_sla_status()
        if computed != self.sla_status:
            self.sla_status = computed
            self.save(update_fields=["sla_status", "last_updated"])


class DisputeMessage(models.Model):
    class Role(models.TextChoices):
        MEMBER = "Member", "Member"
        SUPPORT = "Support", "Support"
        AUTOMATION = "Automation", "Automation"
        SYSTEM = "System", "System"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    dispute = models.ForeignKey(Dispute, related_name="messages", on_delete=models.CASCADE)
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="dispute_messages",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    author_name = models.CharField(max_length=255, blank=True)
    role = models.CharField(max_length=32, choices=Role.choices, default=Role.MEMBER)
    channel = models.CharField(max_length=64, blank=True)
    message = models.TextField()
    is_internal = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self) -> str:  # pragma: no cover - admin helper
        return f"{self.author_name or 'Unknown'} - {self.dispute.case_number}"

    def save(self, *args, **kwargs):
        creating = self._state.adding
        if not self.author_name and self.author:
            self.author_name = self.author.full_name or self.author.phone_number
        super().save(*args, **kwargs)
        if creating:
            Dispute.objects.filter(pk=self.dispute_id).update(last_updated=timezone.now())


class DisputeAttachment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    dispute = models.ForeignKey(Dispute, related_name="attachments", on_delete=models.CASCADE)
    uploaded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="dispute_attachments",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    file = models.FileField(upload_to="disputes/%Y/%m/")
    file_name = models.CharField(max_length=255)
    content_type = models.CharField(max_length=128)
    size = models.PositiveIntegerField(default=0)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-uploaded_at"]

    def __str__(self) -> str:  # pragma: no cover - admin helper
        return self.file_name

    def save(self, *args, **kwargs):
        if self.file and not self.file_name:
            self.file_name = self.file.name
        if self.file and not self.size:
            self.size = self.file.size
        super().save(*args, **kwargs)
