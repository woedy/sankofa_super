from __future__ import annotations

from typing import Any

from django.contrib.auth import get_user_model
from django.db.models import Count, Q
from rest_framework import serializers
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.tokens import RefreshToken

from ..accounts.services import get_platform_user
from ..disputes.models import Dispute
from ..disputes.serializers import (
    DisputeSerializer as BaseDisputeSerializer,
    DisputeUpdateSerializer as BaseDisputeUpdateSerializer,
    SupportArticleSerializer as BaseSupportArticleSerializer,
)
from ..groups.models import Group, GroupInvite
from ..savings.models import SavingsGoal
from ..transactions.models import Transaction, Wallet
from .models import AuditLog

User = get_user_model()


class AdminUserSummarySerializer(serializers.ModelSerializer):
    wallet_balance = serializers.SerializerMethodField()
    wallet_updated_at = serializers.SerializerMethodField()
    groups_count = serializers.SerializerMethodField()
    savings_goal_count = serializers.SerializerMethodField()
    pending_transactions = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            "id",
            "full_name",
            "phone_number",
            "email",
            "kyc_status",
            "is_active",
            "is_staff",
            "last_login",
            "wallet_balance",
            "wallet_updated_at",
            "groups_count",
            "savings_goal_count",
            "pending_transactions",
        )

    def _get_wallet(self, obj: User):
        wallet = getattr(obj, "wallet", None)
        if wallet is None:
            try:
                wallet = obj.get_wallet()
            except Exception:  # pragma: no cover - fallback when wallet creation fails
                return None
        return wallet

    def get_wallet_balance(self, obj: User):
        wallet = self._get_wallet(obj)
        if wallet is None:
            return "0.00"
        return str(wallet.balance)

    def get_wallet_updated_at(self, obj: User):
        wallet = self._get_wallet(obj)
        if wallet and wallet.updated_at:
            return wallet.updated_at
        return None

    def get_groups_count(self, obj: User) -> int:
        annotated = getattr(obj, "groups_count", None)
        if annotated is not None:
            return int(annotated)
        memberships = getattr(obj, "group_memberships", None)
        if memberships is None:
            return obj.group_memberships.count()
        queryset = memberships.all()
        return len(queryset)

    def get_savings_goal_count(self, obj: User) -> int:
        annotated = getattr(obj, "savings_goal_count", None)
        if annotated is not None:
            return int(annotated)
        goals = getattr(obj, "savings_goals", None)
        if goals is None:
            return obj.savings_goals.count()
        queryset = goals.all()
        return len(queryset)

    def get_pending_transactions(self, obj: User) -> int:
        annotated = getattr(obj, "pending_transactions", None)
        if annotated is not None:
            return int(annotated)
        transactions = getattr(obj, "transactions", None)
        if transactions is None:
            return obj.transactions.filter(status=Transaction.STATUS_PENDING).count()
        queryset = transactions.all()
        if hasattr(queryset, "filter"):
            return queryset.filter(status=Transaction.STATUS_PENDING).count()
        return 0


class AdminTokenObtainSerializer(serializers.Serializer):
    identifier = serializers.CharField()
    password = serializers.CharField(write_only=True)
    access = serializers.CharField(read_only=True)
    refresh = serializers.CharField(read_only=True)
    user = AdminUserSummarySerializer(read_only=True)

    default_error_messages = {
        "no_active_account": "Unable to sign in with the provided credentials.",
        "not_staff": "Account is not authorized for admin access.",
    }

    def _normalize_identifier(self, identifier: str) -> tuple[str, str]:
        normalized = identifier.strip()
        if "@" in normalized:
            return "email__iexact", normalized
        try:
            normalized_phone = User.objects.normalize_phone(normalized)
            return "phone_number", normalized_phone
        except Exception:  # pragma: no cover - defensive
            return "phone_number", normalized

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        identifier = attrs.get("identifier", "")
        password = attrs.get("password")
        if not identifier or not password:
            raise AuthenticationFailed(self.error_messages["no_active_account"], code="no_active_account")

        lookup, value = self._normalize_identifier(identifier)
        try:
            user = User.objects.select_related("wallet").prefetch_related(
                "group_memberships",
                "savings_goals",
                "transactions",
            ).get(**{lookup: value})
        except User.DoesNotExist as exc:
            raise AuthenticationFailed(self.error_messages["no_active_account"], code="no_active_account") from exc

        if not user.is_active or not user.check_password(password):
            raise AuthenticationFailed(self.error_messages["no_active_account"], code="no_active_account")

        if not user.is_staff:
            raise AuthenticationFailed(self.error_messages["not_staff"], code="not_staff")

        user.get_wallet()

        refresh = RefreshToken.for_user(user)
        data = {
            "refresh": str(refresh),
            "access": str(refresh.access_token),
            "user": AdminUserSummarySerializer(user).data,
        }
        return data


