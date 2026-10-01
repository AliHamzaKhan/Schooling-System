"""Notification delivery providers.

Real adapters for Twilio (WhatsApp/SMS), Firebase Cloud Messaging (push) and
SMTP email. When the relevant credentials are not configured in settings, each
channel reports "simulated": no delivery was attempted. Successful provider
requests report "accepted", never confirmed delivery.
"""
import asyncio
import json
import logging
import smtplib
import ssl
import time
from email.message import EmailMessage
from dataclasses import dataclass

from app.core.config import settings
from app.core.enums import Channel, DeliveryStatus

logger = logging.getLogger("communication")

TWILIO_BASE = "https://api.twilio.com/2010-04-01"
FCM_V1_URL = "https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"
FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
_TIMEOUT = 15.0

# Service-account key, parsed once. Reading a few KB of JSON per push would be
# wasteful and the contents never change while the process runs.
_fcm_key: dict | None = None

# Cached OAuth2 access token as (token, expires_at_epoch). Google's tokens last
# an hour; minting one per push would add a round trip to every notification.
_fcm_token: tuple[str, float] | None = None

# Refresh this many seconds before actual expiry, so a token can't lapse
# mid-flight between the check and the send.
_FCM_TOKEN_SKEW = 120


@dataclass
class DeliveryResult:
    status: str            # DeliveryStatus value
    provider: str          # "twilio" | "fcm" | "smtp" | "stub" | "none"
    error: str | None = None
    stub: bool = False


