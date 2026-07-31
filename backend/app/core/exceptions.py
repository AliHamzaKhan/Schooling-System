"""Reusable HTTP exceptions."""
from fastapi import HTTPException, status


def credentials_exception() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )


def forbidden(detail: str = "You do not have permission to perform this action") -> HTTPException:
    return HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=detail)


def not_found(detail: str = "Resource not found") -> HTTPException:
    return HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=detail)


def bad_request(detail: str) -> HTTPException:
    return HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)


def payment_required(detail: str = "This school's subscription is not active") -> HTTPException:
    """Subscription lapsed/expired/absent — access blocked until renewed."""
    return HTTPException(status_code=status.HTTP_402_PAYMENT_REQUIRED, detail=detail)
