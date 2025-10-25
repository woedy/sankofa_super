from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal

from django.db.models import Count, Max, QuerySet, Sum
from django.db.models.functions import Coalesce

from .models import Transaction


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
