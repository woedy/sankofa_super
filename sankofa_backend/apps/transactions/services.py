from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal

from django.core.exceptions import ValidationError
from django.db import transaction as db_transaction
from django.db.models import Count, Max, QuerySet, Sum
from django.db.models.functions import Coalesce
from django.utils import timezone

from .models import Transaction, Wallet


@dataclass(slots=True)
class TransactionSummary:
    total_count: int
    total_inflow: Decimal
    total_outflow: Decimal
    net_cashflow: Decimal
    pending_count: int
    last_transaction_at: datetime | None
    totals_by_type: list[dict[str, object]]
    totals_by_status: list[dict[str, object]]


def build_transaction_summary(queryset: QuerySet[Transaction]) -> TransactionSummary:
    zero = Decimal("0.00")
    inflow_total = queryset.filter(transaction_type__in=Transaction.INFLOW_TYPES).aggregate(
        total=Coalesce(Sum("amount"), zero)
    )["total"]
    outflow_total = queryset.filter(transaction_type__in=Transaction.OUTFLOW_TYPES).aggregate(
        total=Coalesce(Sum("amount"), zero)
    )["total"]

    totals_by_type = _aggregate_by(queryset, "transaction_type")
    totals_by_status = _aggregate_status(queryset)

    last_transaction_at = queryset.aggregate(last=Max("occurred_at"))["last"]
    pending_count = queryset.filter(status=Transaction.STATUS_PENDING).count()

    return TransactionSummary(
        total_count=queryset.count(),
        total_inflow=inflow_total,
        total_outflow=outflow_total,
        net_cashflow=inflow_total - outflow_total,
        pending_count=pending_count,
        last_transaction_at=last_transaction_at,
        totals_by_type=totals_by_type,
        totals_by_status=totals_by_status,
    )


def _aggregate_by(queryset: QuerySet[Transaction], field: str) -> list[dict[str, object]]:
    zero = Decimal("0.00")
    results = queryset.values(field).annotate(
        count=Count("id"),
        amount=Coalesce(Sum("amount"), zero),
    )
    totals_map: dict[str, dict[str, object]] = {}
    for row in results:
        key = row[field]
        totals_map[key] = {
            "type": key,
            "count": int(row["count"]),
            "amount": row["amount"],
        }

    ordered: list[dict[str, object]] = []
    for choice, _label in Transaction.TYPE_CHOICES:
        entry = totals_map.get(choice) or {"type": choice, "count": 0, "amount": zero}
        ordered.append(entry)
    return ordered


def _aggregate_status(queryset: QuerySet[Transaction]) -> list[dict[str, object]]:
    counts = queryset.values("status").annotate(count=Count("id"))
    totals_map = {row["status"]: int(row["count"]) for row in counts}
    ordered: list[dict[str, object]] = []
    for value, _label in Transaction.STATUS_CHOICES:
        ordered.append({"status": value, "count": totals_map.get(value, 0)})
    return ordered


def _normalise_amount(value) -> Decimal:
    if isinstance(value, Decimal):
        amount = value
    else:
        amount = Decimal(str(value))
    return amount.quantize(Decimal("0.01"))


@db_transaction.atomic
def apply_deposit(
    *,
    user,
    amount,
    channel: str = "",
    reference: str = "",
    fee: Decimal | None = None,
    description: str = "",
    counterparty: str = "",
) -> tuple[Transaction, Wallet, Wallet]:
    amount_dec = _normalise_amount(amount)
    fee_dec = _normalise_amount(fee) if fee is not None else None

    user_wallet = Wallet.objects.ensure_for_user(user)
    platform_wallet = Wallet.objects.ensure_platform()

    user_wallet = Wallet.objects.select_for_update().get(pk=user_wallet.pk)
    platform_wallet = Wallet.objects.select_for_update().get(pk=platform_wallet.pk)

    user_wallet.balance = user_wallet.balance + amount_dec
    user_wallet.save(update_fields=["balance", "updated_at"])

    platform_wallet.balance = platform_wallet.balance + amount_dec
    platform_wallet.save(update_fields=["balance", "updated_at"])

    transaction = Transaction.objects.create(
        user=user,
        transaction_type=Transaction.TYPE_DEPOSIT,
        status=Transaction.STATUS_SUCCESS,
        amount=amount_dec,
        description=description or "Wallet deposit",
        occurred_at=timezone.now(),
        channel=channel,
        fee=fee_dec,
        reference=reference,
        counterparty=counterparty or user.phone_number,
        balance_after=user_wallet.balance,
        platform_balance_after=platform_wallet.balance,
    )

    return transaction, user_wallet, platform_wallet


