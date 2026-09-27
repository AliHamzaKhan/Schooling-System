from unittest.mock import AsyncMock, patch

from app.modules.uploads.scanner import ClamAVScanner, ScanRejected, ScannerUnavailable


class Reader:
    def __init__(self, reply: bytes):
        self.reply = reply

    async def readuntil(self, _separator: bytes) -> bytes:
        return self.reply


class Writer:
    def __init__(self):
        self.writes: list[bytes] = []

    def write(self, data: bytes) -> None:
        self.writes.append(data)

    async def drain(self) -> None:
        return None

    def close(self) -> None:
        return None

    async def wait_closed(self) -> None:
        return None


async def test_clamav_scanner_streams_bytes_and_accepts_clean_reply():
    writer = Writer()
    scanner = ClamAVScanner("scanner", 3310, 1)
    with patch(
        "app.modules.uploads.scanner.asyncio.open_connection",
        new=AsyncMock(return_value=(Reader(b"stream: OK\0"), writer)),
    ):
        await scanner.scan(b"safe")
    assert writer.writes == [b"zINSTREAM\0", (4).to_bytes(4, "big") + b"safe", b"\0\0\0\0"]


async def test_clamav_scanner_rejects_detected_or_unavailable_results():
    scanner = ClamAVScanner("scanner", 3310, 1)
    with patch(
        "app.modules.uploads.scanner.asyncio.open_connection",
        new=AsyncMock(return_value=(Reader(b"stream: Eicar FOUND\0"), Writer())),
    ):
        try:
            await scanner.scan(b"unsafe")
        except ScanRejected:
            pass
        else:
            raise AssertionError("detected content must be rejected")
    with patch("app.modules.uploads.scanner.asyncio.open_connection", side_effect=OSError):
        try:
            await scanner.scan(b"safe")
        except ScannerUnavailable:
            pass
        else:
            raise AssertionError("scanner failure must fail closed")


async def test_upload_never_stores_rejected_or_unscanned_content(client, school):
    endpoint = f"/api/v1/schools/{school['id']}/uploads"
    scanner = AsyncMock()
    scanner.scan.side_effect = ScannerUnavailable()
    with patch("app.modules.uploads.router.get_upload_scanner", return_value=scanner), patch(
        "app.modules.uploads.router.get_storage"
    ) as storage:
        storage.return_value.save = AsyncMock()
        response = await client.post(
            endpoint, headers=school["hm"], data={"folder": "documents"},
            files={"file": ("certificate.pdf", b"%PDF-safe", "application/pdf")},
        )
        assert response.status_code == 503, response.text
        storage.return_value.save.assert_not_awaited()
