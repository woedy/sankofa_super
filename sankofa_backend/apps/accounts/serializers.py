from __future__ import annotations

from django.conf import settings
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
from rest_framework import serializers

from .models import PhoneOTP


UserModel = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    ghana_card_front_url = serializers.SerializerMethodField()
    ghana_card_back_url = serializers.SerializerMethodField()
    wallet_balance = serializers.DecimalField(
        max_digits=14,
        decimal_places=2,
        coerce_to_string=False,
        read_only=True,
    )
    wallet_updated_at = serializers.DateTimeField(allow_null=True, read_only=True)

    class Meta:
        model = UserModel
        fields = (
            "id",
            "phone_number",
            "full_name",
            "email",
            "kyc_status",
            "kyc_submitted_at",
            "ghana_card_front_url",
            "ghana_card_back_url",
            "wallet_balance",
            "wallet_updated_at",
            "date_joined",
            "updated_at",
        )
        read_only_fields = fields

    def get_ghana_card_front_url(self, obj: UserModel) -> str | None:
        if not obj.ghana_card_front:
            return None
        return self._build_absolute(obj.ghana_card_front.url)

    def get_ghana_card_back_url(self, obj: UserModel) -> str | None:
        if not obj.ghana_card_back:
            return None
        return self._build_absolute(obj.ghana_card_back.url)

    def _build_absolute(self, url: str) -> str:
        request = self.context.get("request") if isinstance(self.context, dict) else None
        if request is not None:
            return request.build_absolute_uri(url)
        return url


class RegistrationSerializer(serializers.ModelSerializer):
    phone_number = serializers.CharField()

    class Meta:
        model = UserModel
        fields = ("phone_number", "full_name", "email")
        extra_kwargs = {
            "phone_number": {"validators": []},
        }

    def validate_phone_number(self, value: str) -> str:
        normalized = UserModel.objects.normalize_phone(value)
        if UserModel.objects.filter(phone_number=normalized).exists():
            raise serializers.ValidationError("A user with this phone number already exists.")
        return normalized

    def create(self, validated_data: dict):
        return UserModel.objects.create_user(**validated_data)


class OTPRequestSerializer(serializers.Serializer):
    phone_number = serializers.CharField()
    purpose = serializers.ChoiceField(choices=PhoneOTP.PURPOSE_CHOICES)

    default_error_messages = {
        "user_missing": _("No account is registered with this phone number."),
    }

    def validate(self, attrs: dict) -> dict:
        normalized = UserModel.objects.normalize_phone(attrs["phone_number"])
        attrs["phone_number"] = normalized
        purpose = attrs["purpose"]

        if purpose in {PhoneOTP.PURPOSE_LOGIN, PhoneOTP.PURPOSE_PASSWORD_RESET}:
            if not UserModel.objects.filter(phone_number=normalized, is_active=True).exists():
                self.fail("user_missing")

        return attrs


class OTPVerifySerializer(serializers.Serializer):
    phone_number = serializers.CharField()
    code = serializers.CharField(max_length=6, min_length=4)
    purpose = serializers.ChoiceField(choices=PhoneOTP.PURPOSE_CHOICES)
    new_password = serializers.CharField(write_only=True, required=False, min_length=8)

    default_error_messages = {
        "otp_invalid": _("The code you entered is incorrect."),
        "otp_expired": _("The verification code has expired. Request a new one."),
        "otp_attempts": _("Too many invalid attempts. Request a new code."),
        "user_missing": _("No account is registered with this phone number."),
        "password_required": _("A new password must be provided for password resets."),
    }

    def validate(self, attrs: dict) -> dict:
        normalized = UserModel.objects.normalize_phone(attrs["phone_number"])
        attrs["phone_number"] = normalized

        purpose = attrs["purpose"]
        if purpose in {PhoneOTP.PURPOSE_LOGIN, PhoneOTP.PURPOSE_PASSWORD_RESET}:
            if not UserModel.objects.filter(phone_number=normalized, is_active=True).exists():
                self.fail("user_missing")

        if purpose == PhoneOTP.PURPOSE_PASSWORD_RESET and "new_password" not in attrs:
            self.fail("password_required")

        return attrs


class PasswordResetRequestSerializer(serializers.Serializer):
    phone_number = serializers.CharField()

    def validate_phone_number(self, value: str) -> str:
        normalized = UserModel.objects.normalize_phone(value)
        if not UserModel.objects.filter(phone_number=normalized, is_active=True).exists():
            raise serializers.ValidationError("No account is registered with this phone number.")
        return normalized


class GhanaCardUploadSerializer(serializers.Serializer):
    front_image = serializers.ImageField()
    back_image = serializers.ImageField()

    default_error_messages = {
        "image_size": _("Images must be %(size)sMB or smaller."),
    }

    def validate_front_image(self, value):
        return self._validate_image(value)

    def validate_back_image(self, value):
        return self._validate_image(value)

    def _validate_image(self, value):
        max_bytes = settings.IDENTIFICATION_MAX_IMAGE_MB * 1024 * 1024
        if value.size > max_bytes:
            self.fail("image_size", size=settings.IDENTIFICATION_MAX_IMAGE_MB)
        return value
