"""Course content service: courses, books, chapters, notes, reading progress."""
import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import EnrollmentStatus
from app.core.exceptions import bad_request, not_found
from app.models.academic import Section, SchoolClass, StudentEnrollment, Subject
from app.models.course import (
    BookChapter,
    Course,
    CourseBook,
    CourseNote,
    ReadingProgress,
)
from app.modules.courses import schemas


class CourseService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------ helpers ------------------------------ #

    async def _get_scoped(self, model, school_id: uuid.UUID, obj_id: uuid.UUID, label: str):
        obj = await self.db.get(model, obj_id)
        if obj is None or obj.school_id != school_id:
            raise not_found(f"{label} not found in this school")
        return obj

    async def _validate_course_links(
        self,
        school_id: uuid.UUID,
        section_id: uuid.UUID | None,
        subject_id: uuid.UUID | None,
    ) -> None:
        """Ensure a course cannot point at another school's academic catalog."""
        section = (
            await self._get_scoped(Section, school_id, section_id, "Section")
            if section_id is not None
            else None
        )
        subject = (
            await self._get_scoped(Subject, school_id, subject_id, "Subject")
            if subject_id is not None
            else None
        )
        if (
            section is not None
            and subject is not None
            and subject.class_id is not None
            and subject.class_id != section.class_id
        ):
            raise bad_request("Subject does not belong to the course section's class")

    async def _require_course_access(
        self, school_id: uuid.UUID, course: Course, student_id: uuid.UUID | None
    ) -> None:
        """Restrict a student's section-scoped material to active enrolments."""
        if student_id is None or course.section_id is None:
            return
        enrollment = await self.db.scalar(
            select(StudentEnrollment.id).where(
                StudentEnrollment.school_id == school_id,
                StudentEnrollment.student_id == student_id,
                StudentEnrollment.section_id == course.section_id,
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
            )
        )
        if enrollment is None:
            raise not_found("Course not found in this school")

    async def _course_for_book(
        self, school_id: uuid.UUID, book: CourseBook, student_id: uuid.UUID | None
    ) -> Course:
        course = await self._get_scoped(Course, school_id, book.course_id, "Course")
        await self._require_course_access(school_id, course, student_id)
        return course

    async def _course_for_note(
        self, school_id: uuid.UUID, note: CourseNote, student_id: uuid.UUID | None
    ) -> Course:
        course = await self._get_scoped(Course, school_id, note.course_id, "Course")
        await self._require_course_access(school_id, course, student_id)
        return course

    # ------------------------------ courses ------------------------------ #

    async def create_course(
        self, school_id: uuid.UUID, data: schemas.CourseCreate, created_by: uuid.UUID
    ) -> Course:
        await self._validate_course_links(school_id, data.section_id, data.subject_id)
        course = Course(
            school_id=school_id,
            title=data.title,
            description=data.description,
            subject=data.subject,
            cover_url=data.cover_url,
            section_id=data.section_id,
            subject_id=data.subject_id,
            created_by=created_by,
        )
        self.db.add(course)
        await self.db.flush()
        return course

    async def update_course(
        self, school_id: uuid.UUID, course_id: uuid.UUID, data: schemas.CourseUpdate
    ) -> Course:
        course = await self._get_scoped(Course, school_id, course_id, "Course")
        fields = data.model_fields_set
        section_id = data.section_id if "section_id" in fields else course.section_id
        subject_id = data.subject_id if "subject_id" in fields else course.subject_id
        await self._validate_course_links(school_id, section_id, subject_id)
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(course, field, value)
        await self.db.flush()
        return course

    async def delete_course(self, school_id: uuid.UUID, course_id: uuid.UUID) -> None:
        course = await self._get_scoped(Course, school_id, course_id, "Course")
        await self.db.delete(course)
        await self.db.flush()

    async def list_courses(
        self,
        school_id: uuid.UUID,
        section_id: uuid.UUID | None = None,
        student_id: uuid.UUID | None = None,
    ) -> list[schemas.CourseListOut]:
        """Active courses in the school.

        ``section_id`` narrows to one class+section. ``student_id`` scopes the
        result to the sections that student is enrolled in (plus any legacy
        school-wide courses with no section), so students only see courses
        offered to their own class+section.
        """
        stmt = (
            select(Course)
            .where(Course.school_id == school_id, Course.is_active.is_(True))
            .order_by(Course.title)
        )
        if section_id is not None:
            stmt = stmt.where(Course.section_id == section_id)
        if student_id is not None:
            enrolled = (
                select(StudentEnrollment.section_id).where(
                    StudentEnrollment.school_id == school_id,
                    StudentEnrollment.student_id == student_id,
                    StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
                )
            ).scalar_subquery()
            # Their sections' courses, plus unscoped (legacy) courses.
            stmt = stmt.where(
                Course.section_id.in_(enrolled) | Course.section_id.is_(None)
            )
        courses = list((await self.db.execute(stmt)).scalars().all())
        if not courses:
            return []
        ids = [c.id for c in courses]
        # Resolve class/section/subject display names in one pass each.
        section_ids = {c.section_id for c in courses if c.section_id is not None}
        subject_ids = {c.subject_id for c in courses if c.subject_id is not None}
        section_info: dict[uuid.UUID, tuple[str, str]] = {}
        if section_ids:
            rows = (
                await self.db.execute(
                    select(Section.id, Section.name, SchoolClass.name)
                    .join(SchoolClass, Section.class_id == SchoolClass.id)
                    .where(Section.id.in_(section_ids))
                )
            ).all()
            section_info = {r[0]: (r[2], r[1]) for r in rows}  # id -> (class, section)
        subject_names: dict[uuid.UUID, str] = {}
        if subject_ids:
            subject_names = dict(
                (
                    await self.db.execute(
                        select(Subject.id, Subject.name).where(Subject.id.in_(subject_ids))
                    )
                ).all()
            )
        book_counts = dict(
            (
                await self.db.execute(
                    select(CourseBook.course_id, func.count())
                    .where(CourseBook.course_id.in_(ids))
                    .group_by(CourseBook.course_id)
                )
            ).all()
        )
        note_counts = dict(
            (
                await self.db.execute(
                    select(CourseNote.course_id, func.count())
                    .where(CourseNote.course_id.in_(ids))
                    .group_by(CourseNote.course_id)
                )
            ).all()
        )
        return [
            schemas.CourseListOut(
                id=c.id,
                school_id=c.school_id,
                title=c.title,
                description=c.description,
                subject=c.subject,
                cover_url=c.cover_url,
                is_active=c.is_active,
                section_id=c.section_id,
                subject_id=c.subject_id,
                class_name=section_info.get(c.section_id, (None, None))[0]
                if c.section_id
                else None,
                section_name=section_info.get(c.section_id, (None, None))[1]
                if c.section_id
                else None,
                subject_name=subject_names.get(c.subject_id) if c.subject_id else None,
                book_count=int(book_counts.get(c.id, 0)),
                note_count=int(note_counts.get(c.id, 0)),
            )
            for c in courses
        ]

    async def get_course(
        self, school_id: uuid.UUID, course_id: uuid.UUID, student_id: uuid.UUID | None = None
    ) -> Course:
        course = await self._get_scoped(Course, school_id, course_id, "Course")
        await self._require_course_access(school_id, course, student_id)
        return course

    # ------------------------------- books ------------------------------- #

    async def add_book(
        self, school_id: uuid.UUID, course_id: uuid.UUID, data: schemas.BookCreate
    ) -> CourseBook:
        await self._get_scoped(Course, school_id, course_id, "Course")
        book = CourseBook(
            school_id=school_id,
            course_id=course_id,
            title=data.title,
            description=data.description,
            order_index=data.order_index,
        )
        self.db.add(book)
        await self.db.flush()
        return book

    async def list_books(
        self, school_id: uuid.UUID, course_id: uuid.UUID, student_id: uuid.UUID | None = None
    ) -> list[schemas.BookListOut]:
        await self.get_course(school_id, course_id, student_id)
        books = list(
            (
                await self.db.execute(
                    select(CourseBook)
                    .where(CourseBook.course_id == course_id)
                    .order_by(CourseBook.order_index, CourseBook.title)
                )
            ).scalars().all()
        )
        if not books:
            return []
        counts = dict(
            (
                await self.db.execute(
                    select(BookChapter.book_id, func.count())
                    .where(BookChapter.book_id.in_([b.id for b in books]))
                    .group_by(BookChapter.book_id)
                )
            ).all()
        )
        return [
            schemas.BookListOut(
                id=b.id,
                course_id=b.course_id,
                title=b.title,
                description=b.description,
                order_index=b.order_index,
                chapter_count=int(counts.get(b.id, 0)),
            )
            for b in books
        ]

    # ------------------------------ chapters ----------------------------- #

    async def add_chapter(
        self, school_id: uuid.UUID, book_id: uuid.UUID, data: schemas.ChapterCreate
    ) -> BookChapter:
        await self._get_scoped(CourseBook, school_id, book_id, "Book")
        chapter = BookChapter(
            school_id=school_id,
            book_id=book_id,
            title=data.title,
            content=data.content,
            order_index=data.order_index,
        )
        self.db.add(chapter)
        await self.db.flush()
        return chapter

    async def list_chapters(
        self, school_id: uuid.UUID, book_id: uuid.UUID, student_id: uuid.UUID | None = None
    ) -> list[BookChapter]:
        book = await self._get_scoped(CourseBook, school_id, book_id, "Book")
        await self._course_for_book(school_id, book, student_id)
        return list(
            (
                await self.db.execute(
                    select(BookChapter)
                    .where(BookChapter.book_id == book_id)
                    .order_by(BookChapter.order_index, BookChapter.title)
                )
            ).scalars().all()
        )

    async def get_chapter(
        self, school_id: uuid.UUID, chapter_id: uuid.UUID, student_id: uuid.UUID | None = None
    ) -> BookChapter:
        chapter = await self._get_scoped(BookChapter, school_id, chapter_id, "Chapter")
        book = await self._get_scoped(CourseBook, school_id, chapter.book_id, "Book")
        await self._course_for_book(school_id, book, student_id)
        return chapter

    # ------------------------------- notes ------------------------------- #

    async def add_note(
        self, school_id: uuid.UUID, course_id: uuid.UUID, data: schemas.NoteCreate
    ) -> CourseNote:
        await self._get_scoped(Course, school_id, course_id, "Course")
        note = CourseNote(
            school_id=school_id,
            course_id=course_id,
            title=data.title,
            content=data.content,
            order_index=data.order_index,
        )
        self.db.add(note)
        await self.db.flush()
        return note

    async def list_notes(
        self, school_id: uuid.UUID, course_id: uuid.UUID, student_id: uuid.UUID | None = None
    ) -> list[CourseNote]:
        await self.get_course(school_id, course_id, student_id)
        return list(
            (
                await self.db.execute(
                    select(CourseNote)
                    .where(CourseNote.course_id == course_id)
                    .order_by(CourseNote.order_index, CourseNote.title)
                )
            ).scalars().all()
        )

    async def get_note(
        self, school_id: uuid.UUID, note_id: uuid.UUID, student_id: uuid.UUID | None = None
    ) -> CourseNote:
        note = await self._get_scoped(CourseNote, school_id, note_id, "Note")
        await self._course_for_note(school_id, note, student_id)
        return note

    async def _progress_resource_course(
        self, school_id: uuid.UUID, resource_type: str, resource_id: uuid.UUID
    ) -> Course:
        if resource_type == "book":
            book = await self._get_scoped(CourseBook, school_id, resource_id, "Book")
            return await self._get_scoped(Course, school_id, book.course_id, "Course")
        note = await self._get_scoped(CourseNote, school_id, resource_id, "Note")
        return await self._get_scoped(Course, school_id, note.course_id, "Course")

    # --------------------------- reading progress ------------------------ #

    async def get_progress(
        self,
        school_id: uuid.UUID,
        user_id: uuid.UUID,
        resource_type: str,
        resource_id: uuid.UUID,
        student_id: uuid.UUID | None = None,
    ) -> ReadingProgress | None:
        course = await self._progress_resource_course(school_id, resource_type, resource_id)
        await self._require_course_access(school_id, course, student_id)
        return await self.db.scalar(
            select(ReadingProgress).where(
                ReadingProgress.school_id == school_id,
                ReadingProgress.user_id == user_id,
                ReadingProgress.resource_type == resource_type,
                ReadingProgress.resource_id == resource_id,
            )
        )

    async def set_progress(
        self,
        school_id: uuid.UUID,
        user_id: uuid.UUID,
        data: schemas.ReadingProgressSet,
        student_id: uuid.UUID | None = None,
    ) -> ReadingProgress:
        course = await self._progress_resource_course(
            school_id, data.resource_type, data.resource_id
        )
        await self._require_course_access(school_id, course, student_id)
        existing = await self.get_progress(
            school_id, user_id, data.resource_type, data.resource_id, student_id
        )
        if existing is not None:
            existing.chapter_id = data.chapter_id
            existing.page = data.page
            await self.db.flush()
            return existing
        progress = ReadingProgress(
            school_id=school_id,
            user_id=user_id,
            resource_type=data.resource_type,
            resource_id=data.resource_id,
            chapter_id=data.chapter_id,
            page=data.page,
        )
        self.db.add(progress)
        await self.db.flush()
        return progress
