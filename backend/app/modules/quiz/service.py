"""Quiz service: authoring, student attempts, auto/manual grading, reports."""
import json
import uuid
from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.enums import (
    AttemptStatus,
    EnrollmentStatus,
    QuestionType,
    QuizStatus,
)
from app.core.exceptions import bad_request, forbidden, not_found
from app.models.academic import Section, StudentEnrollment, Subject
from app.models.quiz import Quiz, QuizAnswer, QuizAssignment, QuizAttempt, QuizQuestion
from app.models.user import User
from app.modules.ai.providers import ai_provider
from app.modules.quiz import schemas


def _now() -> datetime:
    return datetime.now(timezone.utc)


class QuizService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------ helpers ------------------------------ #

    async def _get_scoped(self, model, school_id: uuid.UUID, obj_id: uuid.UUID, label: str):
        obj = await self.db.get(model, obj_id)
        if obj is None or obj.school_id != school_id:
            raise not_found(f"{label} not found in this school")
        return obj

    async def _is_enrolled(self, section_id: uuid.UUID, student_id: uuid.UUID) -> bool:
        row = await self.db.scalar(
            select(StudentEnrollment).where(
                StudentEnrollment.section_id == section_id,
                StudentEnrollment.student_id == student_id,
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
            )
        )
        return row is not None

    async def _enrolled_student_ids(self, section_id: uuid.UUID) -> list[uuid.UUID]:
        rows = await self.db.execute(
            select(StudentEnrollment.student_id).where(
                StudentEnrollment.section_id == section_id,
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
            )
        )
        return [r[0] for r in rows.all()]

    async def _assignee_ids(self, quiz_id: uuid.UUID) -> set[uuid.UUID]:
        rows = await self.db.execute(
            select(QuizAssignment.student_id).where(QuizAssignment.quiz_id == quiz_id)
        )
        return {r[0] for r in rows.all()}

    async def _set_assignees(
        self, school_id: uuid.UUID, quiz: Quiz, student_ids: list[uuid.UUID]
    ) -> None:
        """Replace a quiz's targeted students (validating each is enrolled)."""
        enrolled = set(await self._enrolled_student_ids(quiz.section_id))
        wanted = list(dict.fromkeys(student_ids))  # de-dupe, keep order
        for sid in wanted:
            if sid not in enrolled:
                raise bad_request("Every assignee must be enrolled in the quiz's section")
        # Clear existing then re-add.
        existing = await self.db.execute(
            select(QuizAssignment).where(QuizAssignment.quiz_id == quiz.id)
        )
        for row in existing.scalars().all():
            await self.db.delete(row)
        await self.db.flush()
        for sid in wanted:
            self.db.add(
                QuizAssignment(school_id=school_id, quiz_id=quiz.id, student_id=sid)
            )
        await self.db.flush()

    async def _can_attempt(self, quiz: Quiz, student_id: uuid.UUID) -> bool:
        """A student may attempt when explicitly assigned, or — if the quiz has no
        explicit assignees — when enrolled in its section."""
        assignees = await self._assignee_ids(quiz.id)
        if assignees:
            return student_id in assignees
        return await self._is_enrolled(quiz.section_id, student_id)

    # ------------------------------ quizzes ------------------------------ #

    async def create_quiz(
        self, school_id: uuid.UUID, data: schemas.QuizCreate, created_by: uuid.UUID
    ) -> Quiz:
        await self._get_scoped(Section, school_id, data.section_id, "Section")
        await self._get_scoped(Subject, school_id, data.subject_id, "Subject")
        quiz = Quiz(
            school_id=school_id,
            section_id=data.section_id,
            subject_id=data.subject_id,
            title=data.title,
            description=data.description,
            time_limit_minutes=data.time_limit_minutes,
            scheduled_at=data.scheduled_at,
            due_at=data.due_at,
            status=QuizStatus.DRAFT.value,
            created_by=created_by,
        )
        self.db.add(quiz)
        await self.db.flush()
        if data.assignee_ids:
            await self._set_assignees(school_id, quiz, data.assignee_ids)
        return quiz

    async def list_quizzes(
        self, school_id: uuid.UUID, section_id: uuid.UUID | None = None
    ) -> list[Quiz]:
        stmt = select(Quiz).where(Quiz.school_id == school_id)
        if section_id is not None:
            stmt = stmt.where(Quiz.section_id == section_id)
        stmt = stmt.order_by(Quiz.created_at.desc())
        return list((await self.db.execute(stmt)).scalars().all())

    async def get_quiz(self, school_id: uuid.UUID, quiz_id: uuid.UUID) -> Quiz:
        quiz = await self.db.scalar(
            select(Quiz)
            .where(Quiz.id == quiz_id, Quiz.school_id == school_id)
            .options(selectinload(Quiz.questions))
        )
        if quiz is None:
            raise not_found("Quiz not found in this school")
        return quiz

    async def update_quiz(
        self, school_id: uuid.UUID, quiz_id: uuid.UUID, data: schemas.QuizUpdate
    ) -> Quiz:
        quiz = await self._get_scoped(Quiz, school_id, quiz_id, "Quiz")
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(quiz, field, value)
        await self.db.flush()
        return quiz

    async def delete_quiz(self, school_id: uuid.UUID, quiz_id: uuid.UUID) -> None:
        quiz = await self._get_scoped(Quiz, school_id, quiz_id, "Quiz")
        await self.db.delete(quiz)
        await self.db.flush()

    async def set_status(
        self, school_id: uuid.UUID, quiz_id: uuid.UUID, status: QuizStatus
    ) -> Quiz:
        quiz = await self._get_scoped(Quiz, school_id, quiz_id, "Quiz")
        if status == QuizStatus.PUBLISHED:
            has_question = await self.db.scalar(
                select(QuizQuestion.id).where(QuizQuestion.quiz_id == quiz_id).limit(1)
            )
            if has_question is None:
                raise bad_request("Cannot publish a quiz with no questions")
        quiz.status = status.value
        await self.db.flush()
        return quiz

    # ----------------------------- questions ----------------------------- #

    def _validate_question(self, data: schemas.QuestionCreate | schemas.QuestionUpdate, qtype: str) -> None:
        if qtype == QuestionType.MCQ.value:
            if not data.options or len(data.options) < 2:
                raise bad_request("MCQ questions require at least two options")
            if data.correct_answer is not None and data.correct_answer not in data.options:
                raise bad_request("correct_answer must be one of the provided options")
        if qtype == QuestionType.TRUE_FALSE.value and data.correct_answer is not None:
            if data.correct_answer.strip().lower() not in {"true", "false"}:
                raise bad_request("true_false correct_answer must be 'true' or 'false'")

    async def add_question(
        self, school_id: uuid.UUID, quiz_id: uuid.UUID, data: schemas.QuestionCreate
    ) -> QuizQuestion:
        await self._get_scoped(Quiz, school_id, quiz_id, "Quiz")
        self._validate_question(data, data.question_type.value)
        question = QuizQuestion(
            school_id=school_id,
            quiz_id=quiz_id,
            prompt=data.prompt,
            question_type=data.question_type.value,
            options=data.options,
            correct_answer=data.correct_answer,
            marks=data.marks,
            order_index=data.order_index,
        )
        self.db.add(question)
        await self.db.flush()
        return question

    async def update_question(
        self, school_id: uuid.UUID, question_id: uuid.UUID, data: schemas.QuestionUpdate
    ) -> QuizQuestion:
        question = await self._get_scoped(QuizQuestion, school_id, question_id, "Question")
        payload = data.model_dump(exclude_unset=True)
        if "question_type" in payload and data.question_type is not None:
            payload["question_type"] = data.question_type.value
        qtype = payload.get("question_type", question.question_type)
        # Validate using effective values.
        merged = schemas.QuestionCreate(
            prompt=payload.get("prompt", question.prompt),
            question_type=QuestionType(qtype),
            options=payload.get("options", question.options),
            correct_answer=payload.get("correct_answer", question.correct_answer),
        )
        self._validate_question(merged, qtype)
        for field, value in payload.items():
            setattr(question, field, value)
        await self.db.flush()
        return question

    async def delete_question(self, school_id: uuid.UUID, question_id: uuid.UUID) -> None:
        question = await self._get_scoped(QuizQuestion, school_id, question_id, "Question")
        await self.db.delete(question)
        await self.db.flush()

    # ------------------------------ attempts ----------------------------- #

    async def start_attempt(
        self, school_id: uuid.UUID, quiz_id: uuid.UUID, student_id: uuid.UUID
    ) -> QuizAttempt:
        quiz = await self._get_scoped(Quiz, school_id, quiz_id, "Quiz")
        if quiz.status != QuizStatus.PUBLISHED.value:
            raise bad_request("This quiz is not open for attempts")
        if not await self._can_attempt(quiz, student_id):
            raise forbidden("This quiz is not assigned to you")
        existing = await self.db.scalar(
            select(QuizAttempt).where(
                QuizAttempt.quiz_id == quiz_id, QuizAttempt.student_id == student_id
            )
        )
        if existing is not None:
            return existing
        attempt = QuizAttempt(
            school_id=school_id,
            quiz_id=quiz_id,
            student_id=student_id,
            started_at=_now(),
            status=AttemptStatus.IN_PROGRESS.value,
        )
        self.db.add(attempt)
        await self.db.flush()
        return attempt

    async def submit_attempt(
        self,
        school_id: uuid.UUID,
        quiz_id: uuid.UUID,
        student_id: uuid.UUID,
        data: schemas.AttemptSubmit,
    ) -> QuizAttempt:
        quiz = await self.get_quiz(school_id, quiz_id)
        if not await self._can_attempt(quiz, student_id):
            raise forbidden("This quiz is not assigned to you")

        attempt = await self.db.scalar(
            select(QuizAttempt)
            .where(QuizAttempt.quiz_id == quiz_id, QuizAttempt.student_id == student_id)
            .options(selectinload(QuizAttempt.answers))
        )
        if attempt is None:
            attempt = QuizAttempt(
                school_id=school_id,
                quiz_id=quiz_id,
                student_id=student_id,
                started_at=_now(),
                status=AttemptStatus.IN_PROGRESS.value,
            )
            self.db.add(attempt)
            await self.db.flush()
        else:
            if attempt.status != AttemptStatus.IN_PROGRESS.value:
                raise bad_request("This quiz has already been submitted")
            # Clear any prior answers for a clean re-computation.
            for old in list(attempt.answers):
                await self.db.delete(old)
            await self.db.flush()

        questions = {q.id: q for q in quiz.questions}
        responses = {a.question_id: a.response for a in data.answers}

        auto_score = 0.0
        needs_manual = False
        for qid, question in questions.items():
            response = responses.get(qid)
            is_correct: bool | None = None
            marks_awarded: float | None = None
            if question.question_type in (QuestionType.MCQ.value, QuestionType.TRUE_FALSE.value):
                if question.correct_answer is not None and response is not None:
                    is_correct = response.strip().lower() == question.correct_answer.strip().lower()
                else:
                    is_correct = False
                marks_awarded = question.marks if is_correct else 0.0
                auto_score += marks_awarded
            else:  # short answer -> manual grading
                needs_manual = True
            self.db.add(
                QuizAnswer(
                    school_id=school_id,
                    attempt_id=attempt.id,
                    question_id=qid,
                    response=response,
                    is_correct=is_correct,
                    marks_awarded=marks_awarded,
                )
            )

        attempt.submitted_at = _now()
        attempt.score = auto_score
        attempt.status = (
            AttemptStatus.SUBMITTED.value if needs_manual else AttemptStatus.GRADED.value
        )
        await self.db.flush()
        # Re-fetch with answers eagerly loaded for serialization.
        return await self.get_attempt(school_id, attempt.id)

    async def get_attempt(self, school_id: uuid.UUID, attempt_id: uuid.UUID) -> QuizAttempt:
        attempt = await self.db.scalar(
            select(QuizAttempt)
            .where(QuizAttempt.id == attempt_id, QuizAttempt.school_id == school_id)
            .options(selectinload(QuizAttempt.answers))
        )
        if attempt is None:
            raise not_found("Attempt not found in this school")
        return attempt

    async def list_attempts(self, school_id: uuid.UUID, quiz_id: uuid.UUID) -> list[QuizAttempt]:
        await self._get_scoped(Quiz, school_id, quiz_id, "Quiz")
        result = await self.db.execute(
            select(QuizAttempt).where(QuizAttempt.quiz_id == quiz_id)
        )
        return list(result.scalars().all())

    async def grade_attempt(
        self,
        school_id: uuid.UUID,
        attempt_id: uuid.UUID,
        data: schemas.GradeAttempt,
        graded_by: uuid.UUID,
    ) -> QuizAttempt:
        attempt = await self.get_attempt(school_id, attempt_id)
        answers = {a.id: a for a in attempt.answers}
        for grade in data.grades:
            answer = answers.get(grade.answer_id)
            if answer is None:
                raise not_found(f"Answer {grade.answer_id} not part of this attempt")
            answer.marks_awarded = grade.marks_awarded
            answer.is_correct = grade.is_correct
        # Recompute total from all awarded marks (ungraded short answers count 0).
        attempt.score = sum((a.marks_awarded or 0.0) for a in attempt.answers)
        attempt.status = AttemptStatus.GRADED.value
        attempt.graded_by = graded_by
        await self.db.flush()
        return attempt

    async def student_attempts(
        self, school_id: uuid.UUID, student_id: uuid.UUID
    ) -> list[QuizAttempt]:
        result = await self.db.execute(
            select(QuizAttempt).where(
                QuizAttempt.school_id == school_id, QuizAttempt.student_id == student_id
            )
        )
        return list(result.scalars().all())

    # ------------------------------- report ------------------------------ #

    async def report(self, school_id: uuid.UUID, quiz_id: uuid.UUID) -> schemas.QuizReport:
        quiz = await self.get_quiz(school_id, quiz_id)
        total_marks = sum(q.marks for q in quiz.questions)
        attempts = await self.list_attempts(school_id, quiz_id)
        submitted = [a for a in attempts if a.submitted_at is not None]
        graded = [a for a in attempts if a.status == AttemptStatus.GRADED.value]
        scores = [a.score for a in graded if a.score is not None]
        return schemas.QuizReport(
            quiz_id=quiz_id,
            title=quiz.title,
            total_marks=total_marks,
            total_attempts=len(attempts),
            submitted_count=len(submitted),
            graded_count=len(graded),
            average_score=(sum(scores) / len(scores)) if scores else None,
            highest_score=max(scores) if scores else None,
            lowest_score=min(scores) if scores else None,
        )

    # --------------------------- assignment & scope --------------------------- #

    async def assign(
        self, school_id: uuid.UUID, quiz_id: uuid.UUID, data: schemas.AssignQuiz
    ) -> Quiz:
        quiz = await self._get_scoped(Quiz, school_id, quiz_id, "Quiz")
        await self._set_assignees(school_id, quiz, data.student_ids)
        return quiz

    async def list_section_students(
        self, school_id: uuid.UUID, section_id: uuid.UUID
    ) -> list[schemas.RosterStudent]:
        """Enrolled students of a section (for the assignee picker)."""
        await self._get_scoped(Section, school_id, section_id, "Section")
        ids = await self._enrolled_student_ids(section_id)
        if not ids:
            return []
        rows = await self.db.execute(select(User.id, User.full_name).where(User.id.in_(ids)))
        names = {uid: name for uid, name in rows.all()}
        return [schemas.RosterStudent(student_id=sid, name=names.get(sid, "")) for sid in ids]

    async def list_for_student(
        self, school_id: uuid.UUID, student_id: uuid.UUID
    ) -> list[Quiz]:
        """Published quizzes visible to a student: those explicitly assigned to
        them, plus section-wide quizzes (no explicit assignees) for the sections
        they're enrolled in."""
        sec_rows = await self.db.execute(
            select(StudentEnrollment.section_id).where(
                StudentEnrollment.student_id == student_id,
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
            )
        )
        section_ids = {r[0] for r in sec_rows.all()}

        assigned_rows = await self.db.execute(
            select(QuizAssignment.quiz_id).where(
                QuizAssignment.school_id == school_id,
                QuizAssignment.student_id == student_id,
            )
        )
        assigned_quiz_ids = {r[0] for r in assigned_rows.all()}

        # Quizzes that carry ANY explicit assignees (hidden from non-assignees).
        targeted_rows = await self.db.execute(
            select(QuizAssignment.quiz_id)
            .where(QuizAssignment.school_id == school_id)
            .distinct()
        )
        targeted_quiz_ids = {r[0] for r in targeted_rows.all()}

        result = await self.db.execute(
            select(Quiz)
            .where(Quiz.school_id == school_id, Quiz.status == QuizStatus.PUBLISHED.value)
            .order_by(Quiz.created_at.desc())
        )
        visible: list[Quiz] = []
        for q in result.scalars().all():
            if q.id in assigned_quiz_ids:
                visible.append(q)
            elif q.id not in targeted_quiz_ids and q.section_id in section_ids:
                visible.append(q)
        return visible

    async def performance(
        self, school_id: uuid.UUID, quiz_id: uuid.UUID
    ) -> schemas.QuizPerformance:
        """Per-student scores for a quiz (its roster joined with attempts)."""
        quiz = await self.get_quiz(school_id, quiz_id)
        total_marks = sum(q.marks for q in quiz.questions)
        assignees = await self._assignee_ids(quiz_id)
        roster_ids = (
            list(assignees) if assignees
            else await self._enrolled_student_ids(quiz.section_id)
        )
        names: dict[uuid.UUID, str] = {}
        if roster_ids:
            rows = await self.db.execute(
                select(User.id, User.full_name).where(User.id.in_(roster_ids))
            )
            names = {uid: name for uid, name in rows.all()}
        attempts = {
            a.student_id: a for a in await self.list_attempts(school_id, quiz_id)
        }
        result_rows = [
            schemas.QuizPerformanceRow(
                student_id=sid,
                name=names.get(sid, ""),
                score=(attempts[sid].score if sid in attempts else None),
                status=(attempts[sid].status if sid in attempts else "not_attempted"),
                submitted=bool(sid in attempts and attempts[sid].submitted_at is not None),
            )
            for sid in roster_ids
        ]
        # Highest scorers first; unattempted last.
        result_rows.sort(key=lambda r: (r.score is None, -(r.score or 0)))
        return schemas.QuizPerformance(
            quiz_id=quiz_id,
            title=quiz.title,
            total_marks=total_marks,
            rows=result_rows,
        )

    # --------------------------- AI generation ------------------------------- #

    async def generate_questions(
        self, source_text: str, num_questions: int
    ) -> list[schemas.GeneratedQuestion]:
        """Turn study material (e.g. extracted PDF text) into draft MCQs via the
        AI provider. The result is returned for the teacher to review/edit before
        publishing — nothing is persisted here."""
        text = source_text.strip()
        if len(text) < 40:
            raise bad_request("Not enough readable text to generate a quiz from.")
        n = max(1, min(num_questions, 20))
        system = (
            "You are a quiz author. From the provided study material, write "
            f"{n} multiple-choice questions that test understanding. Respond with "
            "ONLY a JSON array — no prose, no markdown fences. Each element must be "
            '{"prompt": string, "options": array of 4 distinct strings, '
            '"correct_answer": one of the options copied verbatim, '
            '"marks": integer 1 or 2}.'
        )
        prompt = (
            f"Study material:\n\n{text[:8000]}\n\nGenerate {n} multiple-choice "
            "questions as a JSON array."
        )
        result = await ai_provider.generate(prompt, system=system)
        if result.provider == "stub":
            raise bad_request(
                "AI generation isn't configured. Set ANTHROPIC_API_KEY to enable "
                "PDF-to-quiz generation."
            )
        questions = self._parse_generated(result.text, n)
        if not questions:
            raise bad_request(
                "The AI response couldn't be parsed into quiz questions. Please try again."
            )
        return questions

    @staticmethod
    def _parse_generated(raw: str, limit: int) -> list[schemas.GeneratedQuestion]:
        """Extract a JSON array of MCQs from the model output, tolerating stray
        prose or ```json fences, and keep only well-formed items."""
        text = raw.strip()
        start, end = text.find("["), text.rfind("]")
        if start == -1 or end == -1 or end <= start:
            return []
        try:
            data = json.loads(text[start : end + 1])
        except json.JSONDecodeError:
            return []
        out: list[schemas.GeneratedQuestion] = []
        for item in data if isinstance(data, list) else []:
            if not isinstance(item, dict):
                continue
            prompt = str(item.get("prompt", "")).strip()
            options = [
                str(o).strip() for o in (item.get("options") or []) if str(o).strip()
            ]
            correct = str(item.get("correct_answer", "")).strip()
            if not prompt or len(options) < 2 or correct not in options:
                continue
            try:
                marks = float(item.get("marks", 1)) or 1.0
            except (TypeError, ValueError):
                marks = 1.0
            out.append(
                schemas.GeneratedQuestion(
                    prompt=prompt, options=options, correct_answer=correct, marks=marks
                )
            )
            if len(out) >= limit:
                break
        return out
