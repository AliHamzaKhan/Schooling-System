"""SMTP email adapter against a minimal local SMTP server (no provider)."""
import asyncio
from unittest.mock import patch

from app.core.config import settings
from app.modules.communication.providers import Notifier


class _FakeSMTP:
    """Just enough SMTP to accept or refuse one message."""

    def __init__(self) -> None:
        self.messages: list[str] = []

    async def handle(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        def send(line: str) -> None:
            writer.write((line + "\r\n").encode())

        send("220 test ready")
        await writer.drain()
        while line := (await reader.readline()).decode().strip():
            verb = line.split(" ", 1)[0].upper()
            if verb in {"EHLO", "HELO"}:
                send("250 test")
            elif verb == "MAIL":
                send("250 ok")
            elif verb == "RCPT":
                send("550 no such user" if "refused" in line else "250 ok")
            elif verb == "DATA":
                send("354 go ahead")
                await writer.drain()
                data = []
                while (chunk := (await reader.readline()).decode()) != ".\r\n":
                    data.append(chunk)
                self.messages.append("".join(data))
                send("250 queued")
            elif verb == "QUIT":
                send("221 bye")
                await writer.drain()
                break
            else:
                send("250 ok")
            await writer.drain()
        writer.close()


async def _with_server(callback):
    fake = _FakeSMTP()
    server = await asyncio.start_server(fake.handle, "127.0.0.1", 0)
    port = server.sockets[0].getsockname()[1]
    try:
        with patch.multiple(
            settings, SMTP_HOST="127.0.0.1", SMTP_PORT=port, SMTP_SECURITY="none",
            SMTP_USERNAME="", SMTP_PASSWORD="", EMAIL_FROM="school@example.org",
        ):
            return fake, await callback()
    finally:
        server.close()
        await server.wait_closed()


async def test_smtp_hand_off_is_reported_as_accepted():
    fake, result = await _with_server(
        lambda: Notifier().dispatch("email", "parent@example.org", "Fee reminder", "Invoice due Friday")
    )
    assert (result.status, result.provider, result.stub) == ("accepted", "smtp", False)
    assert "Subject: Fee reminder" in fake.messages[0]
    assert "Invoice due Friday" in fake.messages[0]


async def test_refused_recipient_is_failed_without_echoing_the_address():
    fake, result = await _with_server(
        lambda: Notifier().dispatch("email", "refused@example.org", None, "body")
    )
    assert (result.status, result.provider) == ("failed", "smtp")
    assert "refused@example.org" not in (result.error or "")
    assert fake.messages == []


async def test_unreachable_server_is_failed_not_uncertain():
    with patch.multiple(settings, SMTP_HOST="127.0.0.1", SMTP_PORT=1, SMTP_SECURITY="none", EMAIL_FROM="s@example.org"):
        result = await Notifier().dispatch("email", "parent@example.org", None, "body")
    assert (result.status, result.provider) == ("failed", "smtp")


async def test_email_without_smtp_host_is_simulated():
    with patch.multiple(settings, SMTP_HOST="", EMAIL_FROM=""):
        result = await Notifier().dispatch("email", "parent@example.org", None, "body")
    assert (result.status, result.stub) == ("simulated", True)
