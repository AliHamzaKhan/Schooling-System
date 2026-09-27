"""Transport P2/P3: optimization, location pings, tracking, ETA."""
from app.core.config import settings

from tests.utils import create_user, login

API = settings.API_V1_PREFIX


async def _driver(client, sid, hm, email):
    d = await client.post(f"{API}/schools/{sid}/transport/drivers", headers=hm, json={
        "email": email, "password": "DriverPass1", "full_name": "Drv",
    })
    return d.json()["user_id"], await login(client, email, "DriverPass1")


async def _assign(client, sid, hm, route_id, driver_user_id, lat, lng):
    student = await create_user(client, sid, hm, "student")
    r = await client.post(f"{API}/schools/{sid}/transport/assignments", headers=hm, json={
        "student_id": student["id"], "route_id": route_id, "driver_id": driver_user_id,
        "latitude": lat, "longitude": lng,
    })
    assert r.status_code == 201, r.text
    return student


async def test_trip_optimized_and_next_destination(client, school):
    sid, hm = school["id"], school["hm"]
    driver_uid, dh = await _driver(client, sid, hm, "opt-drv@test.edu")
    route = (await client.post(f"{API}/schools/{sid}/transport/routes", headers=hm,
             json={"name": "Opt"})).json()
    # Three students at increasing distance from (24.80, 67.00).
    s1 = await _assign(client, sid, hm, route["id"], driver_uid, 24.801, 67.001)
    s2 = await _assign(client, sid, hm, route["id"], driver_uid, 24.850, 67.050)
    s3 = await _assign(client, sid, hm, route["id"], driver_uid, 24.900, 67.100)

    trip = await client.post(f"{API}/schools/{sid}/transport/trips/start", headers=dh,
                             json={"route_id": route["id"], "trip_type": "pickup"})
    assert trip.status_code == 201, trip.text
    body = trip.json()
    assert body["optimized"] is True
    assert set(body["stop_order"]) == {s1["id"], s2["id"], s3["id"]}
    # Next destination is the first pending student in the optimized order.
    assert body["next_student_id"] == body["stop_order"][0]


async def test_location_ping_tracking_and_eta(client, school):
    sid, hm = school["id"], school["hm"]
    driver_uid, dh = await _driver(client, sid, hm, "loc-drv@test.edu")
    route = (await client.post(f"{API}/schools/{sid}/transport/routes", headers=hm,
             json={"name": "Loc"})).json()
    student = await _assign(client, sid, hm, route["id"], driver_uid, 24.860, 67.010)
    trip = (await client.post(f"{API}/schools/{sid}/transport/trips/start", headers=dh,
            json={"route_id": route["id"], "trip_type": "pickup"})).json()
    tid = trip["id"]

    # Driver posts a device location.
    ping = await client.post(f"{API}/schools/{sid}/transport/trips/{tid}/location", headers=dh,
                             json={"latitude": 24.800, "longitude": 67.000, "address": "On Main Rd"})
    assert ping.status_code == 201, ping.text

    # Latest location is readable by the headmaster; ETA is computed.
    loc = await client.get(f"{API}/schools/{sid}/transport/trips/{tid}/location", headers=hm)
    assert loc.json()["address"] == "On Main Rd"
    eta = await client.get(f"{API}/schools/{sid}/transport/trips/{tid}/eta", headers=hm)
    assert eta.status_code == 200
    assert eta.json()["distance_m"] > 0
    assert eta.json()["eta_minutes"] is not None

    # The student can track their own trip via /trips/active.
    sh = await login(client, student["email"], student["password"])
    active = await client.get(f"{API}/schools/{sid}/transport/trips/active", headers=sh)
    assert [t["id"] for t in active.json()] == [tid]


async def test_location_only_by_trip_driver(client, school):
    sid, hm = school["id"], school["hm"]
    driver_uid, dh = await _driver(client, sid, hm, "own-drv@test.edu")
    _, other_dh = await _driver(client, sid, hm, "other-drv@test.edu")
    route = (await client.post(f"{API}/schools/{sid}/transport/routes", headers=hm,
             json={"name": "Own"})).json()
    await _assign(client, sid, hm, route["id"], driver_uid, 24.86, 67.01)
    trip = (await client.post(f"{API}/schools/{sid}/transport/trips/start", headers=dh,
            json={"route_id": route["id"], "trip_type": "pickup"})).json()

    # A different driver cannot post this trip's location.
    r = await client.post(f"{API}/schools/{sid}/transport/trips/{trip['id']}/location",
                          headers=other_dh, json={"latitude": 24.8, "longitude": 67.0})
    assert r.status_code == 403


