from django.apps import AppConfig


class AdminApiConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "sankofa_backend.apps.admin_api"
    verbose_name = "Admin API"
