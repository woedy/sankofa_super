from __future__ import annotations

from datetime import datetime, time

from django.db.models import Q
from django.utils import timezone
from django.utils.dateparse import parse_date, parse_datetime
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response

from .models import Transaction
from .serializers import (
    DepositRequestSerializer,
    TransactionSerializer,
    TransactionSummarySerializer,
    WalletOperationResponseSerializer,
    WalletSerializer,
    WithdrawRequestSerializer,
)
from .services import apply_deposit, apply_withdrawal, build_transaction_summary


class TransactionPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100


class TransactionViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    serializer_class = TransactionSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = TransactionPagination

    def get_queryset(self):
        return (
            Transaction.objects.select_related("group", "savings_goal")
            .for_user(self.request.user)
            .order_by("-occurred_at", "-created_at")
        )

    def filter_queryset(self, queryset):  # type: ignore[override]
        request = self.request
        type_param = request.query_params.get("types") or request.query_params.get("type")
        if type_param:
            type_values = {value.strip().lower() for value in type_param.split(",") if value.strip()}
            queryset = queryset.filter(transaction_type__in=type_values)

        status_param = request.query_params.get("statuses") or request.query_params.get("status")
        if status_param:
            status_values = {value.strip().lower() for value in status_param.split(",") if value.strip()}
            queryset = queryset.filter(status__in=status_values)

        start_param = request.query_params.get("start")
        if start_param:
            start = _parse_query_datetime(start_param, is_end=False)
            if start is not None:
                queryset = queryset.filter(occurred_at__gte=start)

        end_param = request.query_params.get("end")
        if end_param:
            end = _parse_query_datetime(end_param, is_end=True)
            if end is not None:
                queryset = queryset.filter(occurred_at__lte=end)

        search_param = request.query_params.get("search")
        if search_param:
            queryset = queryset.filter(
                Q(description__icontains=search_param)
                | Q(reference__icontains=search_param)
                | Q(counterparty__icontains=search_param)
            )

        return queryset

    @action(methods=["get"], detail=False)
    def summary(self, request):
        queryset = self.filter_queryset(self.get_queryset())
        summary = build_transaction_summary(queryset)
        serializer = TransactionSummarySerializer(
            data={
                "totalCount": summary.total_count,
                "totalInflow": summary.total_inflow,
                "totalOutflow": summary.total_outflow,
                "netCashflow": summary.net_cashflow,
                "pendingCount": summary.pending_count,
                "lastTransactionAt": summary.last_transaction_at,
                "totalsByType": summary.totals_by_type,
                "totalsByStatus": summary.totals_by_status,
            }
        )
        serializer.is_valid(raise_exception=True)
        return Response(serializer.validated_data)

    @action(methods=["post"], detail=False)
    def deposit(self, request):
        serializer = DepositRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            transaction, wallet, platform_wallet = apply_deposit(
                user=request.user,
                **serializer.validated_data,
            )
        except DjangoValidationError as exc:
            raise ValidationError(exc.message_dict) from exc

        payload = WalletOperationResponseSerializer(
            instance={
                "transaction": transaction,
                "wallet": wallet,
                "platformWallet": platform_wallet,
            },
            context={"request": request},
        )
        return Response(payload.data, status=status.HTTP_201_CREATED)

    @action(methods=["post"], detail=False)
    def withdraw(self, request):
        serializer = WithdrawRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            transaction, wallet, platform_wallet = apply_withdrawal(
                user=request.user,
                **serializer.validated_data,
            )
        except DjangoValidationError as exc:
            raise ValidationError(exc.message_dict) from exc

        payload = WalletOperationResponseSerializer(
            instance={
                "transaction": transaction,
                "wallet": wallet,
                "platformWallet": platform_wallet,
            },
            context={"request": request},
        )
        return Response(payload.data, status=status.HTTP_201_CREATED)


def _parse_query_datetime(value: str, *, is_end: bool) -> datetime | None:
    dt = parse_datetime(value)
    if dt is None:
        parsed_date = parse_date(value)
        if parsed_date is None:
            return None
        boundary_time = time.max if is_end else time.min
        dt = datetime.combine(parsed_date, boundary_time)
    if timezone.is_naive(dt):
        dt = timezone.make_aware(dt, timezone.get_current_timezone())
    if is_end and dt.time() == time.max:
        # ensure inclusive filtering by nudging to end-of-day microsecond
        dt = dt.replace(microsecond=999999)
    return dt
