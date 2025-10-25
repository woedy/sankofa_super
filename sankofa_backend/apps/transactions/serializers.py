from __future__ import annotations

from decimal import Decimal

from rest_framework import serializers

from .models import Transaction


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
        )
        read_only_fields = fields

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data["type"] = data.pop("transaction_type")
        return data


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
