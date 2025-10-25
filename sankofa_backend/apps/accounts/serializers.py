from __future__ import annotations

from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
from rest_framework import serializers

from .models import PhoneOTP


UserModel = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserModel
        fields = (
            "id",
            "phone_number",
            "full_name",
            "email",
            "kyc_status",
            "date_joined",
            "updated_at",
        )
        read_only_fields = fields


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
