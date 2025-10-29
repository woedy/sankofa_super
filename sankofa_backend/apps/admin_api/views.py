from __future__ import annotations

from collections import defaultdict
from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import Any

from django.contrib.auth import get_user_model
from django.db import transaction
from django.db.models import Count, Q, Sum, Value
from django.db.models.functions import Coalesce, TruncDate, TruncMonth
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response
from rest_framework.views import APIView

from ..disputes.models import Dispute, SupportArticle
from ..disputes.serializers import DisputeMessageCreateSerializer
from ..groups.models import Group, GroupInvite
from ..savings.models import SavingsGoal
from ..transactions.models import Transaction, Wallet
from .models import AuditLog
from .permissions import IsStaffUser
from .serializers import (
    AdminDisputeSerializer,
    AdminDisputeUpdateSerializer,
    AdminSupportArticleSerializer,
    AdminTokenObtainSerializer,
    AdminUserDetailSerializer,
    AdminUserSummarySerializer,
    AuditLogSerializer,
    CashflowQueuesSerializer,
    DashboardMetricsSerializer,
    GroupSerializer,
    GroupInviteInputSerializer,
    GroupWriteSerializer,
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


class GroupViewSet(viewsets.ModelViewSet):
    permission_classes = [IsStaffUser]
    pagination_class = AdminPagination
    serializer_class = GroupSerializer

    def get_queryset(self):
        queryset = (
            Group.objects.all()
            .prefetch_related("invites", "memberships__user")
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

    def get_serializer_class(self):
        if self.action in {"create", "update", "partial_update"}:
            return GroupWriteSerializer
        return super().get_serializer_class()

    def _get_refreshed_group(self, pk: Any) -> Group:
        return self.get_queryset().get(pk=pk)

    def _serialize_changes(self, changes: dict[str, Any]) -> dict[str, Any]:
        serialized: dict[str, Any] = {}
        for key, value in changes.items():
            if isinstance(value, Decimal):
                serialized[key] = str(value)
            elif isinstance(value, (datetime, date)):
                serialized[key] = value.isoformat()
            else:
                serialized[key] = value
        return serialized

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        group = serializer.save()

        AuditLog.objects.create(
            actor=request.user,
            action="group.created",
            target_type="groups.Group",
            target_id=str(group.pk),
            changes=self._serialize_changes(serializer.validated_data),
        )

        read_serializer = GroupSerializer(self._get_refreshed_group(group.pk), context=self.get_serializer_context())
        headers = self.get_success_headers(read_serializer.data)
        return Response(read_serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        group = serializer.save()

        AuditLog.objects.create(
            actor=request.user,
            action="group.updated",
            target_type="groups.Group",
            target_id=str(group.pk),
            changes=self._serialize_changes(serializer.validated_data),
        )

        read_serializer = GroupSerializer(self._get_refreshed_group(group.pk), context=self.get_serializer_context())
        return Response(read_serializer.data)

    def partial_update(self, request, *args, **kwargs):
        kwargs["partial"] = True
        return self.update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        group_id = str(instance.pk)
        instance.delete()

        AuditLog.objects.create(
            actor=request.user,
            action="group.deleted",
            target_type="groups.Group",
            target_id=group_id,
        )

        return Response(status=status.HTTP_204_NO_CONTENT)

    def _build_response(self, group: Group) -> Response:
        serializer = GroupSerializer(self._get_refreshed_group(group.pk), context=self.get_serializer_context())
        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(methods=["post"], detail=True, url_path="invites")
    def create_invites(self, request, pk=None):
        group = self.get_object()
        payload = request.data
        invites_payload = payload.get("invites") if isinstance(payload, dict) else None

        if invites_payload is None:
            invites_payload = [payload]

        serializer = GroupInviteInputSerializer(data=invites_payload, many=True)
        serializer.is_valid(raise_exception=True)

        created = []
        seen_numbers: set[str] = set()
        for invite_data in serializer.validated_data:
            phone_number = invite_data["phone_number"]
            if phone_number in seen_numbers:
                continue
            seen_numbers.add(phone_number)
            if group.memberships.filter(user__phone_number=phone_number).exists():
                continue
            if group.invites.filter(phone_number=phone_number, status=GroupInvite.STATUS_PENDING).exists():
                continue
            created.append(
                GroupInvite.objects.create(
                    group=group,
                    name=invite_data["name"],
                    phone_number=phone_number,
                )
            )

        if created:
            AuditLog.objects.create(
                actor=request.user,
                action="group.invite.created",
                target_type="groups.Group",
                target_id=str(group.pk),
                metadata={"count": len(created)},
            )

        return self._build_response(group)

    @action(methods=["post"], detail=True, url_path=r"invites/(?P<invite_id>[^/]+)/approve")
    def approve_invite(self, request, pk=None, invite_id=None):
        group = self.get_object()
        invite = get_object_or_404(group.invites, pk=invite_id)

        with transaction.atomic():
            user_model = get_user_model()
            normalized_phone = user_model.objects.normalize_phone(invite.phone_number)
            member, _created = user_model.objects.get_or_create(
                phone_number=normalized_phone,
                defaults={"full_name": invite.name},
            )

            membership, created_membership = group.memberships.get_or_create(
                user=member,
                defaults={"display_name": invite.name or member.full_name or member.phone_number},
            )

            invite.status = GroupInvite.STATUS_ACCEPTED
            invite.kyc_completed = True
            invite.responded_at = timezone.now()
            invite.save(update_fields=["status", "kyc_completed", "responded_at"])

        AuditLog.objects.create(
            actor=request.user,
            action="group.invite.approved",
            target_type="groups.GroupInvite",
            target_id=str(invite.pk),
            metadata={"group": str(group.pk), "member": str(membership.user_id)},
        )

        return self._build_response(group)

    @action(methods=["post"], detail=True, url_path=r"invites/(?P<invite_id>[^/]+)/decline")
    def decline_invite(self, request, pk=None, invite_id=None):
        group = self.get_object()
        invite = get_object_or_404(group.invites, pk=invite_id)

        invite.status = GroupInvite.STATUS_DECLINED
        invite.responded_at = timezone.now()
        invite.save(update_fields=["status", "responded_at"])

        AuditLog.objects.create(
            actor=request.user,
            action="group.invite.declined",
            target_type="groups.GroupInvite",
            target_id=str(invite.pk),
            metadata={"group": str(group.pk)},
        )

        return self._build_response(group)

    @action(methods=["delete"], detail=True, url_path=r"invites/(?P<invite_id>[^/]+)")
    def delete_invite(self, request, pk=None, invite_id=None):
        group = self.get_object()
        invite = get_object_or_404(group.invites, pk=invite_id)
        invite.delete()

        AuditLog.objects.create(
            actor=request.user,
            action="group.invite.deleted",
            target_type="groups.GroupInvite",
            target_id=str(invite_id),
            metadata={"group": str(group.pk)},
        )

        return self._build_response(group)

    @action(methods=["delete"], detail=True, url_path=r"members/(?P<user_id>[^/]+)")
    def remove_member(self, request, pk=None, user_id=None):
        group = self.get_object()
        membership = group.memberships.filter(user_id=user_id).first()
        if membership is None:
            return Response({"detail": "Member not found."}, status=status.HTTP_404_NOT_FOUND)

        membership.delete()

        AuditLog.objects.create(
            actor=request.user,
            action="group.member.removed",
            target_type="groups.GroupMembership",
            target_id=str(user_id),
            metadata={"group": str(group.pk)},
        )

        return self._build_response(group)


class DisputeViewSet(viewsets.ModelViewSet):
    permission_classes = [IsStaffUser]
    pagination_class = AdminPagination
    serializer_class = AdminDisputeSerializer

    def get_queryset(self):
        queryset = (
            Dispute.objects.all()
            .select_related("user", "group", "assigned_to", "related_article")
            .prefetch_related("messages", "attachments")
            .order_by("-opened_at")
        )

        severity = self.request.query_params.get("severity")
        if severity and severity.lower() != "all":
            normalized = self._match_choice(Dispute.Severity.choices, severity)
            queryset = queryset.filter(severity__iexact=normalized)

        status_filter = self.request.query_params.get("status")
        if status_filter and status_filter.lower() != "all":
            normalized_status = self._match_choice(Dispute.Status.choices, status_filter)
            queryset = queryset.filter(status__iexact=normalized_status)

        sla_status = self.request.query_params.get("sla_status")
        if sla_status and sla_status.lower() != "all":
            normalized_sla = self._match_choice(Dispute.SlaStatus.choices, sla_status)
            queryset = queryset.filter(sla_status__iexact=normalized_sla)

        channel = self.request.query_params.get("channel")
        if channel and channel.lower() != "all":
            normalized_channel = self._match_choice(Dispute.Channel.choices, channel)
            queryset = queryset.filter(channel__iexact=normalized_channel)

        assigned_to = self.request.query_params.get("assigned_to")
        if assigned_to:
            if assigned_to.lower() == "unassigned":
                queryset = queryset.filter(assigned_to__isnull=True)
            else:
                queryset = queryset.filter(assigned_to_id=assigned_to)

        search = self.request.query_params.get("search")
        if search:
            query = search.strip()
            if query:
                queryset = queryset.filter(
                    Q(case_number__icontains=query)
                    | Q(title__icontains=query)
                    | Q(user__full_name__icontains=query)
                    | Q(user__phone_number__icontains=query)
                    | Q(group__name__icontains=query)
                )

        return queryset

    def get_serializer_class(self):
        if self.action in {"update", "partial_update"}:
            return AdminDisputeUpdateSerializer
        return super().get_serializer_class()

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context.setdefault("request", self.request)
        return context

    def _match_choice(self, choices, value):
        normalized = value.strip().lower().replace("-", " ").replace("_", " ")
        for choice, _label in choices:
            if choice.lower() == normalized:
                return choice
        return value

    def _serialize_changes(self, changes: dict[str, Any]) -> dict[str, Any]:
        serialized: dict[str, Any] = {}
        for key, value in changes.items():
            if isinstance(value, Decimal):
                serialized[key] = str(value)
            elif isinstance(value, (datetime, date)):
                serialized[key] = value.isoformat()
            elif hasattr(value, "pk"):
                serialized[key] = str(value.pk)
            else:
                serialized[key] = value
        return serialized

    def _get_refreshed(self, pk):
        return self.get_queryset().get(pk=pk)

    def _update_dispute(self, request, *args, partial: bool = False, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        refreshed = self._get_refreshed(instance.pk)
        read_serializer = AdminDisputeSerializer(refreshed, context=self.get_serializer_context())
        return Response(read_serializer.data)

    def update(self, request, *args, **kwargs):
        return self._update_dispute(request, *args, partial=False, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        return self._update_dispute(request, *args, partial=True, **kwargs)

    def perform_update(self, serializer):
        changes = dict(serializer.validated_data)
        dispute = serializer.save()
        AuditLog.objects.create(
            actor=self.request.user,
            action="dispute.updated",
            target_type="disputes.Dispute",
            target_id=str(dispute.pk),
            changes=self._serialize_changes(changes),
        )

    @action(detail=True, methods=["post"], url_path="messages")
    def add_message(self, request, *args, **kwargs):
        dispute = self.get_object()
        serializer = DisputeMessageCreateSerializer(
            data=request.data,
            context={"dispute": dispute, "author": request.user},
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        refreshed = self._get_refreshed(dispute.pk)
        read_serializer = AdminDisputeSerializer(refreshed, context=self.get_serializer_context())
        return Response(read_serializer.data, status=status.HTTP_200_OK)


class SupportArticleViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsStaffUser]
    serializer_class = AdminSupportArticleSerializer

    def get_queryset(self):
        queryset = SupportArticle.objects.all().order_by("title")
        category = self.request.query_params.get("category")
        if category and category.lower() != "all":
            queryset = queryset.filter(category__iexact=category)
        search = self.request.query_params.get("search")
        if search:
            query = search.strip()
            if query:
                queryset = queryset.filter(
                    Q(title__icontains=query) | Q(summary__icontains=query)
                )
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
        week_start_date = start_of_week.date()
        previous_week_end = week_start_date - timedelta(days=1)
        recent_transactions = Transaction.objects.filter(occurred_at__date__gte=now.date() - timedelta(days=30))

        active_members = User.objects.filter(is_active=True).count()
        previous_active_members = User.objects.filter(is_active=True, date_joined__date__lte=previous_week_end).count()

        total_wallet_balance = (
            Wallet.objects.aggregate(
                total=Coalesce(Sum("balance"), Value(Decimal("0.00")))
            )["total"]
        )

        week_transactions = Transaction.objects.filter(
            occurred_at__date__gte=week_start_date,
            occurred_at__date__lte=now.date(),
            status=Transaction.STATUS_SUCCESS,
        )
        inflow_total = (
            week_transactions.filter(transaction_type__in=Transaction.INFLOW_TYPES)
            .aggregate(total=Coalesce(Sum("amount"), Value(Decimal("0.00"))))
            ["total"]
        )
        outflow_total = (
            week_transactions.filter(transaction_type__in=Transaction.OUTFLOW_TYPES)
            .aggregate(total=Coalesce(Sum("amount"), Value(Decimal("0.00"))))
            ["total"]
        )
        current_total_balance = total_wallet_balance or Decimal("0.00")
        inflow_total = inflow_total or Decimal("0.00")
        outflow_total = outflow_total or Decimal("0.00")
        previous_total_wallet_balance = max(
            Decimal("0.00"),
            Decimal(current_total_balance) - Decimal(inflow_total) + Decimal(outflow_total),
        )

        pending_payouts_qs = Transaction.objects.filter(
            transaction_type=Transaction.TYPE_PAYOUT,
            status=Transaction.STATUS_PENDING,
        )
        pending_payouts = pending_payouts_qs.count()
        previous_pending_payouts = pending_payouts_qs.filter(occurred_at__date__lt=week_start_date).count()

        pending_withdrawals_qs = Transaction.objects.filter(
            transaction_type=Transaction.TYPE_WITHDRAWAL,
            status=Transaction.STATUS_PENDING,
        )
        pending_withdrawals = pending_withdrawals_qs.count()
        previous_pending_withdrawals = pending_withdrawals_qs.filter(occurred_at__date__lt=week_start_date).count()

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
                "user": transaction.user.full_name or transaction.user.phone_number,
                "description": transaction.description,
                "status": transaction.status,
            }
            for transaction in Transaction.objects.filter(
                transaction_type=Transaction.TYPE_PAYOUT,
                status__in=[Transaction.STATUS_PENDING, Transaction.STATUS_SUCCESS],
                occurred_at__gte=start_of_week,
            )
            .select_related("group", "user")
            .order_by("occurred_at")[:10]
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
                "active_members": {
                    "current": float(active_members),
                    "previous": float(previous_active_members),
                },
                "total_wallet_balance": {
                    "current": float(total_wallet_balance),
                    "previous": float(previous_total_wallet_balance),
                },
                "pending_payouts": {
                    "current": float(pending_payouts),
                    "previous": float(previous_pending_payouts),
                },
                "pending_withdrawals": {
                    "current": float(pending_withdrawals),
                    "previous": float(previous_pending_withdrawals),
                },
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
