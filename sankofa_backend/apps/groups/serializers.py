from __future__ import annotations

from django.utils import timezone
from rest_framework import serializers

from .models import Group, GroupInvite, GroupMembership


class GroupInviteSerializer(serializers.ModelSerializer):
    id = serializers.UUIDField(read_only=True)
    phoneNumber = serializers.CharField(source="phone_number")
    kycCompleted = serializers.BooleanField(source="kyc_completed")
    sentAt = serializers.DateTimeField(source="sent_at")
    respondedAt = serializers.DateTimeField(source="responded_at", allow_null=True)
    lastRemindedAt = serializers.DateTimeField(source="last_reminded_at", allow_null=True)
    reminderCount = serializers.IntegerField(source="reminder_count")

    class Meta:
        model = GroupInvite
        fields = (
            "id",
            "name",
            "phoneNumber",
            "status",
            "kycCompleted",
            "sentAt",
            "respondedAt",
            "lastRemindedAt",
            "reminderCount",
        )
        read_only_fields = fields


class GroupSerializer(serializers.ModelSerializer):
    memberIds = serializers.SerializerMethodField()
    memberNames = serializers.SerializerMethodField()
    invites = GroupInviteSerializer(many=True, read_only=True)
    targetMemberCount = serializers.IntegerField(source="target_member_count")
    contributionAmount = serializers.DecimalField(
        source="contribution_amount", max_digits=12, decimal_places=2, coerce_to_string=False
    )
    cycleNumber = serializers.IntegerField(source="cycle_number")
    totalCycles = serializers.IntegerField(source="total_cycles")
    nextPayoutDate = serializers.DateTimeField(source="next_payout_date")
    payoutOrder = serializers.CharField(source="payout_order")
    isPublic = serializers.BooleanField(source="is_public")
    requiresApproval = serializers.BooleanField(source="requires_approval")
    createdAt = serializers.DateTimeField(source="created_at")
    updatedAt = serializers.DateTimeField(source="updated_at")

    class Meta:
        model = Group
        fields = (
            "id",
            "name",
            "memberIds",
            "memberNames",
            "invites",
            "targetMemberCount",
            "contributionAmount",
            "cycleNumber",
            "totalCycles",
            "nextPayoutDate",
            "payoutOrder",
            "isPublic",
            "description",
            "frequency",
            "location",
            "requiresApproval",
            "createdAt",
            "updatedAt",
        )
        read_only_fields = fields

    def get_memberIds(self, obj: Group) -> list[str]:
        memberships = getattr(obj, "_prefetched_members", None) or list(obj.memberships.select_related("user"))
        return [str(m.user_id) for m in memberships]

    def get_memberNames(self, obj: Group) -> list[str]:
        memberships = getattr(obj, "_prefetched_members", None) or list(obj.memberships.select_related("user"))
        names: list[str] = []
        for membership in memberships:
            if membership.display_name:
                names.append(membership.display_name)
            else:
                names.append(membership.user.full_name or membership.user.phone_number)
        return names


class GroupMembershipSerializer(serializers.ModelSerializer):
    class Meta:
        model = GroupMembership
        fields = ("id", "group", "user", "display_name", "joined_at")
        read_only_fields = ("id", "joined_at")


class GroupInviteCreateSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=255)
    phoneNumber = serializers.CharField(max_length=32, allow_blank=True, required=False)


class GroupCreateSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=255)
    description = serializers.CharField(required=False, allow_blank=True)
    contributionAmount = serializers.DecimalField(max_digits=12, decimal_places=2)
    frequency = serializers.CharField(required=False, allow_blank=True)
    location = serializers.CharField(required=False, allow_blank=True)
    requiresApproval = serializers.BooleanField(default=True)
    isPublic = serializers.BooleanField(default=False)
    targetMemberCount = serializers.IntegerField(min_value=1, required=False)
    startDate = serializers.DateTimeField()
    payoutOrder = serializers.CharField(required=False, allow_blank=True)
    invites = GroupInviteCreateSerializer(many=True)

    def create(self, validated_data: dict) -> Group:
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if user is None or user.is_anonymous:
            raise serializers.ValidationError("Authenticated user required to create a group.")

        invites_data = validated_data.pop("invites", [])

        target_member_count = validated_data.get("targetMemberCount")
        if target_member_count is None:
            target_member_count = len(invites_data) + 1
        else:
            minimum_members = len(invites_data) + 1
            if target_member_count < minimum_members:
                raise serializers.ValidationError(
                    {"targetMemberCount": "Must be at least the admin plus all invitees."}
                )

        start_date = validated_data.pop("startDate")
        payout_order = validated_data.get("payoutOrder")
        frequency = validated_data.get("frequency")

        if not payout_order:
            payout_order = "Rotating"
            if frequency:
                payout_order = f"Rotating ({frequency})"

        group = Group.objects.create(
            name=validated_data["name"],
            description=validated_data.get("description", ""),
            frequency=frequency or "",
            location=validated_data.get("location", ""),
            requires_approval=validated_data.get("requiresApproval", True),
            is_public=validated_data.get("isPublic", False),
            target_member_count=target_member_count,
            contribution_amount=validated_data["contributionAmount"],
            cycle_number=1,
            total_cycles=target_member_count,
            next_payout_date=start_date,
            payout_order=payout_order,
        )

        GroupMembership.objects.create(
            group=group,
            user=user,
            display_name=user.full_name or user.phone_number,
            joined_at=timezone.now(),
        )

        now = timezone.now()
        for index, invite_data in enumerate(invites_data):
            phone_number = invite_data.get("phoneNumber") or _generate_placeholder_phone(now, index)
            GroupInvite.objects.create(
                group=group,
                name=invite_data["name"],
                phone_number=phone_number,
            )

        return group


def _generate_placeholder_phone(seed_time, offset: int) -> str:
    millis = int(seed_time.timestamp() * 1000) + offset
    normalized = str(abs(millis) % 1_000_000).zfill(6)
    prefix = "20"
    middle = normalized[:3]
    suffix = normalized[3:]
    return f"+233{prefix}{middle}{suffix}"
