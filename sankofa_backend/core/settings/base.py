"""Base settings shared across environments."""
from __future__ import annotations

import os
from datetime import timedelta
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent.parent.parent

SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "insecure-secret-key")
DEBUG = False


def _csv_env(name: str) -> list[str]:
    return [value.strip() for value in os.environ.get(name, "").split(",") if value.strip()]


def _env_bool(name: str, default: bool = False) -> bool:
    value = os.environ.get(name)
    if value is None:
        return default
    return value.lower() in {"1", "true", "yes", "on"}


ALLOWED_HOSTS = _csv_env("DJANGO_ALLOWED_HOSTS")

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "corsheaders",
    "channels",
    "rest_framework",
    "rest_framework_simplejwt",
    "sankofa_backend.apps.accounts",
    "sankofa_backend.apps.groups",
    "sankofa_backend.apps.savings",
    "sankofa_backend.apps.transactions",
    "sankofa_backend.apps.common",
    "sankofa_backend.apps.disputes",
    "sankofa_backend.apps.admin_api",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "core.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    }
]

WSGI_APPLICATION = "core.wsgi.application"
ASGI_APPLICATION = "core.asgi.application"

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("POSTGRES_DB", "sankofa"),
        "USER": os.environ.get("POSTGRES_USER", "sankofa"),
        "PASSWORD": os.environ.get("POSTGRES_PASSWORD", "sankofa"),
        "HOST": os.environ.get("POSTGRES_HOST", "localhost"),
        "PORT": int(os.environ.get("POSTGRES_PORT", 5432)),
    }
}

if os.environ.get("DJANGO_DB_ENGINE", "").lower() == "sqlite":
    DATABASES["default"] = {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": os.environ.get("SQLITE_DB_PATH", BASE_DIR / "db.sqlite3"),
    }

REDIS_HOST = os.environ.get("REDIS_HOST", "localhost")
REDIS_PORT = int(os.environ.get("REDIS_PORT", 6379))
REDIS_PASSWORD = os.environ.get("REDIS_PASSWORD") or None

CHANNEL_LAYER_BACKEND = os.environ.get("DJANGO_CHANNEL_LAYER", "redis").lower()

if CHANNEL_LAYER_BACKEND == "memory":
    CHANNEL_LAYERS = {
        "default": {
            "BACKEND": "channels.layers.InMemoryChannelLayer",
        }
    }
else:
    CHANNEL_LAYERS = {
        "default": {
            "BACKEND": "channels_redis.core.RedisChannelLayer",
            "CONFIG": {
                "hosts": [
                    {
                        "host": REDIS_HOST,
                        "port": REDIS_PORT,
                        **({"password": REDIS_PASSWORD} if REDIS_PASSWORD else {}),
                    }
                ]
            },
        }
    }

_redis_credentials = f":{REDIS_PASSWORD}@" if REDIS_PASSWORD else ""
_default_redis_url = f"redis://{_redis_credentials}{REDIS_HOST}:{REDIS_PORT}/0"

CELERY_BROKER_URL = os.environ.get("CELERY_BROKER_URL", _default_redis_url)
CELERY_RESULT_BACKEND = os.environ.get("CELERY_RESULT_BACKEND", CELERY_BROKER_URL)
CELERY_TASK_SERIALIZER = "json"
CELERY_RESULT_SERIALIZER = "json"
CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TIMEZONE = os.environ.get("DJANGO_TIME_ZONE", "UTC")

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = os.environ.get("DJANGO_TIME_ZONE", "UTC")
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
MEDIA_URL = "media/"
MEDIA_ROOT = BASE_DIR / "media"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

AUTH_USER_MODEL = "accounts.User"

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
}

CORS_ALLOWED_ORIGINS = _csv_env("DJANGO_CORS_ALLOWED_ORIGINS")
CSRF_TRUSTED_ORIGINS = _csv_env("DJANGO_CSRF_TRUSTED_ORIGINS")

if CORS_ALLOWED_ORIGINS:
    CORS_ALLOW_ALL_ORIGINS = False
else:
    CORS_ALLOW_ALL_ORIGINS = DEBUG
    CORS_ALLOWED_ORIGIN_REGEXES = [
        r"^https?://localhost(:\d+)?$",
        r"^https?://127\.0\.0\.1(:\d+)?$",
        r"^https?://0\.0\.0\.0(:\d+)?$",
    ]

CORS_ALLOW_CREDENTIALS = True

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=int(os.environ.get("AUTH_ACCESS_TOKEN_MINUTES", 30))),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=int(os.environ.get("AUTH_REFRESH_TOKEN_DAYS", 7))),
    "ROTATE_REFRESH_TOKENS": False,
    "BLACKLIST_AFTER_ROTATION": False,
}

AUTH_TEST_PHONE_OTPS = {
    "login": {
        "+233241234567": "112233",
    }
}

DEFAULT_KYC_STATUS = os.environ.get("DEFAULT_KYC_STATUS", "pending")

IDENTIFICATION_STORAGE_BACKEND = os.environ.get("IDENTIFICATION_STORAGE_BACKEND", "local")
IDENTIFICATION_STORAGE_OPTIONS = {
    key: value
    for key, value in {
        "bucket_name": os.environ.get("IDENTIFICATION_STORAGE_BUCKET"),
        "access_key": os.environ.get("IDENTIFICATION_STORAGE_ACCESS_KEY"),
        "secret_key": os.environ.get("IDENTIFICATION_STORAGE_SECRET_KEY"),
        "endpoint_url": os.environ.get("IDENTIFICATION_STORAGE_ENDPOINT"),
        "region_name": os.environ.get("IDENTIFICATION_STORAGE_REGION"),
        "default_acl": os.environ.get("IDENTIFICATION_STORAGE_DEFAULT_ACL"),
        "custom_domain": os.environ.get("IDENTIFICATION_STORAGE_CUSTOM_DOMAIN"),
    }.items()
    if value
}
IDENTIFICATION_MAX_IMAGE_MB = int(os.environ.get("IDENTIFICATION_MAX_IMAGE_MB", 5))

EMAIL_BACKEND = os.environ.get(
    "DJANGO_EMAIL_BACKEND",
    "django.core.mail.backends.filebased.EmailBackend",
)
DEFAULT_FROM_EMAIL = os.environ.get("DJANGO_DEFAULT_FROM_EMAIL", "no-reply@sankofa.test")
EMAIL_HOST = os.environ.get("EMAIL_HOST", "localhost")
EMAIL_PORT = int(os.environ.get("EMAIL_PORT", 25))
EMAIL_HOST_USER = os.environ.get("EMAIL_HOST_USER", "")
EMAIL_HOST_PASSWORD = os.environ.get("EMAIL_HOST_PASSWORD", "")
EMAIL_USE_TLS = _env_bool("EMAIL_USE_TLS", False)
EMAIL_USE_SSL = _env_bool("EMAIL_USE_SSL", False)
EMAIL_TIMEOUT = int(os.environ.get("EMAIL_TIMEOUT", 30))
SERVER_EMAIL = os.environ.get("DJANGO_SERVER_EMAIL", DEFAULT_FROM_EMAIL)
_email_file_path = Path(
    os.environ.get("DJANGO_EMAIL_FILE_PATH", BASE_DIR / "sent_emails")
)
if EMAIL_BACKEND.endswith("filebased.EmailBackend"):
    _email_file_path.mkdir(parents=True, exist_ok=True)
    EMAIL_FILE_PATH = str(_email_file_path)
