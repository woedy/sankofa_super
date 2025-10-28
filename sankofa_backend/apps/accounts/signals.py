from __future__ import annotations

from django.contrib.auth import get_user_model
from django.db.models.signals import post_save
from django.dispatch import receiver


User = get_user_model()


@receiver(post_save, sender=User)
def ensure_wallet_for_user(sender, instance: User, created: bool, **_: object) -> None:
    if not created:
        return

    try:
        instance.get_wallet()
    except Exception:
        # Avoid breaking user creation if storage is temporarily unavailable.
        # The wallet will be lazily provisioned when next accessed.
        pass
