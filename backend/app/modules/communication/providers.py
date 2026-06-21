"""Notification delivery providers.

Real adapters for Twilio (WhatsApp/SMS) and Firebase Cloud Messaging (push),
plus a plain email placeholder. When the relevant credentials are not configured
in settings, each channel degrades to "stub" mode: it logs the intended message
and reports success without making a network call. This keeps the whole
Communication module runnable and testable without secrets, and live the moment
credentials are added to .env.
"""
import logging
from dataclasses import dataclass

from app.core.config import settings
from app.core.enums import Channel, DeliveryStatus

logger = logging.getLogger("communication")

TWILIO_BASE = "https://api.twilio.com/2010-04-01"
FCM_LEGACY_URL = "https://fcm.googleapis.com/fcm/send"
_TIMEOUT = 15.0


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
        return bool(settings.FCM_SERVER_KEY)

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
            logger.warning("Delivery error on %s to %s: %s", channel, address, exc)
            return DeliveryResult(status=DeliveryStatus.FAILED.value, provider="error", error=str(exc))
        return DeliveryResult(status=DeliveryStatus.FAILED.value, provider="none", error="Unknown channel")

    # ------------------------------ Twilio ------------------------------- #

    async def _twilio(self, to: str, body: str, *, whatsapp: bool) -> DeliveryResult:
        if not self._twilio_ready():
            logger.info("[STUB twilio %s] to=%s body=%r", "whatsapp" if whatsapp else "sms", to, body)
            return DeliveryResult(status=DeliveryStatus.SENT.value, provider="stub", stub=True)

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
        if resp.status_code >= 400:
            return DeliveryResult(
                status=DeliveryStatus.FAILED.value, provider="twilio",
                error=f"HTTP {resp.status_code}: {resp.text[:200]}",
            )
        return DeliveryResult(status=DeliveryStatus.SENT.value, provider="twilio")

    # ------------------------------- FCM --------------------------------- #

    async def _fcm(self, token: str, title: str | None, body: str) -> DeliveryResult:
        if not self._fcm_ready():
            logger.info("[STUB fcm] token=%s title=%r body=%r", token[:12], title, body)
            return DeliveryResult(status=DeliveryStatus.SENT.value, provider="stub", stub=True)

        import httpx

        payload = {"to": token, "notification": {"title": title or "", "body": body}}
        headers = {
            "Authorization": f"key={settings.FCM_SERVER_KEY}",
            "Content-Type": "application/json",
        }
        async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
            resp = await client.post(FCM_LEGACY_URL, json=payload, headers=headers)
        if resp.status_code >= 400:
            return DeliveryResult(
                status=DeliveryStatus.FAILED.value, provider="fcm",
                error=f"HTTP {resp.status_code}: {resp.text[:200]}",
            )
        return DeliveryResult(status=DeliveryStatus.SENT.value, provider="fcm")

    # ------------------------------ email -------------------------------- #

    async def _email(self, to: str, subject: str | None, body: str) -> DeliveryResult:
        # Real SMTP not configured here; log in stub mode.
        logger.info("[STUB email] to=%s subject=%r body=%r", to, subject, body)
        return DeliveryResult(status=DeliveryStatus.SENT.value, provider="stub", stub=True)


notifier = Notifier()
