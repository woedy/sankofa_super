from __future__ import annotations

import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone


class SavingsGoalQuerySet(models.QuerySet):
    def for_user(self, user):
        if user.is_anonymous:
            return self.none()
        return self.filter(user=user)


class SavingsGoal(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name="savings_goals", on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    target_amount = models.DecimalField(max_digits=12, decimal_places=2)
    current_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    deadline = models.DateTimeField()
    category = models.CharField(max_length=128)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = SavingsGoalQuerySet.as_manager()

    class Meta:
        ordering = ["deadline", "title"]

    def __str__(self) -> str:
        return f"{self.title} ({self.user})"

    @property
    def progress(self) -> float:
        if self.target_amount == 0:
            return 0.0
        return float(self.current_amount) / float(self.target_amount)


class SavingsContribution(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    goal = models.ForeignKey(SavingsGoal, related_name="contributions", on_delete=models.CASCADE)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name="savings_contributions", on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    channel = models.CharField(max_length=64, default="Mobile Money")
    note = models.CharField(max_length=255, blank=True)
    recorded_at = models.DateTimeField(default=timezone.now)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-recorded_at"]

    def __str__(self) -> str:  # pragma: no cover - debug helper
        return f"{self.amount} to {self.goal.title}"


class SavingsRedemption(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    goal = models.ForeignKey(SavingsGoal, related_name="redemptions", on_delete=models.CASCADE)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name="savings_redemptions", on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    channel = models.CharField(max_length=64, default="Mobile Money")
    note = models.CharField(max_length=255, blank=True)
    recorded_at = models.DateTimeField(default=timezone.now)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-recorded_at"]

    def __str__(self) -> str:  # pragma: no cover - debug helper
        return f"{self.amount} withdrawal from {self.goal.title}"