class Notifier:
    """Dispatches a single message to a single address on a channel."""

    # ------------------------- capability checks ------------------------- #

    @staticmethod
    def _twilio_ready() -> bool:
        return bool(settings.TWILIO_ACCOUNT_SID and settings.TWILIO_AUTH_TOKEN)

    @staticmethod
    def _fcm_ready() -> bool:
        return bool(
            settings.FIREBASE_CREDENTIALS_FILE or settings.FIREBASE_CREDENTIALS_JSON
        )

    @staticmethod
    def _smtp_ready() -> bool:
        return bool(settings.SMTP_HOST and settings.EMAIL_FROM)

    # ------------------------------ dispatch ----------------------------- #

    async def dispatch(
        self, channel: str, address: str | None, subject: str | None, body: str
    ) -> DeliveryResult:
        if not address:
            return DeliveryResult(
                status=DeliveryStatus.FAILED.value, provider="none",
                error="No address for this channel",
            )
        try:
            if channel == Channel.WHATSAPP.value:
                return await self._twilio(address, body, whatsapp=True)
            if channel == Channel.SMS.value:
                return await self._twilio(address, body, whatsapp=False)
            if channel == Channel.PUSH.value:
                return await self._fcm(address, subject, body)
            if channel == Channel.EMAIL.value:
                return await self._email(address, subject, body)
        except Exception as exc:  # network/provider error -> failed, never crash the send
            logger.warning("Delivery error on %s (%s)", channel, type(exc).__name__)
            return DeliveryResult(status=DeliveryStatus.UNCERTAIN.value, provider="error",
                                  error=f"Provider outcome unknown ({type(exc).__name__}); review before retry")
        return DeliveryResult(status=DeliveryStatus.FAILED.value, provider="none", error="Unknown channel")

    # ------------------------------ Twilio ------------------------------- #

    async def _twilio(self, to: str, body: str, *, whatsapp: bool) -> DeliveryResult:
        if not self._twilio_ready():
            logger.info("[STUB twilio %s] no delivery attempted", "whatsapp" if whatsapp else "sms")
            return DeliveryResult(status=DeliveryStatus.SIMULATED.value, provider="stub",
                                  error="Provider not configured; no delivery attempted", stub=True)

        sender = settings.TWILIO_WHATSAPP_FROM if whatsapp else settings.TWILIO_SMS_FROM
        to_addr = f"whatsapp:{to}" if whatsapp and not to.startswith("whatsapp:") else to

        import httpx

        url = f"{TWILIO_BASE}/Accounts/{settings.TWILIO_ACCOUNT_SID}/Messages.json"
        data = {"From": sender, "To": to_addr, "Body": body}
        async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
            resp = await client.post(
                url, data=data,
                auth=(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN),
            )
        if resp.status_code >= 300:
            return DeliveryResult(
                status=DeliveryStatus.UNCERTAIN.value if resp.status_code >= 500 else DeliveryStatus.FAILED.value, provider="twilio",
                error=f"HTTP {resp.status_code}",
            )
        return DeliveryResult(status=DeliveryStatus.ACCEPTED.value, provider="twilio")

    # ------------------------------- FCM --------------------------------- #

    @staticmethod
    def _load_fcm_key() -> dict:
        """The service-account key, from a file path or raw JSON. Parsed once."""
        global _fcm_key
        if _fcm_key is None:
            if settings.FIREBASE_CREDENTIALS_JSON:
                _fcm_key = json.loads(settings.FIREBASE_CREDENTIALS_JSON)
            else:
                with open(settings.FIREBASE_CREDENTIALS_FILE) as fh:
                    _fcm_key = json.load(fh)
        return _fcm_key

    @classmethod
    async def _fcm_access_token(cls) -> str:
        """A valid OAuth2 access token for FCM, cached until near expiry.

        Implements Google's service-account flow directly — sign a short-lived
        JWT assertion with the key, then exchange it at the token endpoint.
        google-auth would do this too, but only through a synchronous
        `requests` transport; doing it here keeps the call async and avoids
        pulling in an HTTP stack the project doesn't otherwise use.
        """
        global _fcm_token
        now = time.time()
        if _fcm_token is not None and _fcm_token[1] - _FCM_TOKEN_SKEW > now:
            return _fcm_token[0]

        import httpx
        import jwt

        key = cls._load_fcm_key()
        token_uri = key.get("token_uri", "https://oauth2.googleapis.com/token")
        assertion = jwt.encode(
            {
                "iss": key["client_email"],
                "scope": FCM_SCOPE,
                "aud": token_uri,
                "iat": int(now),
                "exp": int(now) + 3600,
            },
            key["private_key"],
            algorithm="RS256",
            headers={"kid": key.get("private_key_id")},
        )

        async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
            resp = await client.post(
                token_uri,
                data={
                    "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
                    "assertion": assertion,
                },
            )
        resp.raise_for_status()
        payload = resp.json()
        access_token = payload["access_token"]
        _fcm_token = (access_token, now + float(payload.get("expires_in", 3600)))
        return access_token

    async def _fcm(self, token: str, title: str | None, body: str) -> DeliveryResult:
        """Send one push via FCM HTTP v1.

        The legacy `fcm.googleapis.com/fcm/send` endpoint this used to call was
        shut down by Google in July 2024; v1 needs a short-lived OAuth2 token
        minted from the service account rather than a static server key.
        """
        if not self._fcm_ready():
            logger.info("[STUB fcm] no delivery attempted")
            return DeliveryResult(status=DeliveryStatus.SIMULATED.value, provider="stub",
                                  error="Provider not configured; no delivery attempted", stub=True)

        import httpx

        access_token = await self._fcm_access_token()
        project_id = self._load_fcm_key()["project_id"]
        url = FCM_V1_URL.format(project_id=project_id)
        payload = {
            "message": {
                "token": token,
                "notification": {"title": title or "", "body": body},
            }
        }
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json; UTF-8",
        }
        async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
            resp = await client.post(url, json=payload, headers=headers)

        if resp.status_code >= 300:
            # Preserve known machine codes, never echoed payloads or tokens.
            # INVALID_ARGUMENT may also indicate a malformed message, not a dead token.
            known_codes = {"UNREGISTERED", "INVALID_ARGUMENT", "SENDER_ID_MISMATCH",
                           "QUOTA_EXCEEDED", "UNAVAILABLE", "INTERNAL", "THIRD_PARTY_AUTH_ERROR"}
            codes = []
            try:
                error = resp.json().get("error", {})
                candidates = [error.get("status")] + [
                    detail.get("errorCode") for detail in error.get("details", [])
                    if isinstance(detail, dict)
                ]
                codes = sorted({code for code in candidates if isinstance(code, str) and code in known_codes})
            except (ValueError, AttributeError, TypeError):
                pass
            return DeliveryResult(
                status=DeliveryStatus.UNCERTAIN.value if resp.status_code >= 500 else DeliveryStatus.FAILED.value, provider="fcm",
                error=f"HTTP {resp.status_code}" + (f": {', '.join(codes)}" if codes else ""),
            )
        return DeliveryResult(status=DeliveryStatus.ACCEPTED.value, provider="fcm")

    # ------------------------------ email -------------------------------- #

    async def _email(self, to: str, subject: str | None, body: str) -> DeliveryResult:
        if not self._smtp_ready():
            logger.info("[STUB email] no delivery attempted")
            return DeliveryResult(status=DeliveryStatus.SIMULATED.value, provider="stub",
                                  error="Email delivery is not configured; no delivery attempted", stub=True)
        message = EmailMessage()
        message["From"] = settings.EMAIL_FROM
        message["To"] = to
        message["Subject"] = subject or "School notification"
        message.set_content(body)
        try:
            refused = await asyncio.to_thread(_smtp_send, message)
        except (smtplib.SMTPRecipientsRefused, smtplib.SMTPSenderRefused) as exc:
            # The server rejected the envelope before any message data was sent.
            return DeliveryResult(status=DeliveryStatus.FAILED.value, provider="smtp",
                                  error=f"Rejected by mail server ({type(exc).__name__})")
        except (smtplib.SMTPAuthenticationError, smtplib.SMTPConnectError, ConnectionRefusedError) as exc:
            # Nothing was handed over: login or connection failed.
            return DeliveryResult(status=DeliveryStatus.FAILED.value, provider="smtp",
                                  error=f"Mail server unavailable or login failed ({type(exc).__name__})")
        if refused:
            return DeliveryResult(status=DeliveryStatus.FAILED.value, provider="smtp",
                                  error="Recipient refused by mail server")
        return DeliveryResult(status=DeliveryStatus.ACCEPTED.value, provider="smtp")


def _smtp_send(message: EmailMessage) -> dict:
    """Blocking SMTP hand-off, run in a worker thread. Returns refused recipients."""
    security = settings.SMTP_SECURITY.lower()
    context = ssl.create_default_context()
    if security == "ssl":
        server: smtplib.SMTP = smtplib.SMTP_SSL(settings.SMTP_HOST, settings.SMTP_PORT, timeout=_TIMEOUT, context=context)
    else:
        server = smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=_TIMEOUT)
    with server:
        if security == "starttls":
            server.starttls(context=context)
        if settings.SMTP_USERNAME:
            server.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
        return server.send_message(message)


notifier = Notifier()
