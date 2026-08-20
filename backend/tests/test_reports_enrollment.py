"""Enrollment report — guards the grouped-aggregate query rewrite (was N+1)."""
from .conftest import API
from .utils import create_user, enroll, make_academics


async def test_enrollment_report_counts(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)  # 1 class "Grade 1", 1 section "A"

    s1 = await create_user(client, sid, hm, "student")
    s2 = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], s1["id"])
    await enroll(client, sid, hm, ac["section_id"], s2["id"])

    r = await client.get(f"{API}/schools/{sid}/reports/enrollment", headers=hm)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["total_students"] == 2
    grade1 = next(c for c in body["classes"] if c["class_id"] == ac["class_id"])
    assert grade1["sections"] == 1
    assert grade1["students"] == 2
