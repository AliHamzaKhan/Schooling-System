"""Application configuration loaded from environment variables."""
import base64
from functools import lru_cache
import json
import os
from typing import Annotated, List, Union
from urllib.parse import quote, urlsplit

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict

# Secrets shipped as defaults for local dev. They must never be used once the
# app runs outside development.
_WEAK_JWT_SECRETS = {"change-this-in-production", "dev-secret-change-in-production"}
_DEFAULT_SUPERADMIN_PASSWORD = "ChangeMe123!"
_DEFAULT_SUPERADMIN_EMAIL = "admin@platform.com"
_DEFAULT_DATABASE_URL = "postgresql+asyncpg://postgres:postgres@localhost:5432/schooling"
_DEV_ENVS = {"development", "dev", "local", "test"}


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Application
    PROJECT_NAME: str = "Schooling System API"
    ENVIRONMENT: str = "development"
    API_V1_PREFIX: str = "/api/v1"

    # Database. Either set DATABASE_URL directly, or supply the DB_* components
    # below (handy for Docker, where DB_HOST is the compose service name) and let
    # `_assemble_db_url` build the URL — it percent-encodes the password, so
    # special characters like '#', '@', ':' are handled for you. When all of
    # DB_HOST / DB_NAME / DB_USER are present the assembled URL wins.
    DATABASE_URL: str = _DEFAULT_DATABASE_URL
    DB_HOST: str = ""
    DB_PORT: int = 5432
    DB_NAME: str = ""
    DB_USER: str = ""
    DB_PASSWORD: str = ""
    # Connection pool sizing. These are PER worker process, so the ceiling of
    # concurrent Postgres connections is roughly
    #   (DB_POOL_SIZE + DB_MAX_OVERFLOW) * workers * replicas.
    # Keep that comfortably under Postgres `max_connections` (or front the DB
    # with PgBouncer) to avoid "too many connections" under load.
    DB_POOL_SIZE: int = 10
    DB_MAX_OVERFLOW: int = 20
    DB_POOL_TIMEOUT: int = 30  # seconds to wait for a free connection

    # Redis. Backs the rate limiter's shared counters (and is the natural home
    # for caching / a background-job broker later). Blank => in-memory rate
    # limiting, which only works with a single worker process.
    REDIS_URL: str = ""

    # Legacy optional broker flag, retained for configuration compatibility.
    # Notifications ALWAYS persist outbox work and require an independent worker;
    # False does not enable inline delivery. The standalone DB worker needs no Redis.
    TASK_QUEUE_ENABLED: bool = False

    # The delivery worker records a database heartbeat at startup and before and
    # after each bounded poll. The Super Admin operations view marks it stale
    # after this interval; keep enough room for a normal 10-second poll plus a
    # short database/provider delay.
    OUTBOX_WORKER_STALE_AFTER_SECONDS: int = Field(default=60, ge=20, le=3600)

    # Development keeps readable local logs. Production uses the content-free
    # JSON formatter so an aggregator can reliably filter level/logger/request.
    LOG_FORMAT: str = "text"

    # JWT
    JWT_SECRET_KEY: str = "change-this-in-production"
    JWT_ALGORITHM: str = "HS256"
    # 5 hours. Long enough that a normal working session never hits a refresh,
    # short enough that a leaked access token — stateless, so not revocable —
    # expires the same day. Overall session length is governed by
    # REFRESH_TOKEN_EXPIRE_DAYS, not this.
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 300
    # 30 days. This — not the access-token lifetime — is what decides how long
    # a user stays signed in. Rotation plus reuse detection means a stolen
    # refresh token is single-use and trips session revocation on replay.
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Seconds a school's serviceability status (active + subscription valid) is
    # cached in Redis to keep the per-request tenant check off Postgres. Bounds
    # how long a just-suspended/expired tenant might still be served (the mutation
    # paths also invalidate explicitly, so this is a fallback ceiling). 0 disables
    # the cache. No effect without REDIS_URL.
    TENANT_STATUS_CACHE_TTL: int = 30

    # --- Password reset (forgot-password OTP flow) --- #
    # How long the emailed OTP stays valid, how many wrong guesses are allowed
    # before it's burned, and how long the post-verification reset token lives.
    PASSWORD_RESET_OTP_TTL_MINUTES: int = 10
    PASSWORD_RESET_MAX_ATTEMPTS: int = 5
    PASSWORD_RESET_TOKEN_TTL_MINUTES: int = 15

    # First super admin (created by the seed script)
    FIRST_SUPERADMIN_EMAIL: str = "admin@platform.com"
    FIRST_SUPERADMIN_PASSWORD: str = "ChangeMe123!"

    # CORS
    BACKEND_CORS_ORIGINS: Annotated[list[str], NoDecode] = ["*"]

    # --- Communication providers (optional; blank => stub/log mode) --- #
    # Twilio (WhatsApp + SMS)
    TWILIO_ACCOUNT_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_WHATSAPP_FROM: str = ""  # e.g. "whatsapp:+14155238886"
    TWILIO_SMS_FROM: str = ""       # e.g. "+14155238886"
    # Firebase Cloud Messaging (push). Legacy server key for simplicity.
    # Legacy FCM server key. Google turned this API down in July 2024 — kept
    # only so existing .env files don't fail validation. Ignored at runtime.
    FCM_SERVER_KEY: str = ""

    # Firebase Cloud Messaging HTTP v1. Point FIREBASE_CREDENTIALS_FILE at the
    # service-account JSON on disk (never commit it), or paste the file's
    # contents into FIREBASE_CREDENTIALS_JSON for container/secret-manager
    # deploys. The project id is read from whichever one is set.
    FIREBASE_CREDENTIALS_FILE: str = ""
    FIREBASE_CREDENTIALS_JSON: str = ""
    # Deployment-safe alternative for a multiline JSON service-account secret.
    # Decoded in memory and never logged or returned by an API.
    FIREBASE_CREDENTIALS_JSON_B64: str = ""
    # Email (SMTP); blank => stub
    EMAIL_FROM: str = ""

    # AI features (Anthropic Claude); blank key => stub mode
    ANTHROPIC_API_KEY: str = ""
    AI_MODEL: str = "claude-opus-4-8"

    # --- Scheduled jobs (driven by an external cron hitting /jobs/*) --- #
    # Shared secret an external scheduler sends in the `X-Cron-Secret` header to
    # authorize job endpoints. Blank => the job endpoints are disabled (403).
    CRON_SECRET: str = ""
    # Days before a school's salary payout day that outstanding-fee reminders go
    # out to guardians.
    FEE_REMINDER_LEAD_DAYS: int = 5

    # --- File storage --- #
    # Pluggable object storage. The app depends only on the StorageBackend
    # interface (app/core/storage.py), so the provider can be swapped without
    # touching call sites. "local" writes to STORAGE_LOCAL_DIR. Only raster
    # avatar/uniform compatibility assets have a public API route; private bytes
    # require record-authorized tickets and must never use a static mount. Set
    # STORAGE_BACKEND to "s3" / "firebase" / "gcs" (and add the matching
    # backend) for production.
    STORAGE_BACKEND: str = "local"
    STORAGE_LOCAL_DIR: str = "uploads"
    # Absolute base URL used to build public file links (e.g.
    # "https://api.example.com"). Blank => links are returned relative ("/media/…").
    PUBLIC_BASE_URL: str = ""
    MAX_UPLOAD_MB: int = 10
    # New uploads are scanned before storage. Disabled is permitted only for
    # local/test development; non-development deployments must configure ClamAV.
    UPLOAD_SCANNER_BACKEND: str = "disabled"
    UPLOAD_SCANNER_HOST: str = ""
    UPLOAD_SCANNER_PORT: int = Field(default=3310, gt=0, le=65535)
    UPLOAD_SCANNER_TIMEOUT_SECONDS: float = Field(default=15, gt=0, le=120)

    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def _split_cors(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",") if origin.strip()]
        return v

    @model_validator(mode="after")
    def _assemble_db_url(self) -> "Settings":
        """Build DATABASE_URL from DB_* components when they are supplied.

        The password is percent-encoded so URL-reserved characters (e.g. '#',
        which would otherwise be read as the start of a URL fragment) survive.
        """
        if self.DB_HOST and self.DB_NAME and self.DB_USER:
            password = quote(self.DB_PASSWORD, safe="")
            self.DATABASE_URL = (
                f"postgresql+asyncpg://{self.DB_USER}:{password}"
                f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
            )
        return self

    @model_validator(mode="after")
    def _require_redis_for_queue(self) -> "Settings":
        """Offload needs a broker — fail fast (in every env) rather than silently
        run inline when someone flips the flag but forgets REDIS_URL."""
        if self.TASK_QUEUE_ENABLED and not self.REDIS_URL:
            raise ValueError("TASK_QUEUE_ENABLED requires REDIS_URL to be set")
        return self

    @model_validator(mode="after")
    def _validate_provider_configuration(self) -> "Settings":
        """Reject partial provider settings before a worker can attempt a send."""
        if self.FIREBASE_CREDENTIALS_JSON_B64:
            if self.FIREBASE_CREDENTIALS_JSON:
                raise ValueError("Configure only one Firebase JSON credential source")
            try:
                self.FIREBASE_CREDENTIALS_JSON = base64.b64decode(
                    self.FIREBASE_CREDENTIALS_JSON_B64, validate=True
                ).decode("utf-8")
            except (UnicodeDecodeError, ValueError) as exc:
                raise ValueError(
                    "FIREBASE_CREDENTIALS_JSON_B64 must be valid base64 UTF-8 JSON"
                ) from exc
        if self.TWILIO_ACCOUNT_SID or self.TWILIO_AUTH_TOKEN:
            if not self.TWILIO_ACCOUNT_SID or not self.TWILIO_AUTH_TOKEN:
                raise ValueError("TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN must be configured together")
            if not self.TWILIO_WHATSAPP_FROM and not self.TWILIO_SMS_FROM:
                raise ValueError("Configure a Twilio sender before enabling Twilio delivery")

        if self.FIREBASE_CREDENTIALS_FILE and self.FIREBASE_CREDENTIALS_JSON:
            raise ValueError("Configure only one Firebase credential source")
        if self.FIREBASE_CREDENTIALS_JSON:
            try:
                credentials = json.loads(self.FIREBASE_CREDENTIALS_JSON)
            except (TypeError, ValueError) as exc:
                raise ValueError("FIREBASE_CREDENTIALS_JSON must contain valid JSON") from exc
            if not isinstance(credentials, dict) or not all(
                isinstance(credentials.get(key), str) and credentials[key]
                for key in ("project_id", "client_email", "private_key")
            ):
                raise ValueError("Firebase credentials must include project_id, client_email and private_key")
        return self

    @model_validator(mode="after")
    def _enforce_production_secrets(self) -> "Settings":
        """Refuse to boot with dev defaults / wildcard CORS outside development.

        This makes an insecure production deploy fail loudly instead of silently
        shipping a forgeable JWT secret, the seeded super-admin password, or a
        credentialed wildcard CORS policy.
        """
        if self.ENVIRONMENT.lower() in _DEV_ENVS:
            return self
        problems: list[str] = []
        if not self.DATABASE_URL or self.DATABASE_URL == _DEFAULT_DATABASE_URL:
            problems.append("DATABASE_URL must be set to a non-development database")
        if self.JWT_SECRET_KEY in _WEAK_JWT_SECRETS or len(self.JWT_SECRET_KEY) < 32:
            problems.append("JWT_SECRET_KEY must be set to a strong (>=32 char) value")
        if self.FIRST_SUPERADMIN_EMAIL.lower() == _DEFAULT_SUPERADMIN_EMAIL:
            problems.append("FIRST_SUPERADMIN_EMAIL must be changed from the default")
        if self.FIRST_SUPERADMIN_PASSWORD == _DEFAULT_SUPERADMIN_PASSWORD:
            problems.append("FIRST_SUPERADMIN_PASSWORD must be changed from the default")
        if not self.BACKEND_CORS_ORIGINS or "*" in self.BACKEND_CORS_ORIGINS:
            problems.append("BACKEND_CORS_ORIGINS must list explicit HTTPS origins, not '*'")
        else:
            for origin in self.BACKEND_CORS_ORIGINS:
                parsed = urlsplit(origin)
                if (
                    parsed.scheme != "https"
                    or not parsed.netloc
                    or parsed.username
                    or parsed.password
                    or parsed.path not in ("", "/")
                    or parsed.query
                    or parsed.fragment
                ):
                    problems.append(
                        "BACKEND_CORS_ORIGINS must contain only HTTPS origins without paths or credentials"
                    )
                    break
        if not self.REDIS_URL:
            # In-memory rate-limit counters live per worker process, so with the
            # multi-worker production server each limit is silently multiplied by
            # the worker/replica count — brute-force protection stops working.
            problems.append(
                "REDIS_URL must be set so rate-limit counters are shared across workers"
            )
        if self.UPLOAD_SCANNER_BACKEND.lower() != "clamav":
            problems.append("UPLOAD_SCANNER_BACKEND must be 'clamav' for new uploads")
        if not self.UPLOAD_SCANNER_HOST:
            problems.append("UPLOAD_SCANNER_HOST must be set for the ClamAV scanner")
        if self.LOG_FORMAT.lower() != "json":
            problems.append("LOG_FORMAT must be 'json' outside development")
        if problems:
            raise ValueError(
                f"Insecure configuration for ENVIRONMENT={self.ENVIRONMENT}: "
                + "; ".join(problems)
            )
        return self


@lru_cache
def get_settings() -> Settings:
    # Isolated tests must not inherit local provider credentials or DB components
    # from .env. Their explicit environment is prepared before importing settings.
    return Settings(_env_file=None) if os.environ.get("ENVIRONMENT") == "test" else Settings()


settings = get_settings()
