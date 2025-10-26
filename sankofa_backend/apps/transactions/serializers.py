from __future__ import annotations

from decimal import Decimal

from rest_framework import serializers

from .models import Transaction, Wallet


class TransactionSerializer(serializers.ModelSerializer):
    userId = serializers.UUIDField(source="user_id", read_only=True)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, coerce_to_string=False)
    date = serializers.DateTimeField(source="occurred_at")
    createdAt = serializers.DateTimeField(source="created_at")
    updatedAt = serializers.DateTimeField(source="updated_at")
    channel = serializers.CharField(allow_blank=True, allow_null=True, required=False)
    fee = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        allow_null=True,
        required=False,
        coerce_to_string=False,
    )
    reference = serializers.CharField(allow_blank=True, allow_null=True, required=False)
    counterparty = serializers.CharField(allow_blank=True, allow_null=True, required=False)
    groupId = serializers.UUIDField(source="group_id", allow_null=True, required=False)
    savingsGoalId = serializers.UUIDField(source="savings_goal_id", allow_null=True, required=False)
    balanceAfter = serializers.DecimalField(
        source="balance_after",
        max_digits=14,
        decimal_places=2,
        allow_null=True,
        required=False,
        coerce_to_string=False,
    )
    platformBalanceAfter = serializers.DecimalField(
        source="platform_balance_after",
        max_digits=14,
        decimal_places=2,
        allow_null=True,
        required=False,
        coerce_to_string=False,
    )

    class Meta:
        model = Transaction
        fields = (
            "id",
            "userId",
            "amount",
            "transaction_type",
            "status",
            "description",
            "date",
            "createdAt",
            "updatedAt",
            "channel",
            "fee",
            "reference",
            "counterparty",
            "groupId",
            "savingsGoalId",
            "balanceAfter",
            "platformBalanceAfter",
        )
        read_only_fields = fields

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data["type"] = data.pop("transaction_type")
        return data


class WalletSerializer(serializers.ModelSerializer):
    balance = serializers.DecimalField(max_digits=14, decimal_places=2, coerce_to_string=False)
    updatedAt = serializers.DateTimeField(source="updated_at")

    class Meta:
        model = Wallet
        fields = ("id", "user", "name", "is_platform", "currency", "balance", "updatedAt")
        read_only_fields = fields


class WalletOperationResponseSerializer(serializers.Serializer):
    transaction = TransactionSerializer()
    wallet = WalletSerializer()
    platformWallet = WalletSerializer()


class DepositRequestSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=0.5)
    channel = serializers.CharField(required=False, allow_blank=True)
    reference = serializers.CharField(required=False, allow_blank=True)
    fee = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        required=False,
        allow_null=True,
    )
    description = serializers.CharField(required=False, allow_blank=True)
    counterparty = serializers.CharField(required=False, allow_blank=True)


class WithdrawRequestSerializer(DepositRequestSerializer):
    destination = serializers.CharField(required=False, allow_blank=True)
    note = serializers.CharField(required=False, allow_blank=True)
    status = serializers.ChoiceField(
        choices=Transaction.STATUS_CHOICES,
        required=False,
        allow_blank=False,
    )


class _BreakdownSerializer(serializers.Serializer):
    type = serializers.CharField()
    count = serializers.IntegerField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, coerce_to_string=False)


class _StatusBreakdownSerializer(serializers.Serializer):
    status = serializers.CharField()
    count = serializers.IntegerField()


class TransactionSummarySerializer(serializers.Serializer):
    totalCount = serializers.IntegerField()
    totalInflow = serializers.DecimalField(max_digits=12, decimal_places=2, coerce_to_string=False)
    totalOutflow = serializers.DecimalField(max_digits=12, decimal_places=2, coerce_to_string=False)
    netCashflow = serializers.DecimalField(max_digits=12, decimal_places=2, coerce_to_string=False)
    pendingCount = serializers.IntegerField()
    lastTransactionAt = serializers.DateTimeField(allow_null=True)
    totalsByType = _BreakdownSerializer(many=True)
    totalsByStatus = _StatusBreakdownSerializer(many=True)

    @staticmethod
    def format_breakdown_item(key: str, count: int, amount: Decimal) -> dict[str, object]:
        return {"type": key, "count": count, "amount": amount}
