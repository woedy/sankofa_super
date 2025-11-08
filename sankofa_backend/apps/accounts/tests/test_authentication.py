from __future__ import annotations

import io
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core import mail
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from django.urls import reverse
from rest_framework.test import APIClient

from PIL import Image

from sankofa_backend.apps.accounts.models import PhoneOTP
from sankofa_backend.apps.transactions.models import Wallet


User = get_user_model()


class AuthenticationFlowTests(TestCase):
    def setUp(self) -> None:
        self.client = APIClient()

    def _request(self, path: str, data: dict):
        return self.client.post(path, data, format="json")

    def _create_image(self, colour: str) -> SimpleUploadedFile:
        image = Image.new("RGB", (1200, 800), colour)
        buffer = io.BytesIO()
        image.save(buffer, format="PNG")
        buffer.seek(0)
        return SimpleUploadedFile(f"{colour}.png", buffer.read(), content_type="image/png")

    def test_registration_creates_user_and_dispatches_signup_otp(self):
        response = self._request(
            reverse("accounts:register"),
            {"phone_number": "0241234567", "full_name": "Akosua Mensah", "email": "akosua@example.com"},
        )

        self.assertEqual(response.status_code, 201)
        payload = response.json()
        self.assertEqual(payload["user"]["phone_number"], "+233241234567")

        user = User.objects.get(phone_number="+233241234567")
        otp = PhoneOTP.objects.filter(phone_number=user.phone_number, purpose=PhoneOTP.PURPOSE_SIGNUP).first()
        self.assertIsNotNone(otp)

        wallet = Wallet.objects.filter(user=user).first()
        self.assertIsNotNone(wallet)
        self.assertEqual(wallet.balance, Decimal("0.00"))

    @override_settings(EMAIL_BACKEND="django.core.mail.backends.locmem.EmailBackend")
    def test_registration_sends_signup_email(self):
        self._request(
            reverse("accounts:register"),
            {"phone_number": "0241234567", "full_name": "Akosua Mensah", "email": "akosua@example.com"},
        )

        self.assertEqual(len(mail.outbox), 1)
        message = mail.outbox[0]
        self.assertIn("Sankofa", message.subject)
        self.assertIn("Akosua", message.body)
        self.assertIn("verification code", message.body.lower())

    def test_login_otp_flow_returns_tokens(self):
        user = User.objects.create_user(phone_number="0241234567", full_name="Kwame")

        request_response = self._request(
            reverse("accounts:otp-request"),
            {"phone_number": "+233241234567", "purpose": PhoneOTP.PURPOSE_LOGIN},
        )
        self.assertEqual(request_response.status_code, 200)

        otp = PhoneOTP.objects.filter(phone_number=user.phone_number, purpose=PhoneOTP.PURPOSE_LOGIN).first()
        verify_response = self._request(
            reverse("accounts:otp-verify"),
            {
                "phone_number": user.phone_number,
                "purpose": PhoneOTP.PURPOSE_LOGIN,
                "code": otp.code,
            },
        )

        self.assertEqual(verify_response.status_code, 200)
        body = verify_response.json()
        self.assertIn("access", body)
        self.assertIn("refresh", body)
        self.assertEqual(body["user"]["id"], str(user.id))
        self.assertIn("wallet_balance", body["user"])

    def test_password_reset_flow_updates_password(self):
        user = User.objects.create_user(phone_number="0241234567", full_name="Kwame", password="old-password")

        reset_request = self._request(
            reverse("accounts:password-reset-request"),
            {"phone_number": user.phone_number},
        )
        self.assertEqual(reset_request.status_code, 200)

        otp = PhoneOTP.objects.filter(phone_number=user.phone_number, purpose=PhoneOTP.PURPOSE_PASSWORD_RESET).first()

        confirm_response = self._request(
            reverse("accounts:otp-verify"),
            {
                "phone_number": user.phone_number,
                "purpose": PhoneOTP.PURPOSE_PASSWORD_RESET,
                "code": otp.code,
                "new_password": "new-strong-password",
            },
        )

        self.assertEqual(confirm_response.status_code, 200)
        user.refresh_from_db()
        self.assertTrue(user.check_password("new-strong-password"))

    def test_invalid_otp_returns_error(self):
        user = User.objects.create_user(phone_number="0241234567", full_name="Kwame")
        self._request(
            reverse("accounts:otp-request"),
            {"phone_number": user.phone_number, "purpose": PhoneOTP.PURPOSE_LOGIN},
        )

        response = self._request(
            reverse("accounts:otp-verify"),
            {
                "phone_number": user.phone_number,
                "purpose": PhoneOTP.PURPOSE_LOGIN,
                "code": "000000",
            },
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn("detail", response.json())

    def test_authenticated_user_can_upload_ghana_card_images(self):
        user = User.objects.create_user(phone_number="0241234567", full_name="Kwame")
        self.client.force_authenticate(user=user)

        response = self.client.post(
            reverse("accounts:ghana-card-upload"),
            {
                "front_image": self._create_image("#ff0000"),
                "back_image": self._create_image("#0000ff"),
            },
            format="multipart",
        )

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["user"]["kyc_status"], "submitted")
        self.assertIsNotNone(payload["user"]["kyc_submitted_at"])

        user.refresh_from_db()
        self.assertEqual(user.kyc_status, "submitted")
        self.assertIsNotNone(user.kyc_submitted_at)
        self.assertTrue(user.ghana_card_front.name.endswith(".jpg"))
        self.assertTrue(user.ghana_card_back.name.endswith(".jpg"))

    @override_settings(EMAIL_BACKEND="django.core.mail.backends.locmem.EmailBackend")
    def test_login_request_sends_email_when_available(self):
        user = User.objects.create_user(
            phone_number="0241234567",
            full_name="Kwame Mensah",
            email="kwame@example.com",
        )

        self._request(
            reverse("accounts:otp-request"),
            {"phone_number": user.phone_number, "purpose": PhoneOTP.PURPOSE_LOGIN},
        )

        self.assertEqual(len(mail.outbox), 1)
        message = mail.outbox[0]
        self.assertIn("login", message.subject.lower())
        self.assertIn("Kwame", message.body)

    @override_settings(
        AUTH_TEST_PHONE_OTPS={
            PhoneOTP.PURPOSE_LOGIN: {
                "+233241234567": "112233",
            }
        }
    )
    def test_login_otp_uses_configured_test_code(self):
        user = User.objects.create_user(
            phone_number="0241234567",
            full_name="Test User",
            email="test-user@example.com",
        )

        request_response = self._request(
            reverse("accounts:otp-request"),
            {"phone_number": user.phone_number, "purpose": PhoneOTP.PURPOSE_LOGIN},
        )

        self.assertEqual(request_response.status_code, 200)

        otp = PhoneOTP.objects.filter(
            phone_number=user.phone_number,
            purpose=PhoneOTP.PURPOSE_LOGIN,
        ).first()

        self.assertIsNotNone(otp)
        self.assertEqual(otp.code, "112233")

        verify_response = self._request(
            reverse("accounts:otp-verify"),
            {
                "phone_number": user.phone_number,
                "purpose": PhoneOTP.PURPOSE_LOGIN,
                "code": "112233",
            },
        )

        self.assertEqual(verify_response.status_code, 200)
