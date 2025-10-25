"""Celery application configuration."""
from __future__ import annotations

import os

from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings.production")

app = Celery("core")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()


@app.task(bind=True)
def debug_task(self):
    """A no-op task useful for smoke testing the Celery worker."""
    return f"Task executed from {self.request.hostname}"  # pragma: no cover
