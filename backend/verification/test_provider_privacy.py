"""Provider diagnostics must not expose messages, OTPs or device tokens."""
import unittest
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

from app.modules.communication.providers import Notifier
from app.modules.ai.providers import AIProvider


class ProviderPrivacyTest(unittest.IsolatedAsyncioTestCase):
    async def test_stub_messages_are_not_logged(self):
        notifier = Notifier()
        with patch.object(notifier, "_twilio_ready", return_value=False), \
                patch.object(notifier, "_fcm_ready", return_value=False), \
                self.assertLogs("communication", level="INFO") as logs:
            for channel in ("whatsapp", "sms", "push", "email"):
                result = await notifier.dispatch(channel, "secret-recipient", "secret-subject", "secret-otp")
                self.assertEqual(result.status, "simulated")
                self.assertTrue(result.stub)
        self.assertNotIn("secret", "\n".join(logs.output))

    async def test_twilio_success_is_acceptance_not_delivery(self):
        notifier = Notifier()
        client = AsyncMock()
        client.__aenter__.return_value = client
        client.post.return_value = SimpleNamespace(status_code=201)
        with patch.object(notifier, "_twilio_ready", return_value=True), \
                patch("httpx.AsyncClient", return_value=client):
            result = await notifier.dispatch("sms", "test-recipient", None, "test-body")
        self.assertEqual(result.status, "accepted")
        self.assertEqual(result.provider, "twilio")

    async def test_fcm_success_is_acceptance_not_delivery(self):
        notifier = Notifier()
        client = AsyncMock()
        client.__aenter__.return_value = client
        client.post.return_value = SimpleNamespace(status_code=200)
        with patch.object(notifier, "_fcm_ready", return_value=True), \
                patch.object(notifier, "_fcm_access_token", AsyncMock(return_value="fake-token")), \
                patch.object(notifier, "_load_fcm_key", return_value={"project_id": "fake-project"}), \
                patch("httpx.AsyncClient", return_value=client):
            result = await notifier.dispatch("push", "test-device", "test-title", "test-body")
        self.assertEqual(result.status, "accepted")
        self.assertEqual(result.provider, "fcm")

    async def test_provider_exception_is_not_logged_or_persisted(self):
        notifier = Notifier()
        with patch.object(notifier, "_email", AsyncMock(side_effect=ValueError("secret-password"))), \
                self.assertLogs("communication", level="WARNING") as logs:
            result = await notifier.dispatch("email", "secret-recipient", None, "secret-body")
        self.assertNotIn("secret", "\n".join(logs.output))
        self.assertNotIn("secret", result.error)
        self.assertIn("ValueError", result.error)
        self.assertEqual(result.status, "uncertain")

    async def test_provider_server_error_is_uncertain_not_safe_to_resend(self):
        notifier = Notifier()
        client = AsyncMock()
        client.__aenter__.return_value = client
        client.post.return_value = SimpleNamespace(status_code=503)
        with patch.object(notifier, "_twilio_ready", return_value=True), \
                patch("httpx.AsyncClient", return_value=client):
            result = await notifier.dispatch("sms", "test-recipient", None, "test-body")
        self.assertEqual(result.status, "uncertain")

    async def test_ai_stub_does_not_log_student_prompt(self):
        with patch("app.modules.ai.providers.settings.ANTHROPIC_API_KEY", ""), \
                self.assertLogs("ai", level="INFO") as logs:
            await AIProvider().generate("secret-student-record", None)
            await AIProvider().generate_json("secret-student-record", {}, stub={})
        self.assertNotIn("secret", "\n".join(logs.output))
