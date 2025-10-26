from __future__ import annotations

from pathlib import Path
from typing import Optional

from django.conf import settings
from django.core.exceptions import ImproperlyConfigured
from django.core.files.storage import FileSystemStorage, Storage

_identification_storage: Optional[Storage] = None


def get_identification_storage() -> Storage:
    """Return the storage backend for identification documents."""
    global _identification_storage

    if _identification_storage is not None:
        return _identification_storage

    backend = getattr(settings, "IDENTIFICATION_STORAGE_BACKEND", "local").lower()

    if backend in {"s3", "minio"}:
        try:
            from storages.backends.s3boto3 import S3Boto3Storage  # type: ignore
        except ImportError as exc:  # pragma: no cover - configuration error path
            raise ImproperlyConfigured(
                "IDENTIFICATION_STORAGE_BACKEND is set to use S3-compatible storage, "
                "but django-storages is not installed."
            ) from exc

        options = getattr(settings, "IDENTIFICATION_STORAGE_OPTIONS", {})
        _identification_storage = S3Boto3Storage(**options)
        return _identification_storage

    media_root = Path(settings.MEDIA_ROOT)
    base_path = media_root / "identification_cards"
    base_path.mkdir(parents=True, exist_ok=True)

    media_url = settings.MEDIA_URL.rstrip("/")
    base_url = f"{media_url}/identification_cards/"

    _identification_storage = FileSystemStorage(location=base_path, base_url=base_url)
    return _identification_storage
