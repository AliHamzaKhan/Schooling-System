"""Auth endpoints: login, refresh, logout, password reset, current user."""
import logging
from typing import Annotated

from fastapi import APIRouter, Depends, Request, Response, status
from fastapi.security import OAuth2PasswordRequestForm
from slowapi.util import get_remote_address

from app.core.config import settings
from app.core.deps import CurrentUser, DbDep
from app.core.enums import Channel
from app.core.exceptions import credentials_exception
from app.core.ratelimit import AUTH_LIMIT, SENSITIVE_LIMIT, limiter
from app.modules.auth.schemas import (
    ChangePasswordRequest,
    ForgotPasswordRequest,
    MessageOut,
    RefreshRequest,
    ResetPasswordRequest,
    ResetTokenOut,
    TokenPair,
    UserOut,
    VerifyOtpRequest,
)
from app.modules.auth.service import AuthService
from app.modules.communication.providers import notifier

logger = logging.getLogger("app.auth")

router = APIRouter(prefix="/auth", tags=["Authentication"])

# Account creation is not a public endpoint: users are provisioned by their
# school (create-headmaster / create student|teacher|guardian), so there is no
# self-service `/register` to rate-limit here.

# A single neutral acknowledgement for the reset endpoints — deliberately the
# same whether or not the email is registered, so the flow can't be used to
# enumerate accounts.
_RESET_ACK = MessageOut(
    message="If an account exists and email delivery is available, check your inbox for a reset code."
)


@router.post("/login", response_model=TokenPair)
@limiter.limit(AUTH_LIMIT)
async def login(
    request: Request,
    response: Response,
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: DbDep,
) -> TokenPair:
    """OAuth2 password login. `username` is the user's email.

    Rate-limited per client IP to blunt brute-force / credential-stuffing.
    Opens a server-side refresh session so the login can later be revoked.
    """
    service = AuthService(db)
    user = await service.authenticate(form_data.username, form_data.password)
    if user is None:
        raise credentials_exception()
    access, refresh = await service.start_session(
        user,
        user_agent=request.headers.get("user-agent"),
        ip=get_remote_address(request),
    )
    return TokenPair(access_token=access, refresh_token=refresh)


@router.post("/refresh", response_model=TokenPair)
@limiter.limit("20/minute")
async def refresh_token(request: Request, response: Response, payload: RefreshRequest, db: DbDep) -> TokenPair:
    """Rotate a refresh token. The presented token is invalidated and a new
    access/refresh pair is issued; replaying a rotated token revokes the session.
    """
    access, refresh = await AuthService(db).rotate_session(payload.refresh_token)
    return TokenPair(access_token=access, refresh_token=refresh)


@router.post("/forgot-password", response_model=MessageOut)
@limiter.limit(SENSITIVE_LIMIT)
async def forgot_password(
    request: Request, response: Response, payload: ForgotPasswordRequest, db: DbDep
) -> MessageOut:
    """Send a one-time reset code to the account's email, if it exists.

    Always returns the same neutral acknowledgement so it can't be used to tell
    which emails are registered. Strictly rate-limited (OTP endpoints are a
    prime abuse target).
    """
    code = await AuthService(db).request_password_reset(payload.email)
    if code is not None:
        # One transactional email — not a fan-out — so it's sent inline. In dev
        # (no SMTP configured) the notifier records only a content-free stub log.
        try:
            await notifier.dispatch(
                Channel.EMAIL.value,
                payload.email,
                "Your password reset code",
                f"Your password reset code is {code}. It expires in "
                f"{settings.PASSWORD_RESET_OTP_TTL_MINUTES} minutes. "
                f"If you didn't request this, you can ignore this email.",
            )
        except Exception:  # delivery failure must not leak (or 500) the request
            logger.exception("Failed to send password-reset email")
    return _RESET_ACK


@router.post("/verify-otp", response_model=ResetTokenOut)
@limiter.limit(SENSITIVE_LIMIT)
async def verify_otp(
    request: Request, response: Response, payload: VerifyOtpRequest, db: DbDep
) -> ResetTokenOut:
    """Exchange a valid OTP for a short-lived token authorizing the password
    change. Wrong/expired codes all return the same generic 400."""
    token = await AuthService(db).verify_reset_otp(payload.email, payload.code)
    return ResetTokenOut(reset_token=token)


@router.post("/reset-password", response_model=MessageOut)
@limiter.limit(SENSITIVE_LIMIT)
async def reset_password(
    request: Request, response: Response, payload: ResetPasswordRequest, db: DbDep
) -> MessageOut:
    """Set a new password using the token from /verify-otp. Signs the user out of
    all existing sessions."""
    await AuthService(db).reset_password(payload.token, payload.new_password)
    return MessageOut(message="Your password has been reset. Please sign in.")


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(payload: RefreshRequest, db: DbDep) -> Response:
    """Revoke the session behind this refresh token. Idempotent."""
    await AuthService(db).revoke_session(payload.refresh_token)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/logout-all", status_code=status.HTTP_204_NO_CONTENT)
async def logout_all(current_user: CurrentUser, db: DbDep) -> Response:
    """Revoke every active session for the authenticated user (all devices)."""
    await AuthService(db).revoke_all_for_user(current_user.id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/change-password", response_model=MessageOut)
@limiter.limit(SENSITIVE_LIMIT)
async def change_password(
    request: Request,
    response: Response,
    payload: ChangePasswordRequest,
    current_user: CurrentUser,
    db: DbDep,
) -> MessageOut:
    """Change the signed-in user's own password (requires the current one).
    Signs the user out of all sessions, including the current one."""
    await AuthService(db).change_password(
        current_user, payload.current_password, payload.new_password
    )
    return MessageOut(message="Your password has been changed.")


@router.get("/me", response_model=UserOut)
async def me(current_user: CurrentUser) -> UserOut:
    return current_user
