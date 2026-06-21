"""Application configuration loaded from environment variables."""
from functools import lru_cache
from typing import Annotated

from pydantic import field_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict


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


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
