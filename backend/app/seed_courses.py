"""Idempotent demo course content for the THS test tenant.

Run: .venv/bin/python -m app.seed_courses
Safe to re-run — it skips a course whose title already exists in the school.
"""
import asyncio

from sqlalchemy import select

from app.core.database import AsyncSessionLocal, engine
from app.models.course import BookChapter, Course, CourseBook, CourseNote

SCHOOL_ID = "9a0e89e3-696f-48b0-9659-93382a9f8e74"
HEADMASTER_ID = "1fd2a141-dcc8-4a4b-be84-40309876c06c"

_LOREM = (
    "Photosynthesis is the process by which green plants convert light energy "
    "into chemical energy. It takes place mainly in the leaves, inside tiny "
    "structures called chloroplasts that contain the green pigment chlorophyll.\n\n"
    "During photosynthesis, plants take in carbon dioxide from the air through "
    "small pores called stomata, and absorb water from the soil through their "
    "roots. Using sunlight, they combine these into glucose and release oxygen "
    "as a by-product.\n\n"
    "The overall word equation is: carbon dioxide + water (in the presence of "
    "light and chlorophyll) produces glucose + oxygen. This glucose is the food "
    "the plant uses to grow, and the oxygen is what most living things breathe."
)

COURSES = [
    {
        "title": "General Science — Grade 5",
        "subject": "Science",
        "description": "Foundational science: living things, matter, and energy.",
        "books": [
            {
                "title": "Life Science",
                "description": "How living things grow, feed, and reproduce.",
                "chapters": [
                    ("Chapter 1: Living Things", "All living things share seven characteristics: movement, respiration, sensitivity, growth, reproduction, excretion, and nutrition. In this chapter we explore each of these using familiar examples from plants and animals.\n\n" + _LOREM),
                    ("Chapter 2: Photosynthesis", _LOREM + "\n\nWithout photosynthesis there would be almost no food and very little oxygen on Earth, which is why green plants are called producers."),
                    ("Chapter 3: The Human Body", "The human body is organised into systems that each do a special job: the digestive system breaks down food, the circulatory system moves blood, and the respiratory system takes in oxygen.\n\n" + _LOREM),
                ],
            },
        ],
        "notes": [
            ("Key Terms — Photosynthesis", "chlorophyll: the green pigment that captures light.\nstomata: pores in leaves for gas exchange.\nglucose: the sugar plants make for food.\n\nRemember the equation: CO2 + water + light -> glucose + oxygen."),
            ("Revision Checklist", "1. Name the seven characteristics of living things.\n2. Explain where photosynthesis happens.\n3. List the raw materials and products of photosynthesis.\n4. Name three body systems and what they do."),
        ],
    },
    {
        "title": "English Language — Grade 5",
        "subject": "English",
        "description": "Reading comprehension, grammar, and composition.",
        "books": [
            {
                "title": "Grammar Basics",
                "description": "Parts of speech and sentence construction.",
                "chapters": [
                    ("Chapter 1: Nouns and Verbs", "A noun is a naming word — a person, place, thing, or idea. A verb is a doing or being word. Every complete sentence needs at least one noun (or pronoun) and one verb.\n\nExample: The dog runs. 'Dog' is the noun; 'runs' is the verb."),
                    ("Chapter 2: Adjectives and Adverbs", "Adjectives describe nouns (a red ball, a tall tree). Adverbs describe verbs, adjectives, or other adverbs, and often end in -ly (she ran quickly)."),
                ],
            },
        ],
        "notes": [
            ("Punctuation Rules", "Full stop (.) ends a statement.\nQuestion mark (?) ends a question.\nComma (,) separates items in a list.\nApostrophe (') shows possession or contraction."),
        ],
    },
]


async def main() -> None:
    async with AsyncSessionLocal() as db:
        created = 0
        for c in COURSES:
            exists = await db.scalar(
                select(Course).where(
                    Course.school_id == SCHOOL_ID, Course.title == c["title"]
                )
            )
            if exists is not None:
                print(f"skip (exists): {c['title']}")
                continue
            course = Course(
                school_id=SCHOOL_ID,
                title=c["title"],
                subject=c["subject"],
                description=c["description"],
                created_by=HEADMASTER_ID,
            )
            db.add(course)
            await db.flush()
            for bi, b in enumerate(c["books"]):
                book = CourseBook(
                    school_id=SCHOOL_ID,
                    course_id=course.id,
                    title=b["title"],
                    description=b["description"],
                    order_index=bi,
                )
                db.add(book)
                await db.flush()
                for ci, (title, content) in enumerate(b["chapters"]):
                    db.add(BookChapter(
                        school_id=SCHOOL_ID, book_id=book.id,
                        title=title, content=content, order_index=ci,
                    ))
            for ni, (title, content) in enumerate(c["notes"]):
                db.add(CourseNote(
                    school_id=SCHOOL_ID, course_id=course.id,
                    title=title, content=content, order_index=ni,
                ))
            created += 1
            print(f"created: {c['title']}")
        await db.commit()
        print(f"done — {created} course(s) created")
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
