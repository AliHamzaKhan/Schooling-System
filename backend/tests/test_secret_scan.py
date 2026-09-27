"""Regression coverage for the redacted tracked-secret CI scanner."""

from pathlib import Path

from scripts.scan_tracked_secrets import scan_text


def test_scanner_reports_categories_without_secret_value():
    findings = scan_text(
        Path("fixture.env"),
        "JWT_SECRET_KEY=not-a-real-secret-value\n"
        "-----BEGIN PRIVATE KEY-----\n"
        "const token = 'ghp_abcdefghijklmnopqrstuvwxyz1234567890'\n",
    )

    assert [finding.category for finding in findings] == [
        "secret-assignment",
        "private-key",
        "token-pattern",
    ]
    assert all("not-a-real-secret-value" not in str(finding) for finding in findings)


def test_scanner_accepts_documented_placeholders():
    findings = scan_text(
        Path(".env.example"),
        "JWT_SECRET_KEY=${JWT_SECRET_KEY}\n"
        "API_TOKEN=your_api_token\n"
        "PASSWORD=ci-test-secret-not-used-in-prod\n",
    )

    assert findings == []


def test_scanner_ignores_code_identifiers_and_public_firebase_client_config():
    assert scan_text(
        Path("module.py"),
        "password = request.password\nDB_PASSWORD: str = ''\n",
    ) == []
    assert scan_text(
        Path("frontend/school_portal/lib/firebase_options.dart"),
        "apiKey: 'AIzaabcdefghijklmnopqrstuvwxyz1234567890',\n",
    ) == []
