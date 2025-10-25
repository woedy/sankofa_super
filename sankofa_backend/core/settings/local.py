"""Local development settings."""
from .base import *  # noqa: F401,F403
from .base import DATABASES  # noqa: F401

DEBUG = True
ALLOWED_HOSTS = ["*"]

DATABASES["default"].setdefault("HOST", "localhost")
DATABASES["default"].setdefault("PORT", 5432)
