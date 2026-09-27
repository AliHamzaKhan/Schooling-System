"""Password hashing and JWT token helpers."""
import hashlib
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any

import jwt
from jwt.exceptions import InvalidTokenError as JWTError
from passlib.context import CryptContext

from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

ACCESS_TOKEN = "access"
REFRESH_TOKEN = "refresh"
RESET_TOKEN = "reset"


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def hash_token(token: str) -> str:
    """Stable, non-reversible fingerprint of a token string.

    Refresh tokens are stored only as this hash so a database/backup leak can't
    be used to mint sessions. SHA-256 (not a slow KDF) is deliberate: the input
    is already a high-entropy signed JWT, so there is nothing to brute-force.
    """
    return hashlib.sha256(token.encode()).hexdigest()


def _create_token(
    subject: str, token_type: str, expires_delta: timedelta, **extra: Any
) -> str:
    now = datetime.now(timezone.utc)
    payload: dict[str, Any] = {
        "sub": subject,
        "type": token_type,
        "iat": now,
        "exp": now + expires_delta,
        # Unique per token so two tokens minted in the same second (e.g. a
        # refresh rotation) are never byte-identical — rotation must produce a
        # genuinely new token for reuse detection to work.
        "jti": uuid.uuid4().hex,
        **extra,
    }
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def create_access_token(subject: str, session_id: str | None = None) -> str:
    return _create_token(
        subject, ACCESS_TOKEN, timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
        **({"sid": session_id} if session_id is not None else {}),
    )


def create_refresh_token(subject: str, session_id: str) -> str:
    """Mint a refresh token bound to a server-side session (`sid`).

    The session id ties every token in a rotation chain to one DB row, so the
    session can be rotated, revoked (logout), and checked for token reuse.
    """
    return _create_token(
        subject,
        REFRESH_TOKEN,
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        sid=session_id,
    )


def create_password_reset_token(subject: str, reset_id: str) -> str:
    """Mint the short-lived token that authorizes `POST /auth/reset-password`.

    Issued only after an OTP has been verified. Bound to the `PasswordReset` row
    (`rid`) so the token alone can't reset a password — the row must still be in
    the verified, unconsumed, unexpired state when redeemed.
    """
    return _create_token(
        subject,
        RESET_TOKEN,
        timedelta(minutes=settings.PASSWORD_RESET_TOKEN_TTL_MINUTES),
        rid=reset_id,
    )


def decode_token(token: str) -> dict[str, Any]:
    """Decode and validate a JWT. Raises JWTError on failure."""
    return jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])


__all__ = [
    "hash_password",
    "verify_password",
    "hash_token",
    "create_access_token",
    "create_refresh_token",
    "create_password_reset_token",
    "decode_token",
    "JWTError",
    "ACCESS_TOKEN",
    "REFRESH_TOKEN",
    "RESET_TOKEN",
]
