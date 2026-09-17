"""Regression tests for rate-limit response headers, without touching a DB.

Run: .venv/bin/python -m unittest discover -s verification -v
"""
import unittest
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

from app.core.database import get_db
from app.core.ratelimit import limiter
from app.modules.auth.router import router


class AuthRateHeadersTest(unittest.IsolatedAsyncioTestCase):
    async def test_successful_login_and_refresh_emit_headers(self):
        app = FastAPI()
        app.state.limiter = limiter
        app.include_router(router)

        async def fake_db():
            yield None

        app.dependency_overrides[get_db] = fake_db
        service = SimpleNamespace(
            authenticate=AsyncMock(return_value=SimpleNamespace(id='test-user')),
            start_session=AsyncMock(return_value=('test-access', 'test-refresh')),
            rotate_session=AsyncMock(return_value=('next-access', 'next-refresh')),
        )
        with patch('app.modules.auth.router.AuthService', return_value=service):
            async with AsyncClient(transport=ASGITransport(app=app), base_url='http://test') as client:
                login = await client.post('/auth/login', data={
                    'username': 'preview@example.com', 'password': 'test-only',
                })
                self.assertEqual(login.status_code, 200, login.text)
                self.assertEqual(login.json()['access_token'], 'test-access')
                self.assertIn('x-ratelimit-limit', login.headers)
                refresh = await client.post('/auth/refresh', json={'refresh_token': 'test-refresh'})
                self.assertEqual(refresh.status_code, 200, refresh.text)
                self.assertIn('x-ratelimit-limit', refresh.headers)


if __name__ == '__main__':
    unittest.main()
