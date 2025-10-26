from __future__ import annotations

import logging
import random
from datetime import timedelta

from django.conf import settings
from django.core.mail import send_mail

from .models import PhoneOTP

logger = logging.getLogger(__name__)


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
    generated_code = code or generate_otp_code()
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


