"""Reusable HTTP exceptions.

Every deliberate error carries a machine-readable :class:`ErrorCode` alongside
its human message. The code travels to the client in the response envelope
(``{"error": {"code", "message"}}`` — see ``app/core/errors.py``) so the
frontend can react *precisely*: a lapsed subscription or a disabled tenant must
force a logout, whereas an ordinary "missing permission" denial must not. HTTP
status alone can't tell those apart (both are 403), so the code does.
"""
from enum import Enum

from fastapi import HTTPException, status


class ErrorCode(str, Enum):
    """Stable identifiers for deliberate failures. Values are the strings sent
    to the client as ``error.code``; keep them in sync with the frontend's
    session-fatal set (``ApiResponse.isSessionFatal``)."""

    # Session-fatal — the frontend clears the session and returns to login.
    INVALID_CREDENTIALS = "invalid_credentials"  # 401: bad/expired/absent token
    ACCOUNT_INACTIVE = "account_inactive"  # 403: caller's account deactivated
    TENANT_MISMATCH = "tenant_mismatch"  # 403: cross-tenant access attempt
    TENANT_NOT_FOUND = "tenant_not_found"  # 404: school id resolves to nothing
    TENANT_DISABLED = "tenant_disabled"  # 403: school pending/suspended
    SUBSCRIPTION_INACTIVE = "subscription_inactive"  # 402: expired/cancelled

    # Not session-fatal — surfaced to the user, session left intact.
    PERMISSION_DENIED = "permission_denied"  # 403: authenticated but not allowed
    NOT_FOUND = "not_found"  # 404: ordinary missing resource
    BAD_REQUEST = "bad_request"  # 400: validation / bad input
    CONFLICT = "conflict"  # 409: state conflict
    RATE_LIMITED = "rate_limited"  # 429: too many requests for this key


class AppHTTPException(HTTPException):
    """An :class:`HTTPException` that also carries an :class:`ErrorCode`.

    Behaves exactly like ``HTTPException`` for FastAPI's routing/status handling;
    the extra ``code`` is picked up by the envelope handler in ``errors.py``.
    """

    def __init__(self, status_code: int, detail: str, code: ErrorCode, headers: dict | None = None):
        super().__init__(status_code=status_code, detail=detail, headers=headers)
        self.code = code


def credentials_exception() -> AppHTTPException:
    return AppHTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        code=ErrorCode.INVALID_CREDENTIALS,
        headers={"WWW-Authenticate": "Bearer"},
    )


def forbidden(
    detail: str = "You do not have permission to perform this action",
    code: ErrorCode = ErrorCode.PERMISSION_DENIED,
) -> AppHTTPException:
    """A 403. Defaults to the *non*-fatal ``permission_denied`` code; pass a
    specific tenant/account code (e.g. [ErrorCode.TENANT_MISMATCH]) when the
    denial should force the client to re-authenticate."""
    return AppHTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=detail, code=code)


def not_found(
    detail: str = "Resource not found", code: ErrorCode = ErrorCode.NOT_FOUND
) -> AppHTTPException:
    return AppHTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=detail, code=code)


def bad_request(detail: str, code: ErrorCode = ErrorCode.BAD_REQUEST) -> AppHTTPException:
    return AppHTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=detail, code=code)


def payment_required(
    detail: str = "This school's subscription is not active",
    code: ErrorCode = ErrorCode.SUBSCRIPTION_INACTIVE,
) -> AppHTTPException:
    """Subscription lapsed/expired/absent — access blocked until renewed."""
    return AppHTTPException(status_code=status.HTTP_402_PAYMENT_REQUIRED, detail=detail, code=code)
