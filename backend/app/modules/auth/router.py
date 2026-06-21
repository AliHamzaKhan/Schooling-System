"""Auth endpoints: login, refresh, current user."""
from typing import Annotated

from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordRequestForm

from app.core.deps import CurrentUser, DbDep
from app.core.exceptions import credentials_exception
from app.core.security import ACCESS_TOKEN, JWTError, decode_token
from app.modules.auth.schemas import RefreshRequest, TokenPair, UserOut
from app.modules.auth.service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/login", response_model=TokenPair)
async def login(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: DbDep,
) -> TokenPair:
    """OAuth2 password login. `username` is the user's email."""
    service = AuthService(db)
    user = await service.authenticate(form_data.username, form_data.password)
    if user is None:
        raise credentials_exception()
    access, refresh = service.issue_tokens(user)
    return TokenPair(access_token=access, refresh_token=refresh)


@router.post("/refresh", response_model=TokenPair)
async def refresh_token(payload: RefreshRequest, db: DbDep) -> TokenPair:
    try:
        decoded = decode_token(payload.refresh_token)
        if decoded.get("type") == ACCESS_TOKEN:
            raise credentials_exception()
        user_id = decoded.get("sub")
        if not user_id:
            raise credentials_exception()
    except JWTError:
        raise credentials_exception()

    service = AuthService(db)
    user = await service.get_user(user_id)
    if user is None or not user.is_active:
        raise credentials_exception()
    access, refresh = service.issue_tokens(user)
    return TokenPair(access_token=access, refresh_token=refresh)


@router.get("/me", response_model=UserOut)
async def me(current_user: CurrentUser) -> UserOut:
    return current_user
