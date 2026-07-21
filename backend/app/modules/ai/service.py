"""AI Features Service."""
import json
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import QuestionType
from app.core.exceptions import bad_request
from app.models.ai import AIInteraction
from app.modules.ai import schemas
from app.modules.ai.providers import ai_provider

QUIZ_SYSTEM = (
    "You are an experienced schoolteacher writing quiz questions. "
    "Write clear, unambiguous questions at the requested level with exactly one "
    "defensible correct answer each. Never reference material the students have "
    "not been told about, and never write a question whose answer is given away "
    "by its own wording."
)


def _questions_schema(question_type: QuestionType, count: int) -> dict:
    """JSON schema constraining the model's output to reviewable questions.

    ``additionalProperties: false`` plus an explicit ``required`` list is what
    makes structured outputs enforceable, and the array bounds stop the model
    returning a different number of questions than the teacher asked for.
    """
    question: dict = {
        "type": "object",
        "properties": {
            "prompt": {"type": "string", "description": "The question text."},
            "correct_answer": {
                "type": "string",
                "description": (
                    "For MCQ, the exact text of the correct option. "
                    "For true/false, 'True' or 'False'."
                ),
            },
            "marks": {"type": "number", "description": "Marks for this question."},
        },
        "required": ["prompt", "correct_answer", "marks"],
        "additionalProperties": False,
    }
    if question_type is QuestionType.MCQ:
        question["properties"]["options"] = {
            "type": "array",
            "items": {"type": "string"},
            "description": "Exactly 4 distinct answer options.",
        }
        question["required"].append("options")

    return {
        "type": "object",
        "properties": {
            "questions": {
                "type": "array",
                "items": question,
                "description": f"Exactly {count} questions.",
            }
        },
        "required": ["questions"],
        "additionalProperties": False,
    }


class AIService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def generate(self, school_id: uuid.UUID, data: schemas.GenerateRequest, created_by: uuid.UUID) -> AIInteraction:
        result = await ai_provider.generate(data.prompt, data.system)
        interaction = AIInteraction(
            school_id=school_id,
            feature=data.feature,
            prompt=data.prompt,
            response=result.text,
            provider=result.provider,
            created_by=created_by,
        )
        self.db.add(interaction)
        await self.db.flush()
        return interaction

    async def generate_quiz_questions(
        self,
        school_id: uuid.UUID,
        data: schemas.QuizGenerateRequest,
        created_by: uuid.UUID,
    ) -> schemas.QuizGenerateResponse:
        """Draft quiz questions for teacher review. Persists nothing but the log."""
        context = [f"Topic: {data.topic}"]
        if data.subject_name:
            context.append(f"Subject: {data.subject_name}")
        if data.grade_level:
            context.append(f"Grade level: {data.grade_level}")
        context.append(f"Difficulty: {data.difficulty}")
        if data.question_type is QuestionType.MCQ:
            context.append("Format: multiple choice with exactly 4 options each")
        elif data.question_type is QuestionType.TRUE_FALSE:
            context.append("Format: true/false statements")
        else:
            context.append("Format: short-answer questions")
        if data.instructions:
            context.append(f"Additional instructions: {data.instructions}")

        prompt = (
            f"Write exactly {data.question_count} quiz questions.\n"
            + "\n".join(context)
        )

        stub = {
            "questions": [
                {
                    "prompt": f"[AI stub] Sample question {i + 1} about {data.topic}",
                    "options": ["Option A", "Option B", "Option C", "Option D"]
                    if data.question_type is QuestionType.MCQ
                    else None,
                    "correct_answer": "Option A"
                    if data.question_type is QuestionType.MCQ
                    else "True",
                    "marks": 1.0,
                }
                for i in range(data.question_count)
            ]
        }

        try:
            result = await ai_provider.generate_json(
                prompt,
                _questions_schema(data.question_type, data.question_count),
                system=QUIZ_SYSTEM,
                stub=stub,
            )
        except ValueError as exc:
            raise bad_request(str(exc)) from exc

        raw = (result.data or {}).get("questions", [])
        questions = [
            schemas.GeneratedQuestion(
                prompt=q["prompt"],
                question_type=data.question_type,
                options=q.get("options"),
                correct_answer=q.get("correct_answer"),
                marks=q.get("marks") or 1.0,
            )
            for q in raw
        ]

        # Log the interaction like any other AI feature, so schools keep an
        # audit trail of what was generated and by whom.
        self.db.add(
            AIInteraction(
                school_id=school_id,
                feature="quiz_generation",
                prompt=prompt,
                response=json.dumps(result.data),
                provider=result.provider,
                created_by=created_by,
            )
        )
        await self.db.flush()
        return schemas.QuizGenerateResponse(
            questions=questions, provider=result.provider
        )

    async def list_interactions(self, school_id: uuid.UUID, limit: int = 50) -> list[AIInteraction]:
        result = await self.db.execute(
            select(AIInteraction).where(AIInteraction.school_id == school_id)
            .order_by(AIInteraction.created_at.desc()).limit(limit)
        )
        return list(result.scalars().all())
