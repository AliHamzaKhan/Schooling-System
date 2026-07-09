"""Promotion, promotion reports, and merit-list rules."""
from app.core.config import settings

from tests.utils import create_user, enroll, make_academics

API = settings.API_V1_PREFIX


async def _exam_with_results(client, sid, hm, ac, students_marks):
    """Create an exam+paper, enter marks, publish results. students_marks: {id: mark}."""
    exam = (await client.post(f"{API}/schools/{sid}/exams", headers=hm,
            json={"class_id": ac["class_id"], "name": "Final"})).json()
    paper = (await client.post(f"{API}/schools/{sid}/exams/{exam['id']}/papers", headers=hm,
             json={"subject_id": ac["subject_id"], "max_marks": 100, "pass_marks": 40})).json()
    await client.post(f"{API}/schools/{sid}/exams/papers/{paper['id']}/marks", headers=hm, json={
        "entries": [{"student_id": s, "marks_obtained": m} for s, m in students_marks.items()]})
    await client.post(f"{API}/schools/{sid}/exams/{exam['id']}/results/publish", headers=hm)
    return exam


async def _next_section(client, sid, hm):
    rc = await client.post(f"{API}/schools/{sid}/academic/classes", headers=hm,
                           json={"name": "Grade 2", "level": 2})
    cid = rc.json()["id"]
    rs = await client.post(f"{API}/schools/{sid}/academic/classes/{cid}/sections", headers=hm,
                           json={"name": "A"})
    return rs.json()["id"]


async def test_preview_and_promote_flow(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    s_pass = await create_user(client, sid, hm, "student")
    s_fail = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], s_pass["id"])
    await enroll(client, sid, hm, ac["section_id"], s_fail["id"])
    exam = await _exam_with_results(client, sid, hm, ac,
                                    {s_pass["id"]: 85, s_fail["id"]: 20})

    # Preview suggests promote for the passer, retain for the failer.
    prev = await client.get(f"{API}/schools/{sid}/promotions/preview",
                            headers=hm, params={"exam_id": exam["id"]})
    assert prev.status_code == 200, prev.text
    suggested = {r["student_id"]: r["suggested_outcome"] for r in prev.json()}
    assert suggested[s_pass["id"]] == "promoted"
    assert suggested[s_fail["id"]] == "retained"

    next_section = await _next_section(client, sid, hm)
    r = await client.post(f"{API}/schools/{sid}/promotions", headers=hm, json={
        "exam_id": exam["id"],
        "items": [
            {"student_id": s_pass["id"], "to_section_id": next_section, "outcome": "promoted"},
            {"student_id": s_fail["id"], "outcome": "retained"},
        ],
    })
    assert r.status_code == 201, r.text

    # Passer now enrolled in the next section; failer stays in the original.
    new_roster = (await client.get(
        f"{API}/schools/{sid}/sections/{next_section}/students", headers=hm)).json()
    assert any(e["student_id"] == s_pass["id"] for e in new_roster)
    old_roster = (await client.get(
        f"{API}/schools/{sid}/sections/{ac['section_id']}/students", headers=hm)).json()
    active_old = [e["student_id"] for e in old_roster if e["status"] == "active"]
    assert s_fail["id"] in active_old
    assert s_pass["id"] not in active_old

    # Promotion report has both records.
    report = (await client.get(f"{API}/schools/{sid}/promotions", headers=hm)).json()
    outcomes = {rec["student_id"]: rec["outcome"] for rec in report}
    assert outcomes[s_pass["id"]] == "promoted"
    assert outcomes[s_fail["id"]] == "retained"


async def test_promote_requires_target_section(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])
    r = await client.post(f"{API}/schools/{sid}/promotions", headers=hm, json={
        "items": [{"student_id": student["id"], "outcome": "promoted"}]})
    assert r.status_code == 400


async def test_merit_list_ranking(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    top = await create_user(client, sid, hm, "student")
    mid = await create_user(client, sid, hm, "student")
    low = await create_user(client, sid, hm, "student")
    for s in (top, mid, low):
        await enroll(client, sid, hm, ac["section_id"], s["id"])
    exam = await _exam_with_results(client, sid, hm, ac,
                                    {top["id"]: 95, mid["id"]: 70, low["id"]: 45})

    r = await client.get(f"{API}/schools/{sid}/exams/{exam['id']}/merit-list", headers=hm)
    assert r.status_code == 200, r.text
    ranked = r.json()
    assert [row["student_id"] for row in ranked] == [top["id"], mid["id"], low["id"]]
    assert ranked[0]["rank"] == 1
    assert ranked[0]["percentage"] == 95
