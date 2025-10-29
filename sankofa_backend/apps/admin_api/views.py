from __future__ import annotations

from collections import defaultdict
from datetime import timedelta
from decimal import Decimal
from typing import Any

from django.contrib.auth import get_user_model
from django.db.models import Count, Q, Sum, Value
from django.db.models.functions import Coalesce, TruncDate, TruncMonth
from django.utils import timezone
from rest_framework import mixins, status, viewsets
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response
from rest_framework.views import APIView

from ..groups.models import Group, GroupInvite
from ..savings.models import SavingsGoal
from ..transactions.models import Transaction, Wallet
from .models import AuditLog
from .permissions import IsStaffUser
from .serializers import (
    AdminTokenObtainSerializer,
    AdminUserDetailSerializer,
    AdminUserSummarySerializer,
    AuditLogSerializer,
    CashflowQueuesSerializer,
    DashboardMetricsSerializer,
    GroupSerializer,
    SavingsGoalSerializer,
    TransactionSerializer,
)

User = get_user_model()


class AdminPagination(PageNumberPagination):
    page_size = 25
    max_page_size = 100


class AdminAuthView(APIView):
    permission_classes: list[type[IsStaffUser]] = []
    authentication_classes: list[Any] = []

    def post(self, request, *args, **kwargs):
        serializer = AdminTokenObtainSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.validated_data)


class UserViewSet(viewsets.GenericViewSet, mixins.ListModelMixin, mixins.RetrieveModelMixin, mixins.UpdateModelMixin):
    permission_classes = [IsStaffUser]
    pagination_class = AdminPagination
    serializer_class = AdminUserSummarySerializer

    def get_queryset(self):
        queryset = (
            User.objects.all()
            .select_related("wallet")
            .prefetch_related("group_memberships", "savings_goals", "transactions")
            .annotate(
                groups_count=Count("group_memberships", distinct=True),
                savings_goal_count=Count("savings_goals", distinct=True),
                pending_transactions=Count(
                    "transactions",
                    filter=Q(transactions__status=Transaction.STATUS_PENDING),
                    distinct=True,
                ),
            )
            .order_by("-date_joined")
        )

        search = self.request.query_params.get("search")
        if search:
            queryset = queryset.filter(
                Q(full_name__icontains=search)
                | Q(phone_number__icontains=search)
                | Q(email__icontains=search)
            )

        kyc_status = self.request.query_params.get("kyc_status")
        if kyc_status and kyc_status.lower() != "all":
            queryset = queryset.filter(kyc_status__iexact=kyc_status)

        status_filter = self.request.query_params.get("status")
        if status_filter == "active":
            queryset = queryset.filter(is_active=True)
        elif status_filter == "inactive":
            queryset = queryset.filter(is_active=False)

        return queryset

    def get_serializer_class(self):
        if self.action == "retrieve":
            return AdminUserDetailSerializer
        return super().get_serializer_class()

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        # Ensure wallet relationship exists for serialization
        try:
            instance.get_wallet()
        except Exception:  # pragma: no cover - wallet creation is resilient
            pass
        serializer = self.get_serializer(instance)
        return Response(serializer.data)

    def partial_update(self, request, *args, **kwargs):
        instance = self.get_object()
        allowed_fields = {"kyc_status", "is_active"}
        payload = {key: value for key, value in request.data.items() if key in allowed_fields}
        if not payload:
            return Response({"detail": "No valid fields supplied."}, status=status.HTTP_400_BAD_REQUEST)

        for field, value in payload.items():
            setattr(instance, field, value)
        instance.save(update_fields=list(payload.keys()))

        AuditLog.objects.create(
            actor=request.user,
            action="user.updated",
            target_type="accounts.User",
            target_id=str(instance.pk),
            changes=payload,
        )

        serializer = self.get_serializer(instance)
        return Response(serializer.data)


class GroupViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsStaffUser]
    pagination_class = AdminPagination
    serializer_class = GroupSerializer

    def get_queryset(self):
        queryset = (
            Group.objects.all()
            .prefetch_related("invites")
            .select_related("owner")
            .annotate(
                member_count=Count("memberships", distinct=True),
                pending_invites=Count(
                    "invites",
                    filter=Q(invites__status=GroupInvite.STATUS_PENDING),
                    distinct=True,
                ),
            )
            .order_by("name")
        )

        search = self.request.query_params.get("search")
        if search:
            queryset = queryset.filter(name__icontains=search)

        return queryset


class SavingsGoalViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsStaffUser]
    pagination_class = AdminPagination
    serializer_class = SavingsGoalSerializer

    def get_queryset(self):
        queryset = SavingsGoal.objects.select_related("user").order_by("-created_at")

        user_id = self.request.query_params.get("user")
        if user_id:
            queryset = queryset.filter(user_id=user_id)

        return queryset


class TransactionViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsStaffUser]
    pagination_class = AdminPagination
    serializer_class = TransactionSerializer

    def get_queryset(self):
        queryset = (
            Transaction.objects.select_related("user", "group", "savings_goal")
            .order_by("-occurred_at", "-created_at")
        )

        transaction_type = self.request.query_params.get("type")
        if transaction_type and transaction_type.lower() != "all":
            queryset = queryset.filter(transaction_type=transaction_type)

        status_filter = self.request.query_params.get("status")
        if status_filter and status_filter.lower() != "all":
            queryset = queryset.filter(status=status_filter)

        search = self.request.query_params.get("search")
        if search:
            queryset = queryset.filter(
                Q(user__full_name__icontains=search)
                | Q(user__phone_number__icontains=search)
                | Q(reference__icontains=search)
            )

        return queryset


class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsStaffUser]
    serializer_class = AuditLogSerializer
    pagination_class = AdminPagination
    queryset = AuditLog.objects.select_related("actor")


