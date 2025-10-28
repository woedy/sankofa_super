from __future__ import annotations

from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from .models import SavingsGoal
from .serializers import (
    SavingsContributionCreateSerializer,
    SavingsContributionOutcomeSerializer,
    SavingsContributionSerializer,
    SavingsGoalSerializer,
    SavingsRedemptionCreateSerializer,
    SavingsRedemptionOutcomeSerializer,
)
from .services import collect_savings, record_contribution
from sankofa_backend.apps.groups.realtime import broadcast_group_event


class SavingsGoalViewSet(viewsets.ModelViewSet):
    serializer_class = SavingsGoalSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return SavingsGoal.objects.for_user(self.request.user).prefetch_related("contributions")

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context.setdefault("request", self.request)
        return context

    def perform_create(self, serializer):
        serializer.save()

    @action(methods=["get"], detail=True)
    def contributions(self, request, pk: str | None = None):
        goal = self.get_object()
        contributions = goal.contributions.filter(user=request.user)
        serializer = SavingsContributionSerializer(contributions, many=True)
        return Response(serializer.data)

    @contributions.mapping.post
    def add_contribution(self, request, pk: str | None = None):
        goal = self.get_object()
        create_serializer = SavingsContributionCreateSerializer(data=request.data)
        create_serializer.is_valid(raise_exception=True)

        try:
            (
                updated_goal,
                contribution,
                milestones,
                transaction_record,
                user_wallet,
                platform_wallet,
            ) = record_contribution(
                goal=goal,
                user=request.user,
                amount=create_serializer.validated_data["amount"],
                channel=create_serializer.validated_data.get("channel", "Mobile Money"),
                note=create_serializer.validated_data.get("note", ""),
            )
        except DjangoValidationError as exc:
            raise ValidationError(exc.message_dict) from exc

        milestone_payload = [
            {"threshold": milestone.threshold, "achievedAt": milestone.achieved_at, "message": milestone.message}
            for milestone in milestones
        ]

        outcome_serializer = SavingsContributionOutcomeSerializer(
            {
                "goal": updated_goal,
                "contribution": contribution,
                "unlockedMilestones": milestone_payload,
                "transaction": transaction_record,
                "wallet": user_wallet,
                "platformWallet": platform_wallet,
            },
            context=self.get_serializer_context(),
        )
        status_code = status.HTTP_201_CREATED if contribution else status.HTTP_200_OK
        outcome_data = outcome_serializer.data

        group_ids = list(request.user.group_memberships.values_list("group_id", flat=True))
        if group_ids:
            member_name = request.user.full_name or request.user.phone_number
            for group_id in group_ids:
                broadcast_group_event(
                    group_id=group_id,
                    event="savings.contribution.recorded",
                    payload={
                        "groupId": str(group_id),
                        "member": {"id": str(request.user.id), "name": member_name},
                        "outcome": outcome_data,
                    },
                )

        return Response(outcome_data, status=status_code)

    @action(methods=["post"], detail=True, url_path="collect")
    def collect(self, request, pk: str | None = None):
        goal = self.get_object()
        create_serializer = SavingsRedemptionCreateSerializer(data=request.data)
        create_serializer.is_valid(raise_exception=True)

        try:
            updated_goal, redemption, transaction_record, user_wallet, platform_wallet = collect_savings(
                goal=goal,
                user=request.user,
                amount=create_serializer.validated_data["amount"],
                channel=create_serializer.validated_data.get("channel", "Mobile Money"),
                note=create_serializer.validated_data.get("note", ""),
            )
        except DjangoValidationError as exc:
            raise ValidationError(exc.message_dict) from exc

        outcome_serializer = SavingsRedemptionOutcomeSerializer(
            {
                "goal": updated_goal,
                "redemption": redemption,
                "transaction": transaction_record,
                "wallet": user_wallet,
                "platformWallet": platform_wallet,
            },
            context=self.get_serializer_context(),
        )

        outcome_data = outcome_serializer.data

        group_ids = list(request.user.group_memberships.values_list("group_id", flat=True))
        if group_ids:
            member_name = request.user.full_name or request.user.phone_number
            for group_id in group_ids:
                broadcast_group_event(
                    group_id=group_id,
                    event="savings.redemption.recorded",
                    payload={
                        "groupId": str(group_id),
                        "member": {"id": str(request.user.id), "name": member_name},
                        "outcome": outcome_data,
                    },
                )

        return Response(outcome_data, status=status.HTTP_201_CREATED)
