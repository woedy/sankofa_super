from django.apps import AppConfig


class TransactionsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "sankofa_backend.apps.transactions"
    verbose_name = "Transactions"
