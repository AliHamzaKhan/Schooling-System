"""Application configuration loaded from environment variables."""
from functools import lru_cache
from typing import Annotated, List, Union
from urllib.parse import quote

from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict

# Secrets shipped as defaults for local dev. They must never be used once the
# app runs outside development.
_WEAK_JWT_SECRETS = {"change-this-in-production", "dev-secret-change-in-production"}
_DEFAULT_SUPERADMIN_PASSWORD = "ChangeMe123!"
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
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/schooling"
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
    # Email (SMTP); blank => stub
    EMAIL_FROM: str = ""

    # AI features (Anthropic Claude); blank key => stub mode
    ANTHROPIC_API_KEY: str = ""
    AI_MODEL: str = "claude-opus-4-8"

    # --- File storage --- #
    # Pluggable object storage. The app depends only on the StorageBackend
    # interface (app/core/storage.py), so the provider can be swapped without
    # touching call sites. "local" writes to STORAGE_LOCAL_DIR and serves files
    # via the /media mount (development only). Set STORAGE_BACKEND to "s3" /
    # "firebase" / "gcs" (and add the matching backend) for production.
    STORAGE_BACKEND: str = "local"
    STORAGE_LOCAL_DIR: str = "uploads"
    # Absolute base URL used to build public file links (e.g.
    # "https://api.example.com"). Blank => links are returned relative ("/media/…").
    PUBLIC_BASE_URL: str = ""
    MAX_UPLOAD_MB: int = 10

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
    def _enforce_production_secrets(self) -> "Settings":
        """Refuse to boot with dev defaults / wildcard CORS outside development.

        This makes an insecure production deploy fail loudly instead of silently
        shipping a forgeable JWT secret, the seeded super-admin password, or a
        credentialed wildcard CORS policy.
        """
        if self.ENVIRONMENT.lower() in _DEV_ENVS:
            return self
        problems: list[str] = []
        if self.JWT_SECRET_KEY in _WEAK_JWT_SECRETS or len(self.JWT_SECRET_KEY) < 32:
            problems.append("JWT_SECRET_KEY must be set to a strong (>=32 char) value")
        if self.FIRST_SUPERADMIN_PASSWORD == _DEFAULT_SUPERADMIN_PASSWORD:
            problems.append("FIRST_SUPERADMIN_PASSWORD must be changed from the default")
        if "*" in self.BACKEND_CORS_ORIGINS:
            problems.append("BACKEND_CORS_ORIGINS must list explicit origins, not '*'")
        if not self.REDIS_URL:
            # In-memory rate-limit counters live per worker process, so with the
            # multi-worker production server each limit is silently multiplied by
            # the worker/replica count — brute-force protection stops working.
            problems.append(
                "REDIS_URL must be set so rate-limit counters are shared across workers"
            )
        if problems:
            raise ValueError(
                f"Insecure configuration for ENVIRONMENT={self.ENVIRONMENT}: "
                + "; ".join(problems)
            )
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
