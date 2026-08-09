"""Django settings for the Shohojpath research backend.

Everything environment-specific is read from the environment with a
development-safe default, so the same code runs on a laptop and on a free host
without a second settings file to keep in step.
"""

from datetime import timedelta
from pathlib import Path

import environ

BASE_DIR = Path(__file__).resolve().parent.parent

env = environ.Env(
    DEBUG=(bool, False),
    ALLOWED_HOSTS=(list, ["*"]),
    CORS_ALLOW_ALL=(bool, True),
)
environ.Env.read_env(BASE_DIR / ".env")

# Dev default only. On any real host SECRET_KEY must come from the
# environment — an app signing tokens with a published key is not secured.
SECRET_KEY = env(
    "SECRET_KEY",
    default="dev-only-insecure-key-change-me-before-deploying",
)
DEBUG = env("DEBUG")
ALLOWED_HOSTS = env("ALLOWED_HOSTS")

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "corsheaders",
    "accounts",
    "readers",
    "passages",
    "sync",
    "content",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    # Directly after security: it serves the admin's own CSS on hosts with no
    # separate static file server, which is every free tier.
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

# SQLite locally, Postgres wherever DATABASE_URL is set — which is how every
# free host hands you a database.
DATABASES = {
    "default": env.db_url(
        "DATABASE_URL",
        default=f"sqlite:///{BASE_DIR / 'db.sqlite3'}",
    )
}
DATABASES["default"]["CONN_MAX_AGE"] = env.int("CONN_MAX_AGE", default=60)

# SQLite is the production database on PythonAnywhere's free tier, whose
# filesystem is persistent (unlike the ephemeral disks on Render and friends)
# but network-backed, so a lock is held for longer than on a local disk. The
# default five-second timeout is enough to turn two readers syncing at once
# into "database is locked"; twenty is not noticeable to anyone and removes
# the failure. WAL is deliberately NOT enabled — it needs shared memory that
# network filesystems do not provide.
if DATABASES["default"]["ENGINE"].endswith("sqlite3"):
    DATABASES["default"].setdefault("OPTIONS", {})
    DATABASES["default"]["OPTIONS"]["timeout"] = env.int("SQLITE_TIMEOUT", default=20)

AUTH_USER_MODEL = "accounts.User"

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
        "OPTIONS": {"min_length": 8},
    },
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = env("TIME_ZONE", default="Asia/Dhaka")
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STORAGES = {
    "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
    "staticfiles": {
        "BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage"
    },
}

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.IsAuthenticated",),
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 50,
    # A generic sign-in error stops someone *reading* which emails exist; it
    # does not stop them trying. These caps are what makes guessing at scale
    # impractical. Generous enough that a participant fumbling their password
    # on a study device is never locked out mid-session.
    "DEFAULT_THROTTLE_CLASSES": ["rest_framework.throttling.ScopedRateThrottle"],
    "DEFAULT_THROTTLE_RATES": {
        "login": env("LOGIN_THROTTLE", default="20/min"),
        "signup": env("SIGNUP_THROTTLE", default="10/min"),
    },
}

SIMPLE_JWT = {
    # Long-lived on purpose: a participant mid-session must never be bounced to
    # the login screen, and the device is handed back to the researcher after.
    "ACCESS_TOKEN_LIFETIME": timedelta(days=env.int("ACCESS_TOKEN_DAYS", default=7)),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=env.int("REFRESH_TOKEN_DAYS", default=90)),
    "ROTATE_REFRESH_TOKENS": True,
    "UPDATE_LAST_LOGIN": True,
}

# The Flutter app is not a browser origin, so CORS is only for the admin and
# any web tooling. Left open in development, restricted by env in production.
CORS_ALLOW_ALL_ORIGINS = env("CORS_ALLOW_ALL")
CORS_ALLOWED_ORIGINS = env.list("CORS_ALLOWED_ORIGINS", default=[])
CSRF_TRUSTED_ORIGINS = env.list("CSRF_TRUSTED_ORIGINS", default=[])

if not DEBUG:
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True

    # Children's reading data and the admin password travel over this, so a
    # real host must set SECURE_SSL_REDIRECT=True in its .env — deploy/env.example
    # does, and `manage.py check --deploy` fails the deploy script if it is
    # missing.
    #
    # Not defaulted to True: the test runner also runs with DEBUG=False, and a
    # blanket redirect turns every test request into a 301 before it reaches a
    # view. Defaulting it on silently broke 73 tests. The check is the guard
    # here, not the default.
    SECURE_SSL_REDIRECT = env.bool("SECURE_SSL_REDIRECT", default=False)

# security.W021 asks for SECURE_HSTS_PRELOAD. Preloading is a submission to a
# list browsers ship, and it applies to the whole domain — on a shared host
# like username.pythonanywhere.com that domain belongs to someone else, so
# asking for it would be both ineffective and presumptuous. HSTS itself is on.
SILENCED_SYSTEM_CHECKS = ["security.W021"]
