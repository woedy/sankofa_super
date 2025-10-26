from __future__ import annotations

from django.contrib.auth import get_user_model
from rest_framework import parsers, permissions, response, status, views
from rest_framework.exceptions import ValidationError
from rest_framework_simplejwt.tokens import RefreshToken

from .models import PhoneOTP
from .serializers import (
    GhanaCardUploadSerializer,
    OTPRequestSerializer,
    OTPVerifySerializer,
    PasswordResetRequestSerializer,
    RegistrationSerializer,
    UserSerializer,
)
from .services import issue_phone_otp, submit_ghana_card_documents, validate_otp


User = get_user_model()


def _serialize_user(user: User, *, request=None) -> dict:
    context = {}
    if request is not None:
        context["request"] = request
    return UserSerializer(user, context=context).data


def _issue_tokens_for_user(user: User, *, request=None) -> dict:
    refresh = RefreshToken.for_user(user)
    return {
        "refresh": str(refresh),
        "access": str(refresh.access_token),
        "user": _serialize_user(user, request=request),
    }


class RegistrationView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = RegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        issue_phone_otp(
            phone_number=user.phone_number,
            purpose=PhoneOTP.PURPOSE_SIGNUP,
            email=user.email,
            full_name=user.full_name,
        )

        return response.Response(
            {
                "message": "Registration successful. Verify the OTP sent to your phone to continue.",
                "user": _serialize_user(user, request=request),
            },
            status=status.HTTP_201_CREATED,
        )


class OTPRequestView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = OTPRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        phone_number = serializer.validated_data["phone_number"]
        purpose = serializer.validated_data["purpose"]

        user = None
        if purpose != PhoneOTP.PURPOSE_SIGNUP:
            user = User.objects.filter(phone_number=phone_number).first()

        otp = issue_phone_otp(
            phone_number=phone_number,
            purpose=purpose,
            email=getattr(user, "email", None),
            full_name=getattr(user, "full_name", None),
        )

        payload = {
            "message": "A verification code has been sent to your phone.",
            "expiresAt": otp.expires_at.isoformat(),
        }

        return response.Response(payload, status=status.HTTP_200_OK)


class OTPVerifyView(views.APIView):
    permission_classes = [permissions.AllowAny]

    ERROR_MAP = {
        "otp_invalid": "otp_invalid",
        "otp_expired": "otp_expired",
        "otp_attempts": "otp_attempts",
        "otp_missing": "otp_invalid",
    }

    def post(self, request, *args, **kwargs):
        serializer = OTPVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        phone_number = serializer.validated_data["phone_number"]
        purpose = serializer.validated_data["purpose"]
        code = serializer.validated_data["code"]

        try:
            validate_otp(phone_number=phone_number, purpose=purpose, code=code)
        except ValueError as exc:
            error_key = self.ERROR_MAP.get(str(exc), "otp_invalid")
            raise ValidationError({"detail": serializer.error_messages[error_key]}) from exc

        user = User.objects.filter(phone_number=phone_number).first()

        if purpose == PhoneOTP.PURPOSE_PASSWORD_RESET:
            user.set_password(serializer.validated_data["new_password"])
            user.save(update_fields=["password", "updated_at"])
            return response.Response(
                {"message": "Password has been updated successfully."},
                status=status.HTTP_200_OK,
            )

        if user is None:
            raise ValidationError({"detail": "Account setup is incomplete. Please register first."})

        tokens = _issue_tokens_for_user(user, request=request)
        return response.Response(tokens, status=status.HTTP_200_OK)


class PasswordResetRequestView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        phone_number = serializer.validated_data["phone_number"]
        user = User.objects.filter(phone_number=phone_number).first()

        otp = issue_phone_otp(
            phone_number=phone_number,
            purpose=PhoneOTP.PURPOSE_PASSWORD_RESET,
            email=getattr(user, "email", None),
            full_name=getattr(user, "full_name", None),
        )

        return response.Response(
            {
                "message": "A password reset code has been sent to your phone.",
                "expiresAt": otp.expires_at.isoformat(),
            },
            status=status.HTTP_200_OK,
        )


class CurrentUserView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, *args, **kwargs):
        return response.Response(UserSerializer(request.user, context={"request": request}).data)


class GhanaCardUploadView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = (parsers.MultiPartParser, parsers.FormParser)

    def post(self, request, *args, **kwargs):
        serializer = GhanaCardUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        updated_user = submit_ghana_card_documents(
            user=request.user,
            front_image=serializer.validated_data["front_image"],
            back_image=serializer.validated_data["back_image"],
        )

        payload = {
            "message": "Your Ghana Card has been submitted for review.",
            "user": _serialize_user(updated_user, request=request),
        }
        return response.Response(payload, status=status.HTTP_200_OK)
