from __future__ import annotations

from django.conf import settings
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework import serializers

from .models import Group, GroupInvite, GroupMembership
from ..accounts.services import get_platform_user

UserModel = get_user_model()


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
    ownerId = serializers.UUIDField(source="owner_id", allow_null=True, read_only=True)
    ownerName = serializers.SerializerMethodField()
    ownedByPlatform = serializers.SerializerMethodField()
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
            "ownerId",
            "ownerName",
            "ownedByPlatform",
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

    def get_ownerName(self, obj: Group) -> str:
        if obj.owner:
            return obj.owner.full_name or obj.owner.phone_number
        return getattr(settings, "PLATFORM_ACCOUNT_NAME", "Sankofa Platform")

    def get_ownedByPlatform(self, obj: Group) -> bool:
        if not obj.is_public:
            return False
        owner = getattr(obj, "owner", None)
        if owner is None:
            return True
        platform_phone = getattr(settings, "PLATFORM_ACCOUNT_PHONE_NUMBER", "").strip()
        if platform_phone:
            normalized = UserModel.objects.normalize_phone(platform_phone)
            return owner.phone_number == normalized
        return bool(owner.is_staff)


class GroupMembershipSerializer(serializers.ModelSerializer):
    class Meta:
        model = GroupMembership
        fields = ("id", "group", "user", "display_name", "joined_at")
        read_only_fields = ("id", "joined_at")


class GroupInviteCreateSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=255)
    phoneNumber = serializers.CharField(max_length=32)

    def validate_name(self, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise serializers.ValidationError("Invite name is required.")
        return normalized

    def validate_phoneNumber(self, value: str) -> str:
        normalized = UserModel.objects.normalize_phone(value)
        return normalized


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

    def validate_invites(self, value: list[dict]) -> list[dict]:
        if not value:
            raise serializers.ValidationError("Invite at least one member.")

        normalized: list[dict] = []
        seen_numbers: set[str] = set()

        for invite in value:
            phone = invite["phoneNumber"]
            if phone in seen_numbers:
                raise serializers.ValidationError("Each invite must use a unique phone number.")
            seen_numbers.add(phone)
            normalized.append(invite)

        return normalized

    def create(self, validated_data: dict) -> Group:
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if user is None or user.is_anonymous:
            raise serializers.ValidationError("Authenticated user required to create a group.")

        invites_data = validated_data.pop("invites", [])

        for invite in invites_data:
            if invite["phoneNumber"] == user.phone_number:
                raise serializers.ValidationError(
                    {"invites": "You cannot invite yourself to the group."}
                )

        is_public = validated_data.get("isPublic", False)
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

        owner = user if not is_public else get_platform_user()

        group = Group.objects.create(
            name=validated_data["name"],
            description=validated_data.get("description", ""),
            frequency=frequency or "",
            location=validated_data.get("location", ""),
            requires_approval=validated_data.get("requiresApproval", True),
            is_public=is_public,
            target_member_count=target_member_count,
            contribution_amount=validated_data["contributionAmount"],
            cycle_number=1,
            total_cycles=target_member_count,
            next_payout_date=start_date,
            payout_order=payout_order,
            owner=owner,
        )

        GroupMembership.objects.create(
            group=group,
            user=user,
            display_name=user.full_name or user.phone_number,
            joined_at=timezone.now(),
        )

        for invite_data in invites_data:
            GroupInvite.objects.create(
                group=group,
                name=invite_data["name"],
                phone_number=invite_data["phoneNumber"],
            )

        return group
