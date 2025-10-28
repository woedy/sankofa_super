from django.apps import AppConfig


class AccountsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "sankofa_backend.apps.accounts"
    verbose_name = "Accounts"

    def ready(self) -> None:  # pragma: no cover - import side effects
        from . import signals  # noqa: F401
