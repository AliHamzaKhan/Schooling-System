"""Authentication service: credentials, token issuance, and refresh sessions.

Refresh tokens are backed by `RefreshSession` rows so they can be rotated,
revoked, and checked for reuse. Access tokens remain stateless; see
`app/models/session.py` for the rationale.
"""
import secrets
import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.exceptions import bad_request, credentials_exception
from app.core.security import (
    ACCESS_TOKEN,
    RESET_TOKEN,
    JWTError,
    create_access_token,
    create_password_reset_token,
    create_refresh_token,
    decode_token,
    hash_password,
    hash_token,
    verify_password,
)
from app.models.password_reset import PasswordReset
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

    async def change_password(
        self, user: User, current_password: str, new_password: str
    ) -> None:
        """Change the signed-in user's password after re-checking the current one,
        then revoke every refresh session (all devices must re-authenticate)."""
        if not verify_password(current_password, user.hashed_password):
            raise bad_request("Current password is incorrect")
        user.hashed_password = hash_password(new_password)
        await self.revoke_all_for_user(user.id)

    # --- password reset (forgot-password OTP flow) ------------------------- #

    async def request_password_reset(self, email: str) -> str | None:
        """Start a reset for `email`: mint an OTP, persist its hash, and return
        the raw OTP for the caller to deliver (email/SMS).

        Returns ``None`` when the address has no active account — the endpoint
        still responds identically either way, so a caller can't use it to probe
        which emails are registered. Any earlier pending OTP for the user is
        burned so only the newest code is ever valid.
        """
        result = await self.db.execute(select(User).where(User.email == email.lower()))
        user = result.scalar_one_or_none()
        if user is None or not user.is_active:
            return None

        now = datetime.now(timezone.utc)
        # Invalidate any still-pending OTP for this user.
        await self.db.execute(
            update(PasswordReset)
            .where(
                PasswordReset.user_id == user.id,
                PasswordReset.consumed_at.is_(None),
            )
            .values(consumed_at=now)
        )
        code = f"{secrets.randbelow(1_000_000):06d}"
        self.db.add(
            PasswordReset(
                user_id=user.id,
                code_hash=hash_token(code),
                expires_at=now
                + timedelta(minutes=settings.PASSWORD_RESET_OTP_TTL_MINUTES),
            )
        )
        return code

    async def verify_reset_otp(self, email: str, code: str) -> str:
        """Check an OTP and, on success, return a short-lived reset token.

        Every failure path raises the same generic error so the endpoint reveals
        neither whether the email exists nor whether the code merely expired.
        """
        now = datetime.now(timezone.utc)
        result = await self.db.execute(
            select(PasswordReset)
            .join(User, User.id == PasswordReset.user_id)
            .where(User.email == email.lower(), PasswordReset.consumed_at.is_(None))
            .order_by(PasswordReset.created_at.desc())
            .limit(1)
        )
        reset = result.scalar_one_or_none()
        invalid = bad_request("Invalid or expired code")

        if (
            reset is None
            or reset.verified_at is not None  # already used to mint a token
            or reset.expires_at <= now
            or reset.attempts >= settings.PASSWORD_RESET_MAX_ATTEMPTS
        ):
            raise invalid

        if reset.code_hash != hash_token(code):
            reset.attempts += 1
            await self.db.commit()  # persist the attempt even though we 400
            raise invalid

        reset.verified_at = now
        await self.db.flush()
        return create_password_reset_token(str(reset.user_id), str(reset.id))

    async def reset_password(self, token: str, new_password: str) -> None:
        """Complete a reset with the token from [verify_reset_otp]: set the new
        password, burn the challenge, and sign the user out everywhere (a reset
        is exactly when you want every existing session killed)."""
        try:
            payload = decode_token(token)
            if payload.get("type") != RESET_TOKEN:
                raise credentials_exception()
            user_id = uuid.UUID(payload["sub"])
            reset_id = uuid.UUID(payload["rid"])
        except (JWTError, KeyError, ValueError, TypeError):
            raise credentials_exception()

        reset = await self.db.get(PasswordReset, reset_id)
        now = datetime.now(timezone.utc)
        if (
            reset is None
            or reset.user_id != user_id
            or reset.verified_at is None
            or reset.consumed_at is not None
        ):
            raise credentials_exception()

        user = await self.db.get(User, user_id)
        if user is None:
            raise credentials_exception()

        user.hashed_password = hash_password(new_password)
        reset.consumed_at = now
        await self.revoke_all_for_user(user_id)

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
