from __future__ import annotations

from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import SavingsGoal
from .serializers import (
    SavingsContributionCreateSerializer,
    SavingsContributionOutcomeSerializer,
    SavingsContributionSerializer,
    SavingsGoalSerializer,
)
from .services import record_contribution


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

        updated_goal, contribution, milestones = record_contribution(
            goal=goal,
            user=request.user,
            amount=create_serializer.validated_data["amount"],
            channel=create_serializer.validated_data.get("channel", "Mobile Money"),
            note=create_serializer.validated_data.get("note", ""),
        )

        milestone_payload = [
            {"threshold": milestone.threshold, "achievedAt": milestone.achieved_at, "message": milestone.message}
            for milestone in milestones
        ]

        outcome_serializer = SavingsContributionOutcomeSerializer(
            {
                "goal": updated_goal,
                "contribution": contribution,
                "unlockedMilestones": milestone_payload,
            },
            context=self.get_serializer_context(),
        )
        status_code = status.HTTP_201_CREATED if contribution else status.HTTP_200_OK
        return Response(outcome_serializer.data, status=status_code)
