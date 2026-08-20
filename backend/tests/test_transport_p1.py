"""Transport P1: driver login, request → approve → assign, trip lifecycle."""
from app.core.config import settings

from tests.utils import create_user, login

API = settings.API_V1_PREFIX


async def test_driver_create_and_login(client, school):
    sid, hm = school["id"], school["hm"]
    r = await client.post(f"{API}/schools/{sid}/transport/drivers", headers=hm, json={
        "email": "driver1@test.edu", "password": "DriverPass1",
        "full_name": "Danny Driver", "license_no": "LIC-1",
    })
    assert r.status_code == 201, r.text
    assert r.json()["full_name"] == "Danny Driver"

    # The driver can log in and is listed.
    dh = await login(client, "driver1@test.edu", "DriverPass1")
    assert dh["Authorization"].startswith("Bearer ")
    listed = await client.get(f"{API}/schools/{sid}/transport/drivers", headers=hm)
    assert any(d["email"] == "driver1@test.edu" for d in listed.json())


async def _driver(client, sid, hm, email="drv@test.edu"):
    await client.post(f"{API}/schools/{sid}/transport/drivers", headers=hm, json={
        "email": email, "password": "DriverPass1", "full_name": "Drv",
    })
    return await login(client, email, "DriverPass1")


async def test_request_approve_assign_and_trip(client, school):
    sid, hm = school["id"], school["hm"]
    student = await create_user(client, sid, hm, "student")
    sh = await login(client, student["email"], student["password"])

    # Student raises a transport request.
    req = await client.post(f"{API}/schools/{sid}/transport/requests", headers=sh, json={
        "pickup_address": "12 Elm St", "latitude": 24.86, "longitude": 67.01,
    })
    assert req.status_code == 201, req.text
    rid = req.json()["id"]
    assert req.json()["status"] == "pending"

    # Student sees it under mine.
    mine = await client.get(f"{API}/schools/{sid}/transport/requests/mine", headers=sh)
    assert [x["id"] for x in mine.json()] == [rid]

    # Headmaster approves.
    ap = await client.post(f"{API}/schools/{sid}/transport/requests/{rid}/approve", headers=hm)
    assert ap.status_code == 200 and ap.json()["status"] == "approved"

    # Set up a route + driver, then assign the approved student to that driver.
    driver = await client.post(f"{API}/schools/{sid}/transport/drivers", headers=hm, json={
        "email": "drv2@test.edu", "password": "DriverPass1", "full_name": "Bus Bob",
    })
    driver_user_id = driver.json()["user_id"]
    dh = await login(client, "drv2@test.edu", "DriverPass1")
    route = (await client.post(f"{API}/schools/{sid}/transport/routes", headers=hm,
             json={"name": "Route A"})).json()

    asg = await client.post(f"{API}/schools/{sid}/transport/assignments", headers=hm, json={
        "request_id": rid, "route_id": route["id"], "driver_id": driver_user_id,
    })
    assert asg.status_code == 201, asg.text
    # Coordinates copied from the request.
    assert asg.json()["latitude"] == 24.86
    assert asg.json()["student_id"] == student["id"]
    assert asg.json()["driver_id"] == driver_user_id

    # Driver sees their assignment.
    mine_a = await client.get(f"{API}/schools/{sid}/transport/me/assignments", headers=dh)
    assert [a["student_id"] for a in mine_a.json()] == [student["id"]]

    # Driver starts a trip → manifest seeded with the student pending.
    trip = await client.post(f"{API}/schools/{sid}/transport/trips/start", headers=dh,
                             json={"route_id": route["id"], "trip_type": "pickup"})
    assert trip.status_code == 201, trip.text
    tid = trip.json()["id"]
    assert trip.json()["status"] == "in_progress"
    assert trip.json()["stop_order"] == [student["id"]]
    assert trip.json()["events"][0]["status"] == "pending"

    # Fleet view shows the driver online.
    online = await client.get(f"{API}/schools/{sid}/transport/drivers/online", headers=hm)
    assert any(d["driver_id"] == driver_user_id and d["online"] for d in online.json())

    # Mark the student boarded, then end the trip.
    boarded = await client.post(
        f"{API}/schools/{sid}/transport/trips/{tid}/students/{student['id']}/status",
        headers=dh, json={"status": "boarded"})
    assert boarded.json()["events"][0]["status"] == "boarded"

    ended = await client.post(f"{API}/schools/{sid}/transport/trips/{tid}/end", headers=dh)
    assert ended.json()["status"] == "completed"

    # History lists the completed trip for the headmaster.
    hist = await client.get(f"{API}/schools/{sid}/transport/trips?status=completed", headers=hm)
    assert any(t["id"] == tid for t in hist.json())


async def test_guardian_requests_only_for_own_child(client, school):
    sid, hm = school["id"], school["hm"]
    guardian = await create_user(client, sid, hm, "guardian")
    gh = await login(client, guardian["email"], guardian["password"])
    child = await create_user(client, sid, hm, "student")
    other = await create_user(client, sid, hm, "student")
    await client.post(f"{API}/schools/{sid}/guardians/{guardian['id']}/children", headers=hm,
                      json={"student_id": child["id"], "relationship": "mother"})

    # For their own child: allowed.
    ok = await client.post(f"{API}/schools/{sid}/transport/requests", headers=gh, json={
        "student_id": child["id"], "pickup_address": "9 Oak Ave",
    })
    assert ok.status_code == 201, ok.text

    # For someone else's child: forbidden.
    no = await client.post(f"{API}/schools/{sid}/transport/requests", headers=gh, json={
        "student_id": other["id"], "pickup_address": "9 Oak Ave",
    })
    assert no.status_code == 403


async def test_assign_requires_approved_request(client, school):
    sid, hm = school["id"], school["hm"]
    student = await create_user(client, sid, hm, "student")
    sh = await login(client, student["email"], student["password"])
    req = await client.post(f"{API}/schools/{sid}/transport/requests", headers=sh,
                            json={"pickup_address": "1 Pine Rd"})
    rid = req.json()["id"]
    route = (await client.post(f"{API}/schools/{sid}/transport/routes", headers=hm,
             json={"name": "R"})).json()

    # Not yet approved → assignment rejected.
    r = await client.post(f"{API}/schools/{sid}/transport/assignments", headers=hm,
                          json={"request_id": rid, "route_id": route["id"]})
    assert r.status_code == 400
