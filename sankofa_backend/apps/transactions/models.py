from __future__ import annotations

import uuid
from decimal import Decimal

from django.conf import settings
from django.db import models
from django.db.models import F, Q
from django.utils import timezone


class WalletManager(models.Manager):
    def ensure_platform(self, *, name: str | None = None) -> "Wallet":
        defaults = {"name": name or "Platform Float"}
        wallet, _created = self.get_or_create(is_platform=True, defaults=defaults)
        return wallet

    def ensure_for_user(self, user) -> "Wallet":
        wallet, _created = self.get_or_create(
            user=user,
            defaults={
                "name": getattr(user, "full_name", "").strip() or user.phone_number,
            },
        )
        return wallet


class Wallet(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        related_name="wallet",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
    )
    name = models.CharField(max_length=255, blank=True)
    is_platform = models.BooleanField(default=False)
    balance = models.DecimalField(max_digits=14, decimal_places=2, default=Decimal("0.00"))
    currency = models.CharField(max_length=8, default="GHS")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = WalletManager()

    class Meta:
        verbose_name = "Wallet"
        verbose_name_plural = "Wallets"
        constraints = [
            models.UniqueConstraint(
                fields=("is_platform",),
                condition=Q(is_platform=True),
                name="unique_platform_wallet",
            )
        ]

    def __str__(self) -> str:  # pragma: no cover - admin helper
        label = self.name or "Wallet"
        if self.is_platform:
            label = f"Platform Wallet ({label})"
        elif self.user:
            label = f"{label} ({self.user.phone_number})"
        return label


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
    balance_after = models.DecimalField(max_digits=14, decimal_places=2, null=True, blank=True)
    platform_balance_after = models.DecimalField(max_digits=14, decimal_places=2, null=True, blank=True)
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
