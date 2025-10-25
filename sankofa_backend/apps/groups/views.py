from __future__ import annotations

from django.db import transaction
from django.db.models import Prefetch
from django.utils import timezone
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Group, GroupMembership
from .serializers import GroupSerializer


class GroupViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = GroupSerializer
    permission_classes = [permissions.IsAuthenticated]

    def _prefetched_queryset(self):
        memberships_prefetch = Prefetch(
            "memberships",
            queryset=GroupMembership.objects.select_related("user"),
            to_attr="_prefetched_members",
        )
        return Group.objects.prefetch_related(memberships_prefetch, "invites")

    def get_queryset(self):
        return self._prefetched_queryset().for_user(self.request.user).order_by("name")

    def _get_group(self, group_id):
        return self._prefetched_queryset().get(pk=group_id)

    @action(methods=["post"], detail=True)
    def join(self, request, pk: str | None = None):
        group = self.get_object()

        if not group.is_public:
            return Response({"detail": "This group is invite-only."}, status=status.HTTP_400_BAD_REQUEST)

        if group.seats_remaining <= 0:
            return Response({"detail": "This group is already at capacity."}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            membership, created = GroupMembership.objects.select_for_update().get_or_create(
                group=group,
                user=request.user,
                defaults={"display_name": request.user.full_name or request.user.phone_number},
            )
            if created:
                group.updated_at = timezone.now()
                group.save(update_fields=["updated_at"])

        refreshed = self._get_group(group.pk)
        serializer = self.get_serializer(refreshed)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(methods=["post"], detail=True)
    def leave(self, request, pk: str | None = None):
        group = self.get_object()
        deleted, _ = group.memberships.filter(user=request.user).delete()
        if deleted:
            group.updated_at = timezone.now()
            group.save(update_fields=["updated_at"])
        refreshed = self._get_group(group.pk)
        serializer = self.get_serializer(refreshed)
        return Response(serializer.data, status=status.HTTP_200_OK)
