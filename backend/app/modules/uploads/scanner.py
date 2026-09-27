"""Pre-storage upload scanning through the ClamAV INSTREAM protocol."""
from __future__ import annotations

import asyncio
from contextlib import suppress
from functools import lru_cache

from app.core.config import settings

_CHUNK_BYTES = 64 * 1024
_MAX_RESPONSE_BYTES = 1024


class ScanRejected(Exception):
    """The scanner identified unsafe content. The bytes were not stored."""


class ScannerUnavailable(Exception):
    """The scanner could not provide a trustworthy clean result."""


class DisabledScanner:
    """Development/test-only scanner placeholder; production config rejects it."""

    async def scan(self, _data: bytes) -> None:
        return None

    async def ready(self) -> bool:
        return True


class ClamAVScanner:
    def __init__(self, host: str, port: int, timeout_seconds: float) -> None:
        self.host = host
        self.port = port
        self.timeout_seconds = timeout_seconds

    async def _exchange(self, command: bytes, data: bytes = b"") -> str:
        writer = None
        try:
            reader, writer = await asyncio.wait_for(
                asyncio.open_connection(self.host, self.port), timeout=self.timeout_seconds,
            )
            writer.write(command)
            for offset in range(0, len(data), _CHUNK_BYTES):
                chunk = data[offset:offset + _CHUNK_BYTES]
                writer.write(len(chunk).to_bytes(4, "big") + chunk)
            if data:
                writer.write((0).to_bytes(4, "big"))
            await asyncio.wait_for(writer.drain(), timeout=self.timeout_seconds)
            reply = await asyncio.wait_for(
                reader.readuntil(b"\0"), timeout=self.timeout_seconds,
            )
            if len(reply) > _MAX_RESPONSE_BYTES:
                raise ScannerUnavailable()
            return reply.rstrip(b"\0").decode("utf-8", errors="replace")
        except (
            asyncio.IncompleteReadError,
            asyncio.LimitOverrunError,
            ConnectionError,
            OSError,
            TimeoutError,
        ) as exc:
            raise ScannerUnavailable() from exc
        finally:
            if writer is not None:
                writer.close()
                with suppress(Exception):
                    await writer.wait_closed()

    async def scan(self, data: bytes) -> None:
        response = await self._exchange(b"zINSTREAM\0", data)
        if response.endswith("OK"):
            return
        if response.endswith("FOUND"):
            raise ScanRejected()
        raise ScannerUnavailable()

    async def ready(self) -> bool:
        response = await self._exchange(b"zPING\0")
        return response == "PONG"


@lru_cache
def get_upload_scanner() -> DisabledScanner | ClamAVScanner:
    backend = settings.UPLOAD_SCANNER_BACKEND.lower()
    if backend == "disabled":
        return DisabledScanner()
    if backend == "clamav":
        return ClamAVScanner(
            settings.UPLOAD_SCANNER_HOST,
            settings.UPLOAD_SCANNER_PORT,
            settings.UPLOAD_SCANNER_TIMEOUT_SECONDS,
        )
    raise RuntimeError(
        f"Unsupported UPLOAD_SCANNER_BACKEND '{settings.UPLOAD_SCANNER_BACKEND}'. "
        "Only 'clamav' or development/test 'disabled' are supported."
    )
