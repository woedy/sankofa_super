from __future__ import annotations

from django.conf import settings
from django.db import migrations, models


def assign_group_owners(apps, schema_editor):
    User = apps.get_model("accounts", "User")
    Group = apps.get_model("groups", "Group")
    GroupMembership = apps.get_model("groups", "GroupMembership")

    platform_phone = getattr(settings, "PLATFORM_ACCOUNT_PHONE_NUMBER", "").strip()
    platform_user = None

    if platform_phone:
        normalized = User.objects.normalize_phone(platform_phone)
        defaults = {
            "full_name": getattr(settings, "PLATFORM_ACCOUNT_NAME", "Sankofa Platform"),
            "is_staff": True,
        }
        platform_user, _created = User.objects.get_or_create(
            phone_number=normalized,
            defaults=defaults,
        )
        if not platform_user.is_staff:
            platform_user.is_staff = True
            platform_user.save(update_fields=["is_staff"])
    else:
        platform_user = (
            User.objects.filter(is_staff=True, is_superuser=True).order_by("date_joined").first()
            or User.objects.filter(is_staff=True).order_by("date_joined").first()
        )

    for group in Group.objects.all():
        owner = None
        if group.is_public:
            owner = platform_user
        else:
            membership = (
                GroupMembership.objects.filter(group=group)
                .select_related("user")
                .order_by("joined_at")
                .first()
            )
            if membership:
                owner = membership.user

        if owner and group.owner_id != owner.id:
            group.owner_id = owner.id
            group.save(update_fields=["owner"])


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0002_user_identification_fields"),
        ("groups", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="group",
            name="owner",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=models.SET_NULL,
                related_name="owned_groups",
                to=settings.AUTH_USER_MODEL,
            ),
        ),
        migrations.RunPython(assign_group_owners, migrations.RunPython.noop),
    ]
