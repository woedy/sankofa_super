from __future__ import annotations

import uuid
from typing import Any

from django.conf import settings
from django.db import models


class AuditLog(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="admin_audit_logs",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    action = models.CharField(max_length=255)
    target_type = models.CharField(max_length=255)
    target_id = models.CharField(max_length=64, blank=True)
    changes = models.JSONField(default=dict, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["target_type", "target_id"])]

    def __str__(self) -> str:  # pragma: no cover - admin helper
        actor = getattr(self.actor, "full_name", None) or getattr(self.actor, "phone_number", "Unknown")
        return f"{self.action} by {actor}"

    def record_change(self, *, changes: dict[str, Any] | None = None, metadata: dict[str, Any] | None = None) -> None:
        if changes:
            self.changes = {**(self.changes or {}), **changes}
        if metadata:
            self.metadata = {**(self.metadata or {}), **metadata}
        self.save(update_fields=["changes", "metadata"])
