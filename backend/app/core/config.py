"""Application configuration loaded from environment variables."""
from functools import lru_cache
from typing import Annotated

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

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/schooling"

    # JWT
    JWT_SECRET_KEY: str = "change-this-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

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
    FCM_SERVER_KEY: str = ""
    # Email (SMTP); blank => stub
    EMAIL_FROM: str = ""

    # AI features (Anthropic Claude); blank key => stub mode
    ANTHROPIC_API_KEY: str = ""
    AI_MODEL: str = "claude-opus-4-8"

    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def _split_cors(cls, v: str | list[str]) -> list[str]:
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",") if origin.strip()]
        return v

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
