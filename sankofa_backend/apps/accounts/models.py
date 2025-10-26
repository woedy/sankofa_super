from __future__ import annotations

import uuid
from datetime import timedelta

from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.contrib.auth.models import PermissionsMixin
from django.core.validators import RegexValidator
from django.db import models
from django.utils import timezone

from ..common.storage import get_identification_storage


def get_default_kyc_status() -> str:
    from django.conf import settings  # local import to avoid settings at import time

    return getattr(settings, "DEFAULT_KYC_STATUS", "pending")


class UserManager(BaseUserManager):
    """Custom manager that uses phone numbers as the primary identifier."""

    def create_user(
        self,
        phone_number: str,
        password: str | None = None,
        **extra_fields: object,
    ) -> "User":
        if not phone_number:
            raise ValueError("Users must have a phone number")

        normalized_phone = self.normalize_phone(phone_number)
        user = self.model(phone_number=normalized_phone, **extra_fields)

        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()

        user.save(using=self._db)
        return user

    def create_superuser(
        self,
        phone_number: str,
        password: str,
        **extra_fields: object,
    ) -> "User":
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("is_active", True)

        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")

        return self.create_user(phone_number, password, **extra_fields)

    def normalize_phone(self, phone_number: str) -> str:
        digits_only = "".join(ch for ch in phone_number if ch.isdigit())
        if phone_number.startswith("+233") and len(digits_only) == 12:
            return phone_number
        if digits_only.startswith("233") and len(digits_only) == 12:
            return f"+{digits_only}"
        if digits_only.startswith("0") and len(digits_only) == 10:
            return f"+233{digits_only[1:]}"
        if len(digits_only) == 9:
            return f"+233{digits_only}"
        if phone_number.startswith("+"):
            return phone_number
        return f"+{digits_only}"


identification_storage = get_identification_storage()


class User(AbstractBaseUser, PermissionsMixin):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone_number = models.CharField(
        max_length=16,
        unique=True,
        validators=[
            RegexValidator(
                regex=r"^\+233\d{9}$",
                message="Enter a valid Ghana phone number starting with +233.",
            )
        ],
    )
    full_name = models.CharField(max_length=255)
    email = models.EmailField(blank=True, null=True, unique=True)
    kyc_status = models.CharField(
        max_length=32,
        default=get_default_kyc_status,
        help_text="Current Know Your Customer verification status.",
    )
    ghana_card_front = models.ImageField(
        storage=identification_storage,
        upload_to="",
        blank=True,
        null=True,
        help_text="Optimized scan of the front of the Ghana Card.",
    )
    ghana_card_back = models.ImageField(
        storage=identification_storage,
        upload_to="",
        blank=True,
        null=True,
        help_text="Optimized scan of the back of the Ghana Card.",
    )
    kyc_submitted_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = "phone_number"
    REQUIRED_FIELDS: list[str] = []

    objects = UserManager()

    class Meta:
        verbose_name = "User"
        verbose_name_plural = "Users"

    def __str__(self) -> str:
        return self.full_name or self.phone_number


class PhoneOTP(models.Model):
    PURPOSE_LOGIN = "login"
    PURPOSE_SIGNUP = "signup"
    PURPOSE_PASSWORD_RESET = "password_reset"

    PURPOSE_CHOICES = (
        (PURPOSE_LOGIN, "Login"),
        (PURPOSE_SIGNUP, "Signup"),
        (PURPOSE_PASSWORD_RESET, "Password reset"),
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone_number = models.CharField(max_length=16)
    code = models.CharField(max_length=6)
    purpose = models.CharField(max_length=32, choices=PURPOSE_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    attempt_count = models.PositiveIntegerField(default=0)
    verified_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        indexes = [
            models.Index(fields=["phone_number", "purpose", "created_at"]),
        ]
        ordering = ["-created_at"]

    def mark_attempt(self, *, success: bool) -> None:
        self.attempt_count = models.F("attempt_count") + 1
        update_fields = ["attempt_count"]
        if success:
            self.verified_at = timezone.now()
            update_fields.append("verified_at")
        self.save(update_fields=update_fields)
        self.refresh_from_db(fields=["attempt_count", "verified_at"])

    @property
    def is_expired(self) -> bool:
        return timezone.now() >= self.expires_at

    @classmethod
    def create_for_phone(
        cls,
        *,
        phone_number: str,
        purpose: str,
        code: str,
        ttl: timedelta | None = None,
    ) -> "PhoneOTP":
        lifetime = ttl or timedelta(minutes=5)
        return cls.objects.create(
            phone_number=phone_number,
            purpose=purpose,
            code=code,
            expires_at=timezone.now() + lifetime,
        )

    def __str__(self) -> str:  # pragma: no cover - debug helper
        return f"OTP {self.code} for {self.phone_number} ({self.purpose})"
