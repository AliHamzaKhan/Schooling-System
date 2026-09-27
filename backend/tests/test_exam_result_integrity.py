"""Result publication must not finalize incomplete gradebooks."""

from app.core.config import settings

from tests.utils import create_user, enroll, make_academics

API = settings.API_V1_PREFIX


async def test_result_publication_requires_explicit_score_or_absence_for_every_student(
    client, school
):
    sid, hm = school["id"], school["hm"]
    academics = await make_academics(client, sid, hm)
    first = await create_user(client, sid, hm, "student")
    second = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, academics["section_id"], first["id"])
    await enroll(client, sid, hm, academics["section_id"], second["id"])

    exam = (
        await client.post(
            f"{API}/schools/{sid}/exams",
            headers=hm,
            json={"class_id": academics["class_id"], "name": "Final Integrity"},
        )
    ).json()
    paper = (
        await client.post(
            f"{API}/schools/{sid}/exams/{exam['id']}/papers",
            headers=hm,
            json={
                "subject_id": academics["subject_id"],
                "max_marks": 100,
                "pass_marks": 40,
            },
        )
    ).json()

    # A blank row is still incomplete, and the second student has no row at all.
    entered = await client.post(
        f"{API}/schools/{sid}/exams/papers/{paper['id']}/marks",
        headers=hm,
        json={"entries": [{"student_id": first["id"], "marks_obtained": None}]},
    )
    assert entered.status_code == 200, entered.text

    rejected = await client.post(
        f"{API}/schools/{sid}/exams/{exam['id']}/results/publish", headers=hm
    )
    assert rejected.status_code == 400
    assert "marks are incomplete (2 of 2 paper entries remain unmarked)" in rejected.json()["detail"]

    # A failed publish cannot expose any partial final result.
    results = await client.get(f"{API}/schools/{sid}/exams/{exam['id']}/results", headers=hm)
    assert results.status_code == 200
    assert results.json() == []

    completed = await client.post(
        f"{API}/schools/{sid}/exams/papers/{paper['id']}/marks",
        headers=hm,
        json={
            "entries": [
                {"student_id": first["id"], "marks_obtained": 70},
                {"student_id": second["id"], "is_absent": True},
            ]
        },
    )
    assert completed.status_code == 200, completed.text

    published = await client.post(
        f"{API}/schools/{sid}/exams/{exam['id']}/results/publish", headers=hm
    )
    assert published.status_code == 200, published.text
    assert len(published.json()) == 2


async def test_exam_dates_and_list_window_are_validated(client, school):
    school_id, headmaster = school["id"], school["hm"]
    academics = await make_academics(client, school_id, headmaster)
    exams_url = f"{API}/schools/{school_id}/exams"

    invalid = await client.post(
        exams_url,
        headers=headmaster,
        json={
            "class_id": academics["class_id"],
            "name": "Invalid dates",
            "start_date": "2030-06-10",
            "end_date": "2030-06-09",
        },
    )
    assert invalid.status_code == 400
    assert "end_date" in invalid.json()["detail"]

    for name in ("First window", "Second window", "Third window"):
        created = await client.post(
            exams_url,
            headers=headmaster,
            json={"class_id": academics["class_id"], "name": name},
        )
        assert created.status_code == 201, created.text

    complete = await client.get(exams_url, headers=headmaster)
    first_page = await client.get(exams_url, headers=headmaster, params={"limit": 2})
    second_page = await client.get(
        exams_url, headers=headmaster, params={"limit": 2, "offset": 2}
    )
    assert complete.status_code == first_page.status_code == second_page.status_code == 200
    assert first_page.json() == complete.json()[:2]
    assert second_page.json() == complete.json()[2:]

    invalid_limit = await client.get(exams_url, headers=headmaster, params={"limit": 101})
    assert invalid_limit.status_code == 422

    existing = complete.json()[0]
    invalid_patch = await client.patch(
        f"{exams_url}/{existing['id']}",
        headers=headmaster,
        json={"start_date": "2030-08-10", "end_date": "2030-08-09"},
    )
    assert invalid_patch.status_code == 400


async def test_exam_paper_requires_a_subject_compatible_with_its_class(client, school):
    school_id, headmaster = school["id"], school["hm"]
    academics = await make_academics(client, school_id, headmaster)
    exams_url = f"{API}/schools/{school_id}/exams"

    exam = await client.post(
        exams_url,
        headers=headmaster,
        json={"class_id": academics["class_id"], "name": "Grade one final"},
    )
    assert exam.status_code == 201, exam.text

    other_class = await client.post(
        f"{API}/schools/{school_id}/academic/classes",
        headers=headmaster,
        json={"name": "Grade 2", "level": 2},
    )
    assert other_class.status_code == 201, other_class.text
    class_two_subject = await client.post(
        f"{API}/schools/{school_id}/academic/subjects",
        headers=headmaster,
        json={
            "class_id": other_class.json()["id"],
            "code": "SCI-G2",
            "name": "Grade 2 Science",
        },
    )
    assert class_two_subject.status_code == 201, class_two_subject.text

    rejected = await client.post(
        f"{exams_url}/{exam.json()['id']}/papers",
        headers=headmaster,
        json={
            "subject_id": class_two_subject.json()["id"],
            "max_marks": 100,
            "pass_marks": 40,
        },
    )
    assert rejected.status_code == 400
    assert "not assigned to the exam's class" in rejected.json()["detail"]

    # School-wide subjects remain usable by all classes.
    accepted = await client.post(
        f"{exams_url}/{exam.json()['id']}/papers",
        headers=headmaster,
        json={"subject_id": academics["subject_id"], "max_marks": 100, "pass_marks": 40},
    )
    assert accepted.status_code == 201, accepted.text


async def test_exam_window_cannot_exclude_an_existing_dated_paper(client, school):
    school_id, headmaster = school["id"], school["hm"]
    academics = await make_academics(client, school_id, headmaster)
    exams_url = f"{API}/schools/{school_id}/exams"

    created = await client.post(
        exams_url,
        headers=headmaster,
        json={
            "class_id": academics["class_id"],
            "name": "Window integrity",
            "start_date": "2030-06-10",
            "end_date": "2030-06-20",
        },
    )
    assert created.status_code == 201, created.text
    exam = created.json()

    paper = await client.post(
        f"{exams_url}/{exam['id']}/papers",
        headers=headmaster,
        json={
            "subject_id": academics["subject_id"],
            "max_marks": 100,
            "pass_marks": 40,
            "exam_date": "2030-06-15",
        },
    )
    assert paper.status_code == 201, paper.text

    late_start = await client.patch(
        f"{exams_url}/{exam['id']}",
        headers=headmaster,
        json={"start_date": "2030-06-16"},
    )
    assert late_start.status_code == 400
    assert "start_date cannot be after" in late_start.json()["detail"]

    early_end = await client.patch(
        f"{exams_url}/{exam['id']}",
        headers=headmaster,
        json={"end_date": "2030-06-14"},
    )
    assert early_end.status_code == 400
    assert "end_date cannot be before" in early_end.json()["detail"]

    unchanged = await client.get(exams_url, headers=headmaster)
    assert unchanged.status_code == 200, unchanged.text
    saved = next(item for item in unchanged.json() if item["id"] == exam["id"])
    assert saved["start_date"] == "2030-06-10"
    assert saved["end_date"] == "2030-06-20"
