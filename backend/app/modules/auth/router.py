"""Auth endpoints: login, refresh, logout, current user."""
from typing import Annotated

from fastapi import APIRouter, Depends, Request, Response, status
from fastapi.security import OAuth2PasswordRequestForm
from slowapi.util import get_remote_address

from app.core.deps import CurrentUser, DbDep
from app.core.exceptions import credentials_exception
from app.core.ratelimit import limiter
from app.modules.auth.schemas import RefreshRequest, TokenPair, UserOut
from app.modules.auth.service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/login", response_model=TokenPair)
@limiter.limit("10/minute")
async def login(
    request: Request,
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
async def refresh_token(request: Request, payload: RefreshRequest, db: DbDep) -> TokenPair:
    """Rotate a refresh token. The presented token is invalidated and a new
    access/refresh pair is issued; replaying a rotated token revokes the session.
    """
    access, refresh = await AuthService(db).rotate_session(payload.refresh_token)
    return TokenPair(access_token=access, refresh_token=refresh)


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


@router.get("/me", response_model=UserOut)
async def me(current_user: CurrentUser) -> UserOut:
    return current_user
