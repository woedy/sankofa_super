from __future__ import annotations

from rest_framework import serializers

from .models import SavingsContribution, SavingsGoal, SavingsRedemption
from sankofa_backend.apps.transactions.serializers import TransactionSerializer, WalletSerializer


class SavingsGoalSerializer(serializers.ModelSerializer):
    userId = serializers.UUIDField(source="user_id", read_only=True)
    targetAmount = serializers.DecimalField(source="target_amount", max_digits=12, decimal_places=2, coerce_to_string=False)
    currentAmount = serializers.DecimalField(
        source="current_amount", max_digits=12, decimal_places=2, coerce_to_string=False, read_only=True
    )
    deadline = serializers.DateTimeField()
    createdAt = serializers.DateTimeField(source="created_at", read_only=True)
    updatedAt = serializers.DateTimeField(source="updated_at", read_only=True)

    class Meta:
        model = SavingsGoal
        fields = (
            "id",
            "userId",
            "title",
            "targetAmount",
            "currentAmount",
            "deadline",
            "category",
            "createdAt",
            "updatedAt",
        )

    def create(self, validated_data):
        user = self.context["request"].user
        return SavingsGoal.objects.create(user=user, **validated_data)


class SavingsContributionSerializer(serializers.ModelSerializer):
    goalId = serializers.UUIDField(source="goal_id", read_only=True)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, coerce_to_string=False)
    date = serializers.DateTimeField(source="recorded_at", read_only=True)

    class Meta:
        model = SavingsContribution
        fields = ("id", "goalId", "amount", "channel", "note", "date")
        read_only_fields = ("id", "goalId", "date")


class SavingsContributionCreateSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, coerce_to_string=False)
    channel = serializers.CharField(max_length=64, required=False, default="Mobile Money")
    note = serializers.CharField(max_length=255, required=False, allow_blank=True)

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Contribution amount must be greater than zero.")
        return value


class SavingsRedemptionSerializer(serializers.ModelSerializer):
    goalId = serializers.UUIDField(source="goal_id", read_only=True)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, coerce_to_string=False)
    date = serializers.DateTimeField(source="recorded_at", read_only=True)

    class Meta:
        model = SavingsRedemption
        fields = ("id", "goalId", "amount", "channel", "note", "date")
        read_only_fields = ("id", "goalId", "date")


class SavingsRedemptionCreateSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, coerce_to_string=False)
    channel = serializers.CharField(max_length=64, required=False, default="Mobile Money")
    note = serializers.CharField(max_length=255, required=False, allow_blank=True)

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Collection amount must be greater than zero.")
        return value


class SavingsMilestoneSerializer(serializers.Serializer):
    threshold = serializers.FloatField()
    achievedAt = serializers.DateTimeField()
    message = serializers.CharField()


class SavingsContributionOutcomeSerializer(serializers.Serializer):
    goal = SavingsGoalSerializer()
    contribution = SavingsContributionSerializer()
    unlockedMilestones = SavingsMilestoneSerializer(many=True)
    transaction = TransactionSerializer()
    wallet = WalletSerializer()
    platformWallet = WalletSerializer()


class SavingsRedemptionOutcomeSerializer(serializers.Serializer):
    goal = SavingsGoalSerializer()
    redemption = SavingsRedemptionSerializer()
    transaction = TransactionSerializer()
    wallet = WalletSerializer()
    platformWallet = WalletSerializer()