class DashboardMetricsView(APIView):
    permission_classes = [IsStaffUser]

    def get(self, request, *args, **kwargs):
        now = timezone.now()
        start_of_week = now - timedelta(days=6)
        recent_transactions = Transaction.objects.filter(occurred_at__date__gte=now.date() - timedelta(days=30))

        active_members = User.objects.filter(is_active=True).count()
        total_wallet_balance = (
            Wallet.objects.aggregate(
                total=Coalesce(Sum("balance"), Value(Decimal("0.00")))
            )["total"]
        )
        pending_payouts = Transaction.objects.filter(
            transaction_type=Transaction.TYPE_PAYOUT,
            status=Transaction.STATUS_PENDING,
        ).count()
        pending_withdrawals = Transaction.objects.filter(
            transaction_type=Transaction.TYPE_WITHDRAWAL,
            status=Transaction.STATUS_PENDING,
        ).count()

        daily_volume_qs = (
            recent_transactions.exclude(status=Transaction.STATUS_FAILED)
            .annotate(day=TruncDate("occurred_at"))
            .values("day")
            .annotate(volume=Coalesce(Sum("amount"), Value(Decimal("0.00"))))
            .order_by("day")
        )
        daily_volume = [
            {"date": entry["day"], "volume": entry["volume"]} for entry in daily_volume_qs
        ]

        mix_qs = (
            recent_transactions.exclude(status=Transaction.STATUS_FAILED)
            .values("transaction_type")
            .annotate(total=Coalesce(Sum("amount"), Value(Decimal("0.00"))))
        )
        contribution_mix = [
            {"type": entry["transaction_type"], "amount": entry["total"]} for entry in mix_qs
        ]

        growth_qs = (
            User.objects.annotate(month=TruncMonth("date_joined"))
            .values("month")
            .annotate(total=Count("id"))
            .order_by("month")
        )
        cumulative = 0
        member_growth = []
        for entry in growth_qs:
            cumulative += entry["total"]
            member_growth.append(
                {
                    "month": entry["month"].date() if hasattr(entry["month"], "date") else entry["month"],
                    "new_members": entry["total"],
                    "total_members": cumulative,
                }
            )

        upcoming_payouts = [
            {
                "id": str(transaction.id),
                "reference": transaction.reference,
                "scheduled_for": transaction.occurred_at,
                "amount": transaction.amount,
                "group": transaction.group.name if transaction.group else None,
            }
            for transaction in Transaction.objects.filter(
                transaction_type=Transaction.TYPE_PAYOUT,
                status__in=[Transaction.STATUS_PENDING, Transaction.STATUS_SUCCESS],
                occurred_at__gte=start_of_week,
            ).order_by("occurred_at")[:10]
        ]

        notifications = []
        if pending_withdrawals:
            notifications.append(
                {
                    "id": "withdrawals-pending",
                    "title": "Pending withdrawals",
                    "level": "warning",
                    "message": f"{pending_withdrawals} withdrawal requests awaiting review.",
                    "created_at": now,
                }
            )
        if pending_payouts:
            notifications.append(
                {
                    "id": "payouts-pending",
                    "title": "Upcoming payouts",
                    "level": "info",
                    "message": f"{pending_payouts} payouts queued for members.",
                    "created_at": now,
                }
            )
        if not notifications:
            notifications.append(
                {
                    "id": "system-ok",
                    "title": "All systems nominal",
                    "level": "success",
                    "message": "No pending cashflow actions require attention.",
                    "created_at": now,
                }
            )

        payload = {
            "kpis": {
                "active_members": active_members,
                "total_wallet_balance": float(total_wallet_balance),
                "pending_payouts": pending_payouts,
                "pending_withdrawals": pending_withdrawals,
            },
            "daily_volume": daily_volume,
            "contribution_mix": contribution_mix,
            "member_growth": member_growth,
            "upcoming_payouts": upcoming_payouts,
            "notifications": notifications,
        }

        serializer = DashboardMetricsSerializer(payload)
        return Response(serializer.data)


class CashflowQueuesView(APIView):
    permission_classes = [IsStaffUser]

    def get(self, request, *args, **kwargs):
        pending_transactions = Transaction.objects.select_related("user").filter(
            transaction_type__in=[Transaction.TYPE_DEPOSIT, Transaction.TYPE_WITHDRAWAL],
            status__in=[Transaction.STATUS_PENDING, Transaction.STATUS_FAILED],
        )

        def _risk_for_transaction(transaction: Transaction) -> str:
            if transaction.status == Transaction.STATUS_FAILED:
                return "High"
            if transaction.amount >= Decimal("1500"):
                return "Medium"
            return "Low"

        queues: dict[str, list[dict[str, Any]]] = defaultdict(list)
        for tx in pending_transactions:
            entry = {
                "id": str(tx.id),
                "user": tx.user.full_name or tx.user.phone_number,
                "amount": tx.amount,
                "status": tx.status.title(),
                "channel": tx.channel or "Mobile Money",
                "risk": _risk_for_transaction(tx),
                "reference": tx.reference or "N/A",
                "submitted_at": tx.occurred_at,
                "checklist": {
                    "kyc": "Complete" if tx.user.kyc_status == "approved" else "Pending",
                    "wallet": "Sufficient" if tx.user.wallet_balance >= Decimal("0") else "Review",
                },
            }
            key = "deposits" if tx.transaction_type == Transaction.TYPE_DEPOSIT else "withdrawals"
            queues[key].append(entry)

        serializer = CashflowQueuesSerializer(
            {"deposits": queues.get("deposits", []), "withdrawals": queues.get("withdrawals", [])}
        )
        return Response(serializer.data)
