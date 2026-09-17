"""Fail-closed test configuration. This module never opens a connection."""
import re
from collections.abc import MutableMapping

from sqlalchemy.engine import make_url


def configure_test_environment(env: MutableMapping[str, str]) -> str:
    raw = env.get("SCHOOLING_TEST_DATABASE_URL", "")
    if not raw:
        raise RuntimeError(
            "SCHOOLING_TEST_DATABASE_URL is required. Use scripts/run_isolated_tests.py; "
            "the normal DATABASE_URL is never a test database fallback."
        )
    try:
        url = make_url(raw)
        safe = (
            url.drivername == "postgresql+asyncpg"
            and re.fullmatch(r"schooling_test_[a-z0-9_]+", url.database or "")
            and re.fullmatch(r"schooling_test_[a-z0-9_]+", url.username or "")
            and url.host
            and not url.query
        )
    except Exception:
        safe = False
    if not safe:
        # Never echo the URL; it contains credentials.
        raise RuntimeError("Tests require an explicit schooling_test_* database and role, without URL options.")

    env["DATABASE_URL"] = raw
    # Empty values override potentially dangerous inherited/ dotenv components.
    for key in ("DB_HOST", "DB_NAME", "DB_USER", "DB_PASSWORD"):
        env[key] = ""
    env["ENVIRONMENT"] = "test"
    env["JWT_SECRET_KEY"] = "isolated-test-secret-not-for-production"
    env["FIRST_SUPERADMIN_EMAIL"] = "admin@platform.com"
    env["FIRST_SUPERADMIN_PASSWORD"] = "ChangeMe123!"
    env["TASK_QUEUE_ENABLED"] = "false"
    for key in (
        "REDIS_URL", "TWILIO_ACCOUNT_SID", "TWILIO_AUTH_TOKEN", "TWILIO_SMS_FROM",
        "TWILIO_WHATSAPP_FROM", "FIREBASE_CREDENTIALS_FILE", "FIREBASE_CREDENTIALS_JSON",
        "FCM_SERVER_KEY", "EMAIL_FROM", "ANTHROPIC_API_KEY", "CRON_SECRET",
    ):
        env[key] = ""
    return raw


def assert_database_identity(*, database: str, username: str, superuser: bool,
                             create_db: bool, create_role: bool, owner: str,
                             has_tables: bool, expected_url: str) -> None:
    """Validate connected identity and emptiness before creating any schema."""
    url = make_url(expected_url)
    if (database != url.database or username != url.username or owner != username
            or superuser or create_db or create_role or has_tables):
        raise RuntimeError(
            "Refusing test schema setup: expected an empty, dedicated database "
            "owned by its non-privileged test role. No existing tables were changed."
        )
