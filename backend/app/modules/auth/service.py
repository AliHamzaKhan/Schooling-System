"""Authentication service: credential verification and token issuance."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.security import (
    create_access_token,
    create_refresh_token,
    verify_password,
)
from app.models.role import Role
from app.models.user import User


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

    @staticmethod
    def issue_tokens(user: User) -> tuple[str, str]:
        subject = str(user.id)
        return create_access_token(subject), create_refresh_token(subject)
