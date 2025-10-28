from __future__ import annotations

import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone


class GroupQuerySet(models.QuerySet):
    def for_user(self, user):
        if user.is_anonymous:
            return self.filter(is_public=True)
        return (
            self.filter(
                models.Q(is_public=True)
                | models.Q(memberships__user=user)
                | models.Q(owner=user)
            )
            .distinct()
        )


class Group(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    frequency = models.CharField(max_length=255, blank=True)
    location = models.CharField(max_length=255, blank=True)
    requires_approval = models.BooleanField(default=False)
    is_public = models.BooleanField(default=False)
    target_member_count = models.PositiveIntegerField(default=0)
    contribution_amount = models.DecimalField(max_digits=12, decimal_places=2)
    cycle_number = models.PositiveIntegerField(default=1)
    total_cycles = models.PositiveIntegerField(default=1)
    next_payout_date = models.DateTimeField()
    payout_order = models.CharField(max_length=255, blank=True)
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="owned_groups",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = GroupQuerySet.as_manager()

    class Meta:
        ordering = ["name"]

    def __str__(self) -> str:
        return self.name

    @property
    def seats_remaining(self) -> int:
        return max(self.target_member_count - self.memberships.count(), 0)


class GroupMembership(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    group = models.ForeignKey(Group, related_name="memberships", on_delete=models.CASCADE)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name="group_memberships", on_delete=models.CASCADE)
    display_name = models.CharField(max_length=255)
    joined_at = models.DateTimeField(default=timezone.now)

    class Meta:
        unique_together = ("group", "user")
        ordering = ["joined_at"]

    def __str__(self) -> str:  # pragma: no cover - debug helper
        return f"{self.display_name} in {self.group.name}"


class GroupInvite(models.Model):
    STATUS_PENDING = "pending"
    STATUS_ACCEPTED = "accepted"
    STATUS_DECLINED = "declined"
    STATUS_CHOICES = (
        (STATUS_PENDING, "Pending"),
        (STATUS_ACCEPTED, "Accepted"),
        (STATUS_DECLINED, "Declined"),
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    group = models.ForeignKey(Group, related_name="invites", on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    phone_number = models.CharField(max_length=32)
    status = models.CharField(max_length=16, choices=STATUS_CHOICES, default=STATUS_PENDING)
    kyc_completed = models.BooleanField(default=False)
    sent_at = models.DateTimeField(default=timezone.now)
    responded_at = models.DateTimeField(blank=True, null=True)
    last_reminded_at = models.DateTimeField(blank=True, null=True)
    reminder_count = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["-sent_at"]

    def mark_status(self, *, status: str, kyc_completed: bool | None = None) -> None:
        if status not in {choice[0] for choice in self.STATUS_CHOICES}:
            raise ValueError("Invalid status")
        self.status = status
        if status != self.STATUS_PENDING:
            self.responded_at = timezone.now()
        if kyc_completed is not None:
            self.kyc_completed = kyc_completed
        self.save(update_fields=["status", "responded_at", "kyc_completed"])


class GroupInviteReminder(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    invite = models.ForeignKey(GroupInvite, related_name="reminders", on_delete=models.CASCADE)
    reminded_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ["-reminded_at"]

    def __str__(self) -> str:  # pragma: no cover
        return f"Reminder for {self.invite.phone_number} at {self.reminded_at}"
