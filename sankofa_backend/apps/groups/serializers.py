from __future__ import annotations

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
