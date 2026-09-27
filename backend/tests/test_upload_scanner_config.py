import pytest
from pydantic import ValidationError

from app.core.config import Settings


def test_production_configuration_requires_a_clamav_upload_scanner():
    with pytest.raises(ValidationError, match="UPLOAD_SCANNER_BACKEND"):
        Settings(
            _env_file=None,
            ENVIRONMENT="production",
            DATABASE_URL="postgresql+asyncpg://app:password@db.example.test/schooling",
            JWT_SECRET_KEY="a" * 32,
            FIRST_SUPERADMIN_EMAIL="admin@school.example.test",
            FIRST_SUPERADMIN_PASSWORD="safe-admin-password",
            BACKEND_CORS_ORIGINS=["https://school.example.test"],
            REDIS_URL="redis://redis.example.test/0",
            UPLOAD_SCANNER_BACKEND="disabled",
        )


def test_production_configuration_accepts_configured_clamav_scanner():
    settings = Settings(
        _env_file=None,
        ENVIRONMENT="production",
        DATABASE_URL="postgresql+asyncpg://app:password@db.example.test/schooling",
        JWT_SECRET_KEY="a" * 32,
        FIRST_SUPERADMIN_EMAIL="admin@school.example.test",
        FIRST_SUPERADMIN_PASSWORD="safe-admin-password",
        BACKEND_CORS_ORIGINS=["https://school.example.test"],
        REDIS_URL="redis://redis.example.test/0",
        UPLOAD_SCANNER_BACKEND="clamav",
        UPLOAD_SCANNER_HOST="clamav",
        LOG_FORMAT="json",
    )
    assert settings.UPLOAD_SCANNER_PORT == 3310


def test_production_configuration_requires_json_logs():
    with pytest.raises(ValidationError, match="LOG_FORMAT"):
        Settings(
            _env_file=None,
            ENVIRONMENT="production",
            DATABASE_URL="postgresql+asyncpg://app:password@db.example.test/schooling",
            JWT_SECRET_KEY="a" * 32,
            FIRST_SUPERADMIN_EMAIL="admin@school.example.test",
            FIRST_SUPERADMIN_PASSWORD="safe-admin-password",
            BACKEND_CORS_ORIGINS=["https://school.example.test"],
            REDIS_URL="redis://redis.example.test/0",
            UPLOAD_SCANNER_BACKEND="clamav",
            UPLOAD_SCANNER_HOST="clamav",
            LOG_FORMAT="text",
        )


def test_production_rejects_default_database_admin_and_non_https_cors():
    with pytest.raises(ValidationError) as exc:
        Settings(
            _env_file=None,
            ENVIRONMENT="production",
            DATABASE_URL="postgresql+asyncpg://postgres:postgres@localhost:5432/schooling",
            JWT_SECRET_KEY="x" * 32,
            FIRST_SUPERADMIN_PASSWORD="not-the-default-password",
            BACKEND_CORS_ORIGINS="http://school.example.test,https://school.example.test/path",
            REDIS_URL="redis://redis.example.test/0",
            UPLOAD_SCANNER_BACKEND="clamav",
            UPLOAD_SCANNER_HOST="clamav.internal",
        )

    message = str(exc.value)
    assert "DATABASE_URL" in message
    assert "FIRST_SUPERADMIN_EMAIL" in message
    assert "BACKEND_CORS_ORIGINS" in message