class AuditLogSerializer(serializers.ModelSerializer):
    actor_name = serializers.SerializerMethodField()

    class Meta:
        model = AuditLog
        fields = ("id", "action", "target_type", "target_id", "changes", "metadata", "actor", "actor_name", "created_at")
        read_only_fields = fields

    def get_actor_name(self, obj: AuditLog) -> str:
        if obj.actor:
            return obj.actor.full_name or obj.actor.phone_number
        return "System"


class GroupInviteSerializer(serializers.ModelSerializer):
    class Meta:
        model = GroupInvite
        fields = ("id", "name", "phone_number", "status", "kyc_completed", "sent_at", "responded_at", "last_reminded_at")


class GroupMemberSerializer(serializers.Serializer):
    id = serializers.CharField()
    name = serializers.CharField()
    phone_number = serializers.CharField()
    joined_at = serializers.DateTimeField()


class GroupSerializer(serializers.ModelSerializer):
    member_count = serializers.IntegerField()
    pending_invites = serializers.IntegerField()
    owner_name = serializers.SerializerMethodField()
    invites = GroupInviteSerializer(many=True, read_only=True)
    members = serializers.SerializerMethodField()

    class Meta:
        model = Group
        fields = (
            "id",
            "name",
            "description",
            "frequency",
            "location",
            "requires_approval",
            "is_public",
            "target_member_count",
            "contribution_amount",
            "cycle_number",
            "total_cycles",
            "next_payout_date",
            "created_at",
            "updated_at",
            "owner_name",
            "member_count",
            "pending_invites",
            "invites",
            "members",
        )

    def get_owner_name(self, obj: Group) -> str | None:
        if obj.owner:
            return obj.owner.full_name or obj.owner.phone_number
        return None

    def get_members(self, obj: Group) -> list[dict[str, Any]]:
        memberships = getattr(obj, "_prefetched_members", None)
        if memberships is None:
            memberships = list(obj.memberships.select_related("user"))
        members: list[dict[str, Any]] = []
        for membership in memberships:
            user = membership.user
            display = membership.display_name or getattr(user, "full_name", None) or getattr(user, "phone_number", "")
            members.append(
                {
                    "id": str(user.pk),
                    "name": display,
                    "phone_number": user.phone_number,
                    "joined_at": membership.joined_at,
                }
            )
        return members


class GroupInviteInputSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=255)
    phone_number = serializers.CharField(max_length=32)

    def validate_name(self, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise serializers.ValidationError("Invite name is required.")
        return normalized

    def validate_phone_number(self, value: str) -> str:
        try:
            return User.objects.normalize_phone(value)
        except Exception as exc:  # pragma: no cover - defensive sanitization
            raise serializers.ValidationError("Enter a valid phone number.") from exc


class GroupWriteSerializer(serializers.ModelSerializer):
    invites = GroupInviteInputSerializer(many=True, required=False, write_only=True)

    class Meta:
        model = Group
        fields = (
            "name",
            "description",
            "frequency",
            "location",
            "requires_approval",
            "is_public",
            "target_member_count",
            "contribution_amount",
            "cycle_number",
            "total_cycles",
            "next_payout_date",
            "payout_order",
            "invites",
        )
        extra_kwargs = {
            "cycle_number": {"required": False},
            "total_cycles": {"required": False},
            "is_public": {"required": False},
            "payout_order": {"required": False},
            "description": {"required": False, "allow_blank": True},
            "frequency": {"required": False, "allow_blank": True},
            "location": {"required": False, "allow_blank": True},
        }

    def validate_target_member_count(self, value: int) -> int:
        if value < 1:
            raise serializers.ValidationError("Target member count must be at least 1.")
        return value

    def validate_total_cycles(self, value: int) -> int:
        if value < 1:
            raise serializers.ValidationError("Total cycles must be at least 1.")
        return value

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        invites = attrs.get("invites") or []
        seen_numbers: set[str] = set()
        for invite in invites:
            phone = invite["phone_number"]
            if phone in seen_numbers:
                raise serializers.ValidationError(
                    {"invites": "Each invite must use a unique phone number."}
                )
            seen_numbers.add(phone)

        attrs.setdefault("is_public", True)
        attrs.setdefault("requires_approval", True)

        member_target = attrs.get("target_member_count")
        if member_target is None:
            attrs["target_member_count"] = max(len(invites), 1)
        elif member_target < len(invites):
            raise serializers.ValidationError(
                {"target_member_count": "Must be greater than or equal to the number of pending invites."}
            )

        total_cycles = attrs.get("total_cycles")
        if total_cycles is None:
            attrs["total_cycles"] = attrs["target_member_count"]
        elif total_cycles < attrs["target_member_count"]:
            raise serializers.ValidationError(
                {"total_cycles": "Total cycles must be at least the target member count."}
            )

        cycle_number = attrs.get("cycle_number")
        if cycle_number is None:
            attrs["cycle_number"] = 1
        elif cycle_number < 1:
            raise serializers.ValidationError({"cycle_number": "Cycle number must be at least 1."})

        return attrs

    def create(self, validated_data: dict[str, Any]) -> Group:
        invites = validated_data.pop("invites", [])
        owner = get_platform_user()
        if owner is None:
            raise serializers.ValidationError("Platform owner account is not provisioned.")

        group = Group.objects.create(owner=owner, **validated_data)

        for invite in invites:
            GroupInvite.objects.create(
                group=group,
                name=invite["name"],
                phone_number=invite["phone_number"],
            )

        return group

    def update(self, instance: Group, validated_data: dict[str, Any]) -> Group:
        invites = validated_data.pop("invites", None)
        if invites:
            raise serializers.ValidationError({"invites": "Use the invite endpoints to manage invites."})

        target_member_count = validated_data.get("target_member_count")
        if target_member_count is not None:
            member_count = instance.memberships.count()
            if target_member_count < member_count:
                raise serializers.ValidationError(
                    {"target_member_count": "Cannot reduce below the current member count."}
                )

        total_cycles = validated_data.get("total_cycles")
        if total_cycles is not None and total_cycles < instance.cycle_number:
            raise serializers.ValidationError(
                {"total_cycles": "Total cycles cannot be less than the current cycle number."}
            )

        for field, value in validated_data.items():
            setattr(instance, field, value)

        instance.save()
        return instance


class SavingsGoalSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()
    progress = serializers.SerializerMethodField()

    class Meta:
        model = SavingsGoal
        fields = (
            "id",
            "title",
            "category",
            "target_amount",
            "current_amount",
            "progress",
            "deadline",
            "created_at",
            "updated_at",
            "user",
            "user_name",
        )

    def get_user_name(self, obj: SavingsGoal) -> str:
        return obj.user.full_name or obj.user.phone_number

    def get_progress(self, obj: SavingsGoal) -> float:
        if obj.target_amount:
            return float(obj.current_amount / obj.target_amount)
        return 0.0


class TransactionSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()
    group_name = serializers.SerializerMethodField()
    savings_goal_title = serializers.SerializerMethodField()

    class Meta:
        model = Transaction
        fields = (
            "id",
            "user",
            "user_name",
            "transaction_type",
            "status",
            "amount",
            "description",
            "occurred_at",
            "channel",
            "reference",
            "fee",
            "counterparty",
            "balance_after",
            "platform_balance_after",
            "group",
            "group_name",
            "savings_goal",
            "savings_goal_title",
        )

    def get_user_name(self, obj: Transaction) -> str:
        return obj.user.full_name or obj.user.phone_number

    def get_group_name(self, obj: Transaction) -> str | None:
        if obj.group:
            return obj.group.name
        return None

    def get_savings_goal_title(self, obj: Transaction) -> str | None:
        if obj.savings_goal:
            return obj.savings_goal.title
        return None


class WalletSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()

    class Meta:
        model = Wallet
        fields = ("id", "user", "user_name", "name", "is_platform", "balance", "currency", "updated_at")

    def get_user_name(self, obj: Wallet) -> str | None:
        if obj.user:
            return obj.user.full_name or obj.user.phone_number
        return obj.name


class AdminUserDetailSerializer(AdminUserSummarySerializer):
    wallet = WalletSerializer(read_only=True)
    savings_goals = SavingsGoalSerializer(many=True, read_only=True)
    recent_transactions = serializers.SerializerMethodField()
    groups = serializers.SerializerMethodField()

    class Meta(AdminUserSummarySerializer.Meta):
        fields = AdminUserSummarySerializer.Meta.fields + (
            "wallet",
            "savings_goals",
            "recent_transactions",
            "groups",
        )

    def get_recent_transactions(self, obj: User):
        queryset = obj.transactions.select_related("group", "savings_goal").order_by("-occurred_at")[:10]
        return TransactionSerializer(queryset, many=True, context=self.context).data

    def get_groups(self, obj: User):
        queryset = (
            Group.objects.filter(memberships__user=obj)
            .prefetch_related("invites")
            .annotate(
                member_count=Count("memberships", distinct=True),
                pending_invites=Count(
                    "invites",
                    filter=Q(invites__status=GroupInvite.STATUS_PENDING),
                    distinct=True,
                ),
            )
            .distinct()
        )
        return GroupSerializer(queryset, many=True, context=self.context).data


class DashboardNotificationSerializer(serializers.Serializer):
    id = serializers.CharField()
    title = serializers.CharField()
    level = serializers.ChoiceField(choices=["alert", "warning", "success", "info"])
    message = serializers.CharField()
    created_at = serializers.DateTimeField()


class DailyVolumePointSerializer(serializers.Serializer):
    date = serializers.DateField()
    volume = serializers.DecimalField(max_digits=14, decimal_places=2)


class ContributionSliceSerializer(serializers.Serializer):
    type = serializers.CharField()
    amount = serializers.DecimalField(max_digits=14, decimal_places=2)


class MemberGrowthPointSerializer(serializers.Serializer):
    month = serializers.DateField()
    new_members = serializers.IntegerField()
    total_members = serializers.IntegerField()


class UpcomingPayoutSerializer(serializers.Serializer):
    id = serializers.CharField()
    reference = serializers.CharField(allow_blank=True, allow_null=True)
    scheduled_for = serializers.DateTimeField()
    amount = serializers.DecimalField(max_digits=14, decimal_places=2)
    group = serializers.CharField(allow_null=True, allow_blank=True)
    user = serializers.CharField(allow_null=True, allow_blank=True)
    description = serializers.CharField(allow_blank=True)
    status = serializers.CharField()


class DashboardMetricsSerializer(serializers.Serializer):
    kpis = serializers.DictField(child=serializers.DictField(child=serializers.FloatField()))
    daily_volume = DailyVolumePointSerializer(many=True)
    contribution_mix = ContributionSliceSerializer(many=True)
    member_growth = MemberGrowthPointSerializer(many=True)
    upcoming_payouts = UpcomingPayoutSerializer(many=True)
    notifications = DashboardNotificationSerializer(many=True)


class CashflowQueueItemSerializer(serializers.Serializer):
    id = serializers.CharField()
    user = serializers.CharField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    status = serializers.CharField()
    channel = serializers.CharField()
    risk = serializers.CharField()
    reference = serializers.CharField()
    submitted_at = serializers.DateTimeField()
    checklist = serializers.DictField(child=serializers.CharField())


class CashflowQueuesSerializer(serializers.Serializer):
    deposits = CashflowQueueItemSerializer(many=True)
    withdrawals = CashflowQueueItemSerializer(many=True)


class AdminSupportArticleSerializer(BaseSupportArticleSerializer):
    class Meta(BaseSupportArticleSerializer.Meta):
        model = BaseSupportArticleSerializer.Meta.model
        fields = BaseSupportArticleSerializer.Meta.fields
        read_only_fields = BaseSupportArticleSerializer.Meta.read_only_fields


class AdminDisputeSerializer(BaseDisputeSerializer):
    class Meta(BaseDisputeSerializer.Meta):
        model = Dispute
        fields = BaseDisputeSerializer.Meta.fields
        read_only_fields = BaseDisputeSerializer.Meta.read_only_fields


class AdminDisputeUpdateSerializer(BaseDisputeUpdateSerializer):
    class Meta(BaseDisputeUpdateSerializer.Meta):
        model = Dispute
        fields = BaseDisputeUpdateSerializer.Meta.fields
