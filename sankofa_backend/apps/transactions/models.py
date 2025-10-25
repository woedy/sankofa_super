from __future__ import annotations

import uuid
from django.conf import settings
from django.db import models
from django.utils import timezone


class TransactionQuerySet(models.QuerySet):
    def for_user(self, user):
        if user.is_anonymous:
            return self.none()
        return self.filter(user=user)

    def inflow(self):
        return self.filter(transaction_type__in=Transaction.INFLOW_TYPES)

    def outflow(self):
        return self.filter(transaction_type__in=Transaction.OUTFLOW_TYPES)


class Transaction(models.Model):
    TYPE_DEPOSIT = "deposit"
    TYPE_WITHDRAWAL = "withdrawal"
    TYPE_CONTRIBUTION = "contribution"
    TYPE_PAYOUT = "payout"
    TYPE_SAVINGS = "savings"

    STATUS_SUCCESS = "success"
    STATUS_PENDING = "pending"
    STATUS_FAILED = "failed"

    TYPE_CHOICES = (
        (TYPE_DEPOSIT, "Deposit"),
        (TYPE_WITHDRAWAL, "Withdrawal"),
        (TYPE_CONTRIBUTION, "Contribution"),
        (TYPE_PAYOUT, "Payout"),
        (TYPE_SAVINGS, "Savings"),
    )

    STATUS_CHOICES = (
        (STATUS_SUCCESS, "Success"),
        (STATUS_PENDING, "Pending"),
        (STATUS_FAILED, "Failed"),
    )

    INFLOW_TYPES: tuple[str, ...] = (TYPE_DEPOSIT, TYPE_PAYOUT)
    OUTFLOW_TYPES: tuple[str, ...] = (TYPE_WITHDRAWAL, TYPE_CONTRIBUTION, TYPE_SAVINGS)

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="transactions",
        on_delete=models.CASCADE,
    )
    transaction_type = models.CharField(max_length=32, choices=TYPE_CHOICES)
    status = models.CharField(max_length=16, choices=STATUS_CHOICES)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    description = models.CharField(max_length=255)
    occurred_at = models.DateTimeField(default=timezone.now)
    channel = models.CharField(max_length=64, blank=True)
    fee = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    reference = models.CharField(max_length=64, blank=True)
    counterparty = models.CharField(max_length=128, blank=True)
    group = models.ForeignKey(
        "groups.Group",
        related_name="transactions",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    savings_goal = models.ForeignKey(
        "savings.SavingsGoal",
        related_name="transactions",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = TransactionQuerySet.as_manager()

    class Meta:
        ordering = ["-occurred_at", "-created_at"]
        indexes = [
            models.Index(fields=["user", "occurred_at"]),
            models.Index(fields=["user", "transaction_type"]),
            models.Index(fields=["user", "status"]),
        ]

    def __str__(self) -> str:  # pragma: no cover - debug helper
        return f"{self.transaction_type} {self.amount} for {self.user}"  # pragma: no cover

    @property
    def is_inflow(self) -> bool:
        return self.transaction_type in self.INFLOW_TYPES

    @property
    def is_outflow(self) -> bool:
        return self.transaction_type in self.OUTFLOW_TYPES
