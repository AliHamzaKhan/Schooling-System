import unittest
from types import SimpleNamespace
from unittest.mock import AsyncMock

from fastapi import HTTPException

from app.modules.uploads.limits import CHUNK_BYTES, read_limited_upload


class UploadLimitTest(unittest.IsolatedAsyncioTestCase):
    async def test_exact_limit_is_accepted(self):
        file = SimpleNamespace(read=AsyncMock(side_effect=[b"12345", b""]))
        self.assertEqual(await read_limited_upload(file, 5), b"12345")
        self.assertEqual([call.args[0] for call in file.read.await_args_list], [6, 1])

    async def test_over_limit_stops_before_reading_remainder(self):
        file = SimpleNamespace(read=AsyncMock(side_effect=[b"123456", b"must not read"]))
        with self.assertRaises(HTTPException) as ctx:
            await read_limited_upload(file, 5)
        self.assertEqual(ctx.exception.status_code, 400)
        file.read.assert_awaited_once_with(6)

    async def test_large_upload_reads_in_bounded_chunks(self):
        file = SimpleNamespace(read=AsyncMock(side_effect=[b"x" * CHUNK_BYTES, b"x", b""]))
        self.assertEqual(len(await read_limited_upload(file, CHUNK_BYTES + 1)), CHUNK_BYTES + 1)
        self.assertTrue(all(0 < call.args[0] <= CHUNK_BYTES for call in file.read.await_args_list))

    async def test_empty_file_and_invalid_limit_fail(self):
        file = SimpleNamespace(read=AsyncMock(return_value=b""))
        with self.assertRaises(HTTPException):
            await read_limited_upload(file, 5)
        with self.assertRaises(ValueError):
            await read_limited_upload(file, 0)
