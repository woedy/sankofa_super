from django.urls import path

from .views import (
    CurrentUserView,
    GhanaCardUploadView,
    OTPRequestView,
    OTPVerifyView,
    PasswordResetRequestView,
    RegistrationView,
)


app_name = "accounts"


urlpatterns = [
    path("register/", RegistrationView.as_view(), name="register"),
    path("otp/request/", OTPRequestView.as_view(), name="otp-request"),
    path("otp/verify/", OTPVerifyView.as_view(), name="otp-verify"),
    path("password/reset/request/", PasswordResetRequestView.as_view(), name="password-reset-request"),
    path("me/", CurrentUserView.as_view(), name="current-user"),
    path("ghana-card/", GhanaCardUploadView.as_view(), name="ghana-card-upload"),
]
