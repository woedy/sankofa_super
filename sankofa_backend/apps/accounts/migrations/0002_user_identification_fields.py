# Generated manually because the container lacks Django dependencies during scaffolding.
from __future__ import annotations

from django.db import migrations, models

import sankofa_backend.apps.common.storage


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="ghana_card_back",
            field=models.ImageField(
                blank=True,
                help_text="Optimized scan of the back of the Ghana Card.",
                null=True,
                storage=sankofa_backend.apps.common.storage.get_identification_storage(),
                upload_to="",
            ),
        ),
        migrations.AddField(
            model_name="user",
            name="ghana_card_front",
            field=models.ImageField(
                blank=True,
                help_text="Optimized scan of the front of the Ghana Card.",
                null=True,
                storage=sankofa_backend.apps.common.storage.get_identification_storage(),
                upload_to="",
            ),
        ),
        migrations.AddField(
            model_name="user",
            name="kyc_submitted_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