async def test_unrelated_student_cannot_track(client, school):
    sid, hm = school["id"], school["hm"]
    driver_uid, dh = await _driver(client, sid, hm, "trk-drv@test.edu")
    route = (await client.post(f"{API}/schools/{sid}/transport/routes", headers=hm,
             json={"name": "Trk"})).json()
    await _assign(client, sid, hm, route["id"], driver_uid, 24.86, 67.01)
    trip = (await client.post(f"{API}/schools/{sid}/transport/trips/start", headers=dh,
            json={"route_id": route["id"], "trip_type": "pickup"})).json()
    await client.post(f"{API}/schools/{sid}/transport/trips/{trip['id']}/location", headers=dh,
                      json={"latitude": 24.8, "longitude": 67.0})

    outsider = await create_user(client, sid, hm, "student")
    oh = await login(client, outsider["email"], outsider["password"])
    r = await client.get(f"{API}/schools/{sid}/transport/trips/{trip['id']}/location", headers=oh)
    assert r.status_code == 403
    # And they see no active trips of their own.
    assert (await client.get(f"{API}/schools/{sid}/transport/trips/active", headers=oh)).json() == []


async def test_active_trips_paginate_after_guardian_visibility_scope(client, school):
    """A later, unrelated trip must not consume a guardian's page window."""
    sid, hm = school["id"], school["hm"]
    guardian = await create_user(client, sid, hm, "guardian")
    child = await create_user(client, sid, hm, "student")
    unrelated = await create_user(client, sid, hm, "student")
    linked = await client.post(
        f"{API}/schools/{sid}/guardians/{guardian['id']}/children",
        headers=hm,
        json={"student_id": child["id"], "relationship": "parent"},
    )
    assert linked.status_code == 201, linked.text

    own_driver, own_headers = await _driver(client, sid, hm, "page-own-driver@test.edu")
    own_route = (await client.post(
        f"{API}/schools/{sid}/transport/routes", headers=hm, json={"name": "Own route"},
    )).json()
    own_assignment = await client.post(
        f"{API}/schools/{sid}/transport/assignments", headers=hm,
        json={"student_id": child["id"], "route_id": own_route["id"], "driver_id": own_driver},
    )
    assert own_assignment.status_code == 201, own_assignment.text
    own_trip = await client.post(
        f"{API}/schools/{sid}/transport/trips/start", headers=own_headers,
        json={"route_id": own_route["id"], "trip_type": "pickup"},
    )
    assert own_trip.status_code == 201, own_trip.text

    other_driver, other_headers = await _driver(client, sid, hm, "page-other-driver@test.edu")
    other_route = (await client.post(
        f"{API}/schools/{sid}/transport/routes", headers=hm, json={"name": "Other route"},
    )).json()
    other_assignment = await client.post(
        f"{API}/schools/{sid}/transport/assignments", headers=hm,
        json={"student_id": unrelated["id"], "route_id": other_route["id"], "driver_id": other_driver},
    )
    assert other_assignment.status_code == 201, other_assignment.text
    other_trip = await client.post(
        f"{API}/schools/{sid}/transport/trips/start", headers=other_headers,
        json={"route_id": other_route["id"], "trip_type": "pickup"},
    )
    assert other_trip.status_code == 201, other_trip.text

    guardian_headers = await login(client, guardian["email"], guardian["password"])
    page = await client.get(
        f"{API}/schools/{sid}/transport/trips/active?limit=1&offset=0",
        headers=guardian_headers,
    )
    assert page.status_code == 200, page.text
    assert [trip["id"] for trip in page.json()] == [own_trip.json()["id"]]
    assert other_trip.json()["id"] not in {trip["id"] for trip in page.json()}
    assert (await client.get(
        f"{API}/schools/{sid}/transport/trips/active?limit=1&offset=1",
        headers=guardian_headers,
    )).json() == []

    assert (await client.get(
        f"{API}/schools/{sid}/transport/trips/active?limit=101", headers=guardian_headers,
    )).status_code == 422
    assert (await client.get(
        f"{API}/schools/{sid}/transport/trips/active?offset=-1", headers=guardian_headers,
    )).status_code == 422


async def test_transport_assignments_use_a_bounded_stable_list_window(client, school):
    sid, hm = school["id"], school["hm"]
    driver_uid, _ = await _driver(client, sid, hm, "assignment-page-driver@test.edu")
    route = (await client.post(
        f"{API}/schools/{sid}/transport/routes", headers=hm, json={"name": "Paged route"},
    )).json()
    for index in range(3):
        await _assign(client, sid, hm, route["id"], driver_uid, 24.80 + index / 100, 67.0)

    assignments_url = f"{API}/schools/{sid}/transport/assignments"
    complete = await client.get(assignments_url, headers=hm)
    first_page = await client.get(assignments_url, headers=hm, params={"limit": 2})
    second_page = await client.get(
        assignments_url, headers=hm, params={"limit": 2, "offset": 2}
    )
    assert complete.status_code == first_page.status_code == second_page.status_code == 200
    assert first_page.json() == complete.json()[:2]
    assert second_page.json() == complete.json()[2:]
    assert (await client.get(assignments_url, headers=hm, params={"limit": 101})).status_code == 422
