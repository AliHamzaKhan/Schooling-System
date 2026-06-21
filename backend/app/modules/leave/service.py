"""Leave Management Service."""
import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import bad_request, not_found
from app.models.leave import LeaveRequest
from app.modules.leave import schemas


class LeaveService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def submit(self, school_id: uuid.UUID, requester_id: uuid.UUID, data: schemas.LeaveSubmit) -> LeaveRequest:
        leave = LeaveRequest(
            school_id=school_id,
            requester_id=requester_id,
            leave_type=data.leave_type,
            start_date=data.start_date,
            end_date=data.end_date,
            reason=data.reason,
            status="pending",
        )
        self.db.add(leave)
        await self.db.flush()
        return leave

    async def _get(self, school_id: uuid.UUID, leave_id: uuid.UUID) -> LeaveRequest:
        leave = await self.db.get(LeaveRequest, leave_id)
        if leave is None or leave.school_id != school_id:
            raise not_found("Leave request not found in this school")
        return leave

    async def list_own(self, school_id: uuid.UUID, requester_id: uuid.UUID) -> list[LeaveRequest]:
        result = await self.db.execute(
            select(LeaveRequest).where(
                LeaveRequest.school_id == school_id, LeaveRequest.requester_id == requester_id
            ).order_by(LeaveRequest.created_at.desc())
        )
        return list(result.scalars().all())

    async def list_all(self, school_id: uuid.UUID, status: str | None = None) -> list[LeaveRequest]:
        stmt = select(LeaveRequest).where(LeaveRequest.school_id == school_id)
        if status is not None:
            stmt = stmt.where(LeaveRequest.status == status)
        stmt = stmt.order_by(LeaveRequest.created_at.desc())
        return list((await self.db.execute(stmt)).scalars().all())

    async def review(self, school_id: uuid.UUID, leave_id: uuid.UUID, approve: bool, reviewer_id: uuid.UUID, note: str | None) -> LeaveRequest:
        leave = await self._get(school_id, leave_id)
        if leave.status != "pending":
            raise bad_request(f"Leave request is already {leave.status}")
        leave.status = "approved" if approve else "rejected"
        leave.reviewed_by = reviewer_id
        leave.review_note = note
        leave.reviewed_at = datetime.now(timezone.utc)
        await self.db.flush()
        return leave
