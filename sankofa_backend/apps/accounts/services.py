from __future__ import annotations

import logging
import random
import io
import uuid
from datetime import timedelta

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.files.base import ContentFile
from django.core.mail import send_mail
from django.db import transaction
from django.utils import timezone
from PIL import Image

from .models import PhoneOTP

logger = logging.getLogger(__name__)

UserModel = get_user_model()


def get_platform_user() -> UserModel | None:
    """Return or provision the platform user used for system-owned records."""

    platform_phone = getattr(settings, "PLATFORM_ACCOUNT_PHONE_NUMBER", "").strip()
    platform_name = getattr(settings, "PLATFORM_ACCOUNT_NAME", "Sankofa Platform")
    platform_email = getattr(settings, "PLATFORM_ACCOUNT_EMAIL", "").strip()

    if platform_phone:
        normalized = UserModel.objects.normalize_phone(platform_phone)
        user, _created = UserModel.objects.get_or_create(
            phone_number=normalized,
            defaults={
                "full_name": platform_name,
                "is_staff": True,
            },
        )

        update_fields: list[str] = []

        if not user.full_name and platform_name:
            user.full_name = platform_name
            update_fields.append("full_name")

        if not user.is_staff:
            user.is_staff = True
            update_fields.append("is_staff")

        if platform_email and user.email != platform_email:
            user.email = platform_email
            update_fields.append("email")

        if update_fields:
            user.save(update_fields=update_fields)

        return user

    return (
        UserModel.objects.filter(is_staff=True, is_superuser=True).order_by("date_joined").first()
        or UserModel.objects.filter(is_staff=True).order_by("date_joined").first()
    )


def generate_otp_code(length: int = 6) -> str:
    upper_bound = 10**length - 1
    return f"{random.SystemRandom().randint(0, upper_bound):0{length}d}"


PURPOSE_SUBJECTS = {
    PhoneOTP.PURPOSE_SIGNUP: "Complete your Sankofa registration",
    PhoneOTP.PURPOSE_LOGIN: "Your Sankofa login code",
    PhoneOTP.PURPOSE_PASSWORD_RESET: "Reset your Sankofa password",
}


def issue_phone_otp(
    *,
    phone_number: str,
    purpose: str,
    code: str | None = None,
    email: str | None = None,
    full_name: str | None = None,
) -> PhoneOTP:
    ttl_minutes = int(getattr(settings, "AUTH_OTP_TTL_MINUTES", 5))
    test_code = None
    test_config = getattr(settings, "AUTH_TEST_PHONE_OTPS", None)

    if code is not None:
        generated_code = code
    else:
        if isinstance(test_config, dict):
            purpose_config = test_config.get(purpose) or {}
            if isinstance(purpose_config, dict):
                test_code = purpose_config.get(phone_number)

        generated_code = test_code or generate_otp_code()
    otp = PhoneOTP.create_for_phone(
        phone_number=phone_number,
        purpose=purpose,
        code=generated_code,
        ttl=timedelta(minutes=ttl_minutes),
    )

    logger.info("Issued OTP", extra={"phone_number": phone_number, "purpose": purpose})

    if settings.DEBUG:
        logger.debug("OTP code for %s (%s): %s", phone_number, purpose, generated_code)

    if email:
        subject = PURPOSE_SUBJECTS.get(purpose, "Your Sankofa verification code")
        recipient_name = full_name or phone_number
        message = (
            f"Hi {recipient_name},\n\n"
            f"Use the verification code {generated_code} to continue with your Sankofa {purpose.replace('_', ' ')}.\n"
            f"This code expires in {ttl_minutes} minute{'s' if ttl_minutes != 1 else ''}.\n\n"
            "If you did not request this code, please contact support."
        )

        try:
            send_mail(
                subject,
                message,
                getattr(settings, "DEFAULT_FROM_EMAIL", "no-reply@sankofa.test"),
                [email],
            )
        except Exception:  # pragma: no cover - log for visibility while preserving OTP issuance
            logger.exception(
                "Failed to deliver OTP email",
                extra={
                    "phone_number": phone_number,
                    "purpose": purpose,
                    "email": email,
                },
            )

    return otp


def validate_otp(*, phone_number: str, purpose: str, code: str) -> PhoneOTP:
    max_attempts = int(getattr(settings, "AUTH_OTP_MAX_ATTEMPTS", 5))
    otp = (
        PhoneOTP.objects.filter(
            phone_number=phone_number,
            purpose=purpose,
            verified_at__isnull=True,
        )
        .order_by("-created_at")
        .first()
    )

    if otp is None:
        raise ValueError("otp_missing")

    if otp.is_expired:
        otp.mark_attempt(success=False)
        raise ValueError("otp_expired")

    if otp.attempt_count >= max_attempts:
        raise ValueError("otp_attempts")

    if otp.code != code:
        otp.mark_attempt(success=False)
        raise ValueError("otp_invalid")

    otp.mark_attempt(success=True)
    return otp


def _optimise_image(upload) -> ContentFile:
    upload.seek(0)
    image = Image.open(upload)
    if image.mode not in ("RGB", "L"):
        image = image.convert("RGB")

    max_dimension = int(getattr(settings, "IDENTIFICATION_MAX_DIMENSION", 2400))
    image.thumbnail((max_dimension, max_dimension), Image.LANCZOS)

    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=85, optimize=True)
    buffer.seek(0)
    return ContentFile(buffer.read())


def _build_filename(user: UserModel, side: str) -> str:
    return f"{user.id}/{side}-{uuid.uuid4().hex}.jpg"


@transaction.atomic
def submit_ghana_card_documents(*, user: UserModel, front_image, back_image) -> UserModel:
    """Persist optimised Ghana Card scans for the authenticated user."""

    if user.ghana_card_front:
        user.ghana_card_front.delete(save=False)
    if user.ghana_card_back:
        user.ghana_card_back.delete(save=False)

    optimised_front = _optimise_image(front_image)
    optimised_back = _optimise_image(back_image)

    user.ghana_card_front.save(_build_filename(user, "front"), optimised_front, save=False)
    user.ghana_card_back.save(_build_filename(user, "back"), optimised_back, save=False)

    user.kyc_status = getattr(settings, "IDENTIFICATION_SUBMITTED_STATUS", "submitted")
    user.kyc_submitted_at = timezone.now()
    user.save(update_fields=["ghana_card_front", "ghana_card_back", "kyc_status", "kyc_submitted_at", "updated_at"])

    return user


