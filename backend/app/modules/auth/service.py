"""Authentication service: credentials, token issuance, and refresh sessions.

Refresh tokens are backed by `RefreshSession` rows so they can be rotated,
revoked, and checked for reuse. Access tokens remain stateless; see
`app/models/session.py` for the rationale.
"""
import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.exceptions import credentials_exception
from app.core.security import (
    ACCESS_TOKEN,
    JWTError,
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_token,
    verify_password,
)
from app.models.role import Role
from app.models.session import RefreshSession
from app.models.user import User


def _refresh_expiry() -> datetime:
    return datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)


class AuthService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def authenticate(self, email: str, password: str) -> User | None:
        result = await self.db.execute(
            select(User)
            .where(User.email == email.lower())
            .options(selectinload(User.roles).selectinload(Role.permissions))
        )
        user = result.scalar_one_or_none()
        if user is None or not user.is_active:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user

    async def get_user(self, user_id: str) -> User | None:
        result = await self.db.execute(
            select(User)
            .where(User.id == user_id)
            .options(selectinload(User.roles).selectinload(Role.permissions))
        )
        return result.scalar_one_or_none()

    async def start_session(
        self, user: User, *, user_agent: str | None = None, ip: str | None = None
    ) -> tuple[str, str]:
        """Open a new refresh session for `user` and return (access, refresh)."""
        session_id = uuid.uuid4()
        refresh = create_refresh_token(str(user.id), str(session_id))
        self.db.add(
            RefreshSession(
                id=session_id,
                user_id=user.id,
                token_hash=hash_token(refresh),
                expires_at=_refresh_expiry(),
                user_agent=user_agent[:255] if user_agent else None,
                ip_address=ip,
            )
        )
        return create_access_token(str(user.id)), refresh

    async def rotate_session(self, refresh_token: str) -> tuple[str, str]:
        """Validate + rotate a refresh token, returning a fresh (access, refresh).

        Raises `credentials_exception` on any failure. If a previously-rotated
        token is replayed (hash mismatch), the whole session is revoked — the
        standard response to a leaked refresh token.
        """
        payload = self._decode_refresh(refresh_token)
        session = await self.db.get(RefreshSession, payload["sid"])
        now = datetime.now(timezone.utc)

        if (
            session is None
            or session.revoked_at is not None
            or session.user_id != payload["sub"]
            or session.expires_at <= now
        ):
            raise credentials_exception()

        if session.token_hash != hash_token(refresh_token):
            # Replay of an already-rotated token → treat as compromise.
            await self._revoke_and_commit(session, now)
            raise credentials_exception()

        user = await self.get_user(str(payload["sub"]))
        if user is None or not user.is_active:
            await self._revoke_and_commit(session, now)
            raise credentials_exception()

        new_refresh = create_refresh_token(str(user.id), str(session.id))
        session.token_hash = hash_token(new_refresh)
        session.expires_at = _refresh_expiry()
        session.last_used_at = now
        return create_access_token(str(user.id)), new_refresh

    async def revoke_session(self, refresh_token: str) -> None:
        """Logout: revoke the session this refresh token belongs to (idempotent)."""
        try:
            payload = self._decode_refresh(refresh_token)
        except Exception:
            return  # A bad/expired token has nothing to revoke; stay quiet.
        session = await self.db.get(RefreshSession, payload["sid"])
        if session is not None and session.revoked_at is None:
            session.revoked_at = datetime.now(timezone.utc)

    async def revoke_all_for_user(self, user_id: uuid.UUID) -> int:
        """Logout everywhere: revoke every active session for a user."""
        result = await self.db.execute(
            update(RefreshSession)
            .where(
                RefreshSession.user_id == user_id,
                RefreshSession.revoked_at.is_(None),
            )
            .values(revoked_at=datetime.now(timezone.utc))
        )
        return result.rowcount or 0

    # --- internals --------------------------------------------------------- #

    @staticmethod
    def _decode_refresh(token: str) -> dict:
        """Decode a refresh token into {'sub': UUID, 'sid': UUID}."""
        try:
            payload = decode_token(token)
            if payload.get("type") == ACCESS_TOKEN:
                raise credentials_exception()
            return {
                "sub": uuid.UUID(payload["sub"]),
                "sid": uuid.UUID(payload["sid"]),
            }
        except (JWTError, KeyError, ValueError, TypeError):
            raise credentials_exception()

    async def _revoke_and_commit(self, session: RefreshSession, when: datetime) -> None:
        """Persist a revocation even though the caller then raises 401.

        The request DB dependency rolls back on the raised exception, so the
        revoke must be committed here or it would be lost.
        """
        session.revoked_at = when
        await self.db.commit()
