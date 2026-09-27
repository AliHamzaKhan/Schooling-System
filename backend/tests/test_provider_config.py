"""Provider configuration must fail closed without printing credentials."""
import base64
import pytest
from pydantic import ValidationError

from app.core.config import Settings


def test_partial_twilio_configuration_is_rejected():
    with pytest.raises(ValidationError, match="TWILIO_ACCOUNT_SID"):
        Settings(_env_file=None, TWILIO_ACCOUNT_SID="account-only")


def test_twilio_configuration_requires_a_sender():
    with pytest.raises(ValidationError, match="Twilio sender"):
        Settings(
            _env_file=None,
            TWILIO_ACCOUNT_SID="account",
            TWILIO_AUTH_TOKEN="token",
        )


def test_firebase_credentials_reject_ambiguous_or_incomplete_sources():
    with pytest.raises(ValidationError, match="only one Firebase"):
        Settings(
            _env_file=None,
            FIREBASE_CREDENTIALS_FILE="/run/secrets/fcm.json",
            FIREBASE_CREDENTIALS_JSON="{}",
        )
    with pytest.raises(ValidationError, match="project_id"):
        Settings(_env_file=None, FIREBASE_CREDENTIALS_JSON='{"project_id": "project"}')


def test_firebase_base64_credentials_decode_before_validation():
    raw = '{"project_id":"project","client_email":"service@example.test","private_key":"key"}'
    settings = Settings(
        _env_file=None,
        FIREBASE_CREDENTIALS_JSON_B64=base64.b64encode(raw.encode()).decode(),
    )
    assert settings.FIREBASE_CREDENTIALS_JSON == raw


def test_invalid_firebase_base64_credentials_are_rejected():
    with pytest.raises(ValidationError, match="JSON_B64"):
        Settings(_env_file=None, FIREBASE_CREDENTIALS_JSON_B64="not valid base64")