@db_transaction.atomic
def apply_withdrawal(
    *,
    user,
    amount,
    status: str | None = None,
    channel: str = "",
    reference: str = "",
    fee: Decimal | None = None,
    description: str = "",
    counterparty: str = "",
    destination: str = "",
    note: str = "",
) -> tuple[Transaction, Wallet, Wallet]:
    amount_dec = _normalise_amount(amount)
    fee_dec = _normalise_amount(fee) if fee is not None else None

    requested_status = status or Transaction.STATUS_PENDING
    if requested_status not in {choice[0] for choice in Transaction.STATUS_CHOICES}:
        raise ValidationError({"status": "Invalid status supplied."})

    user_wallet = Wallet.objects.ensure_for_user(user)
    platform_wallet = Wallet.objects.ensure_platform()

    user_wallet = Wallet.objects.select_for_update().get(pk=user_wallet.pk)
    platform_wallet = Wallet.objects.select_for_update().get(pk=platform_wallet.pk)

    if requested_status != Transaction.STATUS_FAILED and user_wallet.balance < amount_dec:
        raise ValidationError({"amount": "Insufficient wallet balance for withdrawal."})

    if requested_status != Transaction.STATUS_FAILED:
        user_wallet.balance = user_wallet.balance - amount_dec
        platform_wallet.balance = platform_wallet.balance - amount_dec
        user_wallet.save(update_fields=["balance", "updated_at"])
        platform_wallet.save(update_fields=["balance", "updated_at"])
    else:
        user_wallet.save(update_fields=["updated_at"])
        platform_wallet.save(update_fields=["updated_at"])

    final_description = description or "Wallet withdrawal"
    if note:
        separator = " — " if final_description else ""
        final_description = f"{final_description}{separator}{note}" if final_description else note

    transaction = Transaction.objects.create(
        user=user,
        transaction_type=Transaction.TYPE_WITHDRAWAL,
        status=requested_status,
        amount=amount_dec,
        description=final_description,
        occurred_at=timezone.now(),
        channel=channel,
        fee=fee_dec,
        reference=reference,
        counterparty=destination or counterparty or user.phone_number,
        balance_after=user_wallet.balance,
        platform_balance_after=platform_wallet.balance,
    )

    return transaction, user_wallet, platform_wallet


@db_transaction.atomic
def apply_savings_contribution(
    *,
    user,
    goal,
    amount,
    channel: str = "",
    reference: str = "",
    description: str = "",
    counterparty: str = "",
    note: str = "",
) -> tuple[Transaction, Wallet, Wallet]:
    """Debit the member wallet for a savings contribution while crediting the platform float."""

    amount_dec = _normalise_amount(amount)

    user_wallet = Wallet.objects.ensure_for_user(user)
    platform_wallet = Wallet.objects.ensure_platform()

    user_wallet = Wallet.objects.select_for_update().get(pk=user_wallet.pk)
    platform_wallet = Wallet.objects.select_for_update().get(pk=platform_wallet.pk)

    if user_wallet.balance < amount_dec:
        raise ValidationError({"amount": "Insufficient wallet balance for savings contribution."})

    user_wallet.balance = user_wallet.balance - amount_dec
    platform_wallet.balance = platform_wallet.balance + amount_dec

    user_wallet.save(update_fields=["balance", "updated_at"])
    platform_wallet.save(update_fields=["balance", "updated_at"])

    base_description = description or f"Savings contribution to {goal.title}"
    if note:
        separator = " — " if base_description else ""
        base_description = f"{base_description}{separator}{note}" if base_description else note

    transaction = Transaction.objects.create(
        user=user,
        transaction_type=Transaction.TYPE_SAVINGS,
        status=Transaction.STATUS_SUCCESS,
        amount=amount_dec,
        description=base_description or "Savings contribution",
        occurred_at=timezone.now(),
        channel=channel,
        reference=reference,
        counterparty=counterparty or user.phone_number,
        balance_after=user_wallet.balance,
        platform_balance_after=platform_wallet.balance,
        savings_goal=goal,
    )

    return transaction, user_wallet, platform_wallet


@db_transaction.atomic
def apply_savings_payout(
    *,
    user,
    goal,
    amount,
    channel: str = "",
    reference: str = "",
    description: str = "",
    counterparty: str = "",
    note: str = "",
) -> tuple[Transaction, Wallet, Wallet]:
    """Release savings back to the member wallet while debiting the platform float."""

    amount_dec = _normalise_amount(amount)

    user_wallet = Wallet.objects.ensure_for_user(user)
    platform_wallet = Wallet.objects.ensure_platform()

    user_wallet = Wallet.objects.select_for_update().get(pk=user_wallet.pk)
    platform_wallet = Wallet.objects.select_for_update().get(pk=platform_wallet.pk)

    if platform_wallet.balance < amount_dec:
        raise ValidationError({"amount": "Insufficient platform balance to release savings."})

    user_wallet.balance = user_wallet.balance + amount_dec
    platform_wallet.balance = platform_wallet.balance - amount_dec

    user_wallet.save(update_fields=["balance", "updated_at"])
    platform_wallet.save(update_fields=["balance", "updated_at"])

    base_description = description or f"Savings payout from {goal.title}"
    if note:
        separator = " — " if base_description else ""
        base_description = f"{base_description}{separator}{note}" if base_description else note

    transaction = Transaction.objects.create(
        user=user,
        transaction_type=Transaction.TYPE_PAYOUT,
        status=Transaction.STATUS_SUCCESS,
        amount=amount_dec,
        description=base_description or "Savings payout",
        occurred_at=timezone.now(),
        channel=channel,
        reference=reference,
        counterparty=counterparty or user.phone_number,
        balance_after=user_wallet.balance,
        platform_balance_after=platform_wallet.balance,
        savings_goal=goal,
    )

    return transaction, user_wallet, platform_wallet
