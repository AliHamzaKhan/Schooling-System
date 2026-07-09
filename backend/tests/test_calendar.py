"""Academic calendar CRUD, filtering, and the exam-schedule feed."""
from app.core.config import settings

from tests.utils import make_academics

API = settings.API_V1_PREFIX


async def test_event_crud_and_type_filter(client, school):
    sid, hm = school["id"], school["hm"]

    holiday = await client.post(f"{API}/schools/{sid}/calendar/events", headers=hm, json={
        "title": "Independence Day", "event_type": "holiday", "start_date": "2026-08-14"})
    assert holiday.status_code == 201, holiday.text

    await client.post(f"{API}/schools/{sid}/calendar/events", headers=hm, json={
        "title": "Sports Day", "event_type": "event",
        "start_date": "2026-09-01", "end_date": "2026-09-02"})

    # Filter by type returns only holidays.
    r = await client.get(f"{API}/schools/{sid}/calendar/events",
                         headers=hm, params={"event_type": "holiday"})
    assert r.status_code == 200
    titles = [e["title"] for e in r.json()]
    assert titles == ["Independence Day"]

    # Update + delete.
    eid = holiday.json()["id"]
    up = await client.patch(f"{API}/schools/{sid}/calendar/events/{eid}", headers=hm,
                            json={"location": "Main Hall"})
    assert up.json()["location"] == "Main Hall"
    d = await client.delete(f"{API}/schools/{sid}/calendar/events/{eid}", headers=hm)
    assert d.status_code == 204


async def test_end_before_start_rejected(client, school):
    sid, hm = school["id"], school["hm"]
    r = await client.post(f"{API}/schools/{sid}/calendar/events", headers=hm, json={
        "title": "Bad Range", "start_date": "2026-09-05", "end_date": "2026-09-01"})
    assert r.status_code == 422


async def test_date_window_filter(client, school):
    sid, hm = school["id"], school["hm"]
    for title, d in [("Jan", "2026-01-10"), ("Jun", "2026-06-10"), ("Dec", "2026-12-10")]:
        await client.post(f"{API}/schools/{sid}/calendar/events", headers=hm,
                          json={"title": title, "start_date": d})
    r = await client.get(f"{API}/schools/{sid}/calendar/events", headers=hm,
                         params={"from_date": "2026-05-01", "to_date": "2026-07-01"})
    assert [e["title"] for e in r.json()] == ["Jun"]


async def test_exam_schedule_feed(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    await client.post(f"{API}/schools/{sid}/exams", headers=hm, json={
        "class_id": ac["class_id"], "name": "Midterm",
        "start_date": "2026-10-01", "end_date": "2026-10-05"})
    r = await client.get(f"{API}/schools/{sid}/calendar/exam-schedule", headers=hm)
    assert r.status_code == 200, r.text
    feed = r.json()
    assert len(feed) == 1
    assert feed[0]["title"] == "Midterm"
    assert feed[0]["event_type"] == "exam"
