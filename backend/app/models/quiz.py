"""Quiz models: quizzes, questions, student attempts and answers.

A quiz is teacher-created coursework (gated by the HOMEWORK module) assigned to
a section for a subject. Objective questions (MCQ / true-false) are auto-graded
on submission; short-answer questions are left for manual grading.
"""
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.enums import AttemptStatus, QuestionType, QuizStatus
from app.models.base import Base, TimestampMixin, UUIDMixin


class Quiz(Base, UUIDMixin, TimestampMixin):
    """A quiz given to a section for a subject."""

    __tablename__ = "quizzes"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    section_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sections.id", ondelete="CASCADE"), nullable=False, index=True
    )
    subject_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    time_limit_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    scheduled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default=QuizStatus.DRAFT.value, nullable=False)
    created_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    questions: Mapped[list["QuizQuestion"]] = relationship(
        back_populates="quiz", cascade="all, delete-orphan", order_by="QuizQuestion.order_index"
    )
    attempts: Mapped[list["QuizAttempt"]] = relationship(
        back_populates="quiz", cascade="all, delete-orphan"
    )
    assignments: Mapped[list["QuizAssignment"]] = relationship(
        back_populates="quiz", cascade="all, delete-orphan"
    )


class QuizAssignment(Base, UUIDMixin, TimestampMixin):
    """Targets a quiz at an individual student.

    A quiz is section-scoped by default (every enrolled student can attempt it).
    When one or more ``QuizAssignment`` rows exist for a quiz, it becomes visible
    only to those specific students instead of the whole section.
    """

    __tablename__ = "quiz_assignments"
    __table_args__ = (
        UniqueConstraint("quiz_id", "student_id", name="uq_quiz_assignment_student"),
    )

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    quiz_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("quizzes.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    quiz: Mapped["Quiz"] = relationship(back_populates="assignments")


class QuizQuestion(Base, UUIDMixin, TimestampMixin):
    """A single question within a quiz."""

    __tablename__ = "quiz_questions"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    quiz_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("quizzes.id", ondelete="CASCADE"), nullable=False, index=True
    )
    prompt: Mapped[str] = mapped_column(Text, nullable=False)
    question_type: Mapped[str] = mapped_column(String(20), default=QuestionType.MCQ.value, nullable=False)
    # For MCQ: list of option strings. Null for true/false and short.
    options: Mapped[list | None] = mapped_column(JSONB, nullable=True)
    # Expected answer used for auto-grading. For MCQ this is the correct option
    # text; for true/false "true"/"false"; for short questions this is the
    # reference answer (not auto-compared).
    correct_answer: Mapped[str | None] = mapped_column(Text, nullable=True)
    marks: Mapped[float] = mapped_column(Float, default=1.0, nullable=False)
    order_index: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    quiz: Mapped["Quiz"] = relationship(back_populates="questions")


class QuizAttempt(Base, UUIDMixin, TimestampMixin):
    """A student's attempt at a quiz."""

    __tablename__ = "quiz_attempts"
    __table_args__ = (
        UniqueConstraint("quiz_id", "student_id", name="uq_quiz_attempt_student"),
    )

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    quiz_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("quizzes.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    submitted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    score: Mapped[float | None] = mapped_column(Float, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default=AttemptStatus.IN_PROGRESS.value, nullable=False)
    graded_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    quiz: Mapped["Quiz"] = relationship(back_populates="attempts")
    answers: Mapped[list["QuizAnswer"]] = relationship(
        back_populates="attempt", cascade="all, delete-orphan"
    )


class QuizAnswer(Base, UUIDMixin, TimestampMixin):
    """A student's answer to a single question within an attempt."""

    __tablename__ = "quiz_answers"
    __table_args__ = (
        UniqueConstraint("attempt_id", "question_id", name="uq_quiz_answer_attempt_question"),
    )

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    attempt_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("quiz_attempts.id", ondelete="CASCADE"), nullable=False, index=True
    )
    question_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("quiz_questions.id", ondelete="CASCADE"), nullable=False
    )
    response: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_correct: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    marks_awarded: Mapped[float | None] = mapped_column(Float, nullable=True)

    attempt: Mapped["QuizAttempt"] = relationship(back_populates="answers")
