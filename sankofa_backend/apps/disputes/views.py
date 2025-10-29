from __future__ import annotations

from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Dispute, SupportArticle
from .serializers import (
    DisputeCreateSerializer,
    DisputeMessageCreateSerializer,
    DisputeSerializer,
    DisputeUpdateSerializer,
    SupportArticleSerializer,
)


class DisputeViewSet(
    viewsets.GenericViewSet,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    mixins.CreateModelMixin,
    mixins.UpdateModelMixin,
):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = DisputeSerializer

    def get_queryset(self):
        user = self.request.user
        queryset = (
            Dispute.objects.all()
            .select_related("user", "group", "assigned_to", "related_article")
            .prefetch_related("messages", "attachments")
            .order_by("-opened_at")
        )
        if not user.is_staff:
            queryset = queryset.filter(user=user)
        return queryset

    def get_serializer_class(self):
        if self.action == "create":
            return DisputeCreateSerializer
        if self.action in {"partial_update", "update"}:
            return DisputeUpdateSerializer
        return super().get_serializer_class()

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context.setdefault("request", self.request)
        return context

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        dispute = serializer.instance

        output_serializer = DisputeSerializer(
            dispute,
            context=self.get_serializer_context(),
        )
        headers = self.get_success_headers(output_serializer.data)
        return Response(output_serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def perform_create(self, serializer):
        serializer.save()

    def perform_update(self, serializer):
        serializer.save()

    @action(detail=True, methods=["post"], url_path="messages")
    def add_message(self, request, *args, **kwargs):
        dispute = self.get_object()
        serializer = DisputeMessageCreateSerializer(
            data=request.data,
            context={"dispute": dispute, "author": request.user},
        )
        serializer.is_valid(raise_exception=True)
        message = serializer.save()
        output = self.get_serializer(dispute, context=self.get_serializer_context()).data
        return Response(output, status=status.HTTP_200_OK)


class SupportArticleViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = SupportArticleSerializer
    queryset = SupportArticle.objects.all().order_by("title")
