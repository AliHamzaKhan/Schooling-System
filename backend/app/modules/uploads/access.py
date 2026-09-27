"""Record-based local attachment access. Stored URLs are references, not grants."""
from urllib.parse import urlsplit

from sqlalchemy import select

from app.core.config import settings
from app.core.deps import require_school_permission, verify_student_access
from app.core.enums import Module, PermissionAction as PA, SystemRole
from app.core.exceptions import bad_request, forbidden, not_found
from app.models.academic import Section, TimetableSlot
from app.models.document import StudentDocument
from app.models.fees import Payment
from app.models.homework import Assignment, Submission
from app.modules.permissions.service import PermissionService


async def has_personal_student_access(school_id, student_id, user, db):
    from app.models.associations import guardian_students
    if user.id == student_id:
        return True
    linked = await db.scalar(select(guardian_students.c.student_id).where(
        guardian_students.c.school_id == school_id,
        guardian_students.c.guardian_id == user.id,
        guardian_students.c.student_id == student_id,
    ))
    return linked is not None


def local_key(url: str) -> str:
    try:
        parsed = urlsplit(url)
    except ValueError:
        raise bad_request("Invalid attachment reference")
    base = urlsplit(settings.PUBLIC_BASE_URL)
    if (parsed.scheme or parsed.netloc) and (
        parsed.scheme not in ("http", "https") or
        (parsed.scheme, parsed.netloc) != (base.scheme, base.netloc)
    ):
        raise bad_request("External attachments require migration to managed storage")
    if parsed.query or parsed.fragment or not parsed.path.startswith("/media/"):
        raise bad_request("Invalid attachment reference")
    key = parsed.path[len("/media/"):]
    if any(p in ("", ".", "..") for p in key.split("/")) or "%" in key or "\\" in key:
        raise bad_request("Invalid attachment reference")
    return key


def validate_new_reference(
    url,
    school_id,
    uploader_id,
    folder,
    *,
    existing=None,
    allow_external: bool = True,
):
    """Never let a caller claim someone else's blob through editable metadata.

    Historical references can stay on the same submission, but cannot be newly
    attached. External links remain metadata-only for compatibility (not proxied).
    """
    if not url or url == existing:
        return
    try:
        parsed = urlsplit(url)
    except ValueError:
        raise bad_request("Invalid attachment reference")
    if parsed.scheme in ("http", "https") and not parsed.path.startswith("/media/"):
        if allow_external:
            return
        raise bad_request("Attachment must be a managed upload")
    key = local_key(url)
    prefix = f"private/{folder}/{school_id}/{uploader_id}/"
    if not key.startswith(prefix) or "/" in key[len(prefix):]:
        raise bad_request("Upload a new attachment owned by the current user")


async def require_assignment_staff(school_id, assignment, user, db):
    await require_school_permission(Module.HOMEWORK, PA.EDIT)(school_id, user, db)
    if PermissionService.is_super_admin(user) or any(
        role.code == SystemRole.HEADMASTER.value for role in user.roles
    ) or assignment.assigned_by == user.id:
        return
    section = await db.scalar(select(Section.id).where(
        Section.id == assignment.section_id, Section.school_id == school_id,
        Section.class_teacher_id == user.id,
    ))
    slot = await db.scalar(select(TimetableSlot.id).where(
        TimetableSlot.school_id == school_id,
        TimetableSlot.section_id == assignment.section_id,
        TimetableSlot.subject_id == assignment.subject_id,
        TimetableSlot.teacher_id == user.id,
    ).limit(1))
    if section is None and slot is None:
        raise forbidden("Only staff assigned to this work may access its submissions")


async def authorize_attachment(db, school_id, kind, record_id, user):
    if kind == "documents":
        record = await db.scalar(select(StudentDocument).where(
            StudentDocument.id == record_id, StudentDocument.school_id == school_id,
        ))
        if record is None:
            raise not_found("Attachment not found")
        await verify_student_access(school_id, record.student_id, user, db)
        url, owner = record.file_url, record.uploaded_by
    elif kind == "submissions":
        record = await db.scalar(select(Submission).where(
            Submission.id == record_id, Submission.school_id == school_id,
        ))
        if record is None:
            raise not_found("Attachment not found")
        assignment = await db.scalar(select(Assignment).where(
            Assignment.id == record.assignment_id, Assignment.school_id == school_id,
        ))
        if assignment is None:
            raise not_found("Assignment not found")
        # Self/linked guardian, otherwise the assigned teaching team only.
        if not await has_personal_student_access(school_id, record.student_id, user, db):
            await require_assignment_staff(school_id, assignment, user, db)
        elif Module.HOMEWORK.value not in await PermissionService(db).get_effective_modules(user):
            raise forbidden("Homework is not available")
        url, owner = record.attachment_url, record.student_id
    elif kind == "payment_proofs":
        record = await db.scalar(select(Payment).where(
            Payment.id == record_id, Payment.school_id == school_id,
        ))
        if record is None or not record.proof_url:
            raise not_found("Attachment not found")
        # Bank/cheque evidence can expose account details. It is available to
        # the recorder and school administration only, never through a
        # guardian's ordinary fee-view permission.
        if not (
            user.id == record.recorded_by
            or PermissionService.is_super_admin(user)
            or any(role.code == SystemRole.HEADMASTER.value for role in user.roles)
        ):
            raise forbidden("Only the Headmaster can access payment proof")
        url, owner = record.proof_url, record.recorded_by
    else:
        raise not_found("Attachment kind not found")
    if not url:
        raise not_found("Attachment not found")
    key = local_key(url)
    parts = key.split("/")
    # Existing school-scoped legacy files remain reachable only through records.
    legacy = len(parts) == 3 and parts[:2] == [kind, str(school_id)]
    owned = len(parts) == 5 and parts[:4] == ["private", kind, str(school_id), str(owner)]
    if not (legacy or owned):
        raise forbidden("Attachment ownership does not match its record")
    return key
