from __future__ import annotations

from django.contrib.auth import get_user_model
from django.db import transaction
from django.db.models import Prefetch
from django.utils import timezone
from django.shortcuts import get_object_or_404
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Group, GroupInvite, GroupInviteReminder, GroupMembership
from .realtime import broadcast_group_event
from .serializers import GroupCreateSerializer, GroupSerializer

User = get_user_model()


class GroupViewSet(viewsets.ModelViewSet):
    serializer_class = GroupSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        if self.action == "create":
            return GroupCreateSerializer
        return super().get_serializer_class()

    def _prefetched_queryset(self):
        memberships_prefetch = Prefetch(
            "memberships",
            queryset=GroupMembership.objects.select_related("user"),
            to_attr="_prefetched_members",
        )
        return Group.objects.select_related("owner").prefetch_related(memberships_prefetch, "invites")

    def get_queryset(self):
        return self._prefetched_queryset().for_user(self.request.user).order_by("name")

    def _get_group(self, group_id):
        return self._prefetched_queryset().get(pk=group_id)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        group = serializer.save()
        response_serializer = GroupSerializer(group, context=self.get_serializer_context())
        headers = self.get_success_headers(response_serializer.data)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    @action(methods=["post"], detail=True)
    def join(self, request, pk: str | None = None):
        group = self.get_object()

        if not group.is_public:
            return Response({"detail": "This group is invite-only."}, status=status.HTTP_400_BAD_REQUEST)

        if group.seats_remaining <= 0:
            return Response({"detail": "This group is already at capacity."}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            membership = (
                GroupMembership.objects.select_for_update()
                .filter(group=group, user=request.user)
                .first()
            )
            created = False

            if membership is None:
                if group.requires_approval:
                    display_name = request.user.full_name or request.user.phone_number
                    normalized_phone = User.objects.normalize_phone(request.user.phone_number)
                    kyc_status = (request.user.kyc_status or "").lower()
                    kyc_completed = kyc_status in {
                        "verified",
                        "approved",
                        "completed",
                        "submitted",
                        "under_review",
                        "in_review",
                        "review_pending",
                    }

                    invite_qs = group.invites.select_for_update().filter(phone_number=normalized_phone)
                    invite = invite_qs.first()
                    if invite:
                        invite.name = display_name
                        invite.status = GroupInvite.STATUS_PENDING
                        invite.kyc_completed = kyc_completed
                        invite.responded_at = None
                        invite.last_reminded_at = None
                        invite.reminder_count = 0
                        invite.sent_at = timezone.now()
                        invite.save(
                            update_fields=[
                                "name",
                                "status",
                                "kyc_completed",
                                "responded_at",
                                "last_reminded_at",
                                "reminder_count",
                                "sent_at",
                            ]
                        )
                    else:
                        group.invites.create(
                            name=display_name,
                            phone_number=normalized_phone,
                            status=GroupInvite.STATUS_PENDING,
                            kyc_completed=kyc_completed,
                        )
                else:
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

        if created:
            broadcast_group_event(
                group_id=group.pk,
                event="group.membership.joined",
                payload={
                    "group": serializer.data,
                    "member": {
                        "id": str(request.user.id),
                        "name": membership.display_name,
                    },
                },
            )

        if group.requires_approval and not created and membership is None:
            return Response(serializer.data, status=status.HTTP_202_ACCEPTED)

        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(methods=["post"], detail=True)
    def leave(self, request, pk: str | None = None):
        group = self.get_object()
        departing_name = request.user.full_name or request.user.phone_number
        deleted, _ = group.memberships.filter(user=request.user).delete()
        if deleted:
            group.updated_at = timezone.now()
            group.save(update_fields=["updated_at"])
        refreshed = self._get_group(group.pk)
        serializer = self.get_serializer(refreshed)

        if deleted:
            broadcast_group_event(
                group_id=group.pk,
                event="group.membership.left",
                payload={
                    "group": serializer.data,
                    "member": {
                        "id": str(request.user.id),
                        "name": departing_name,
                    },
                },
            )

        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(methods=["post"], detail=True, url_path=r"invites/(?P<invite_id>[^/]+)/remind")
    def remind_invite(self, request, pk: str | None = None, invite_id: str | None = None):
        group = self.get_object()
        invite = get_object_or_404(group.invites, pk=invite_id)

        GroupInviteReminder.objects.create(invite=invite)
        invite.last_reminded_at = timezone.now()
        invite.reminder_count += 1
        invite.save(update_fields=["last_reminded_at", "reminder_count"])
        refreshed = self._get_group(group.pk)
        data = GroupSerializer(refreshed, context=self.get_serializer_context()).data
        return Response(data, status=status.HTTP_200_OK)

    @action(methods=["post"], detail=True, url_path=r"invites/(?P<invite_id>[^/]+)/status")
    def update_invite_status(self, request, pk: str | None = None, invite_id: str | None = None):
        group = self.get_object()
        invite = get_object_or_404(group.invites, pk=invite_id)

        status_value = request.data.get("status")
        kyc_completed = request.data.get("kycCompleted")
        if status_value is None:
            return Response({"status": "This field is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            invite.mark_status(status=status_value, kyc_completed=kyc_completed)
        except ValueError:
            return Response({"status": "Invalid status."}, status=status.HTTP_400_BAD_REQUEST)

        refreshed = self._get_group(group.pk)
        data = GroupSerializer(refreshed, context=self.get_serializer_context()).data
        return Response(data, status=status.HTTP_200_OK)

    @action(methods=["post"], detail=True, url_path=r"invites/(?P<invite_id>[^/]+)/promote")
    def promote_invite(self, request, pk: str | None = None, invite_id: str | None = None):
        group = self.get_object()
        invite = get_object_or_404(group.invites, pk=invite_id)

        with transaction.atomic():
            user_model = get_user_model()
            normalized_phone = user_model.objects.normalize_phone(invite.phone_number)
            member_user, _ = user_model.objects.get_or_create(
                phone_number=normalized_phone,
                defaults={"full_name": invite.name},
            )

            if invite.name and not member_user.full_name:
                member_user.full_name = invite.name
                member_user.save(update_fields=["full_name"])

            membership, created = GroupMembership.objects.get_or_create(
                group=group,
                user=member_user,
                defaults={"display_name": invite.name or member_user.full_name},
            )
            invite.mark_status(status=GroupInvite.STATUS_ACCEPTED, kyc_completed=True)

            if created:
                group.updated_at = timezone.now()
                group.save(update_fields=["updated_at"])

        refreshed = self._get_group(group.pk)
        data = GroupSerializer(refreshed, context=self.get_serializer_context()).data

        broadcast_group_event(
            group_id=group.pk,
            event="group.membership.invite_promoted",
            payload={
                "group": data,
                "member": {
                    "id": str(membership.user_id),
                    "name": membership.display_name,
                },
            },
        )

        return Response(data, status=status.HTTP_200_OK)
