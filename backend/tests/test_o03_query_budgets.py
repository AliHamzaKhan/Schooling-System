"""O03 query budgets for high-growth history endpoints.

Each endpoint is measured against the representative 105-row fixture at a
small page, a full page and a partial tail.  The SQL statement count must be
identical across those windows (no per-row N+1 work) and must not exceed the
agreed budget below.  Latency percentiles are recorded as evidence only; set
``O03_MEASUREMENT_REPORT`` to collect them::

    O03_MEASUREMENT_REPORT=/tmp/o03.json \
    python scripts/run_isolated_tests.py --from-local-config -- -q \
        tests/test_o03_query_budgets.py
"""
from datetime import datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.core.config import settings
from app.models.communication import Message
from app.models.direct_message import DirectMessage
from tests.conftest import TEST_URL
from tests.query_budget import MeasurementReport, count_queries, measure_endpoint
from tests.representative_fixture import seed_representative_invoice_fixture
from tests.utils import create_user, login


API = settings.API_V1_PREFIX
HISTORY_ROWS = 105

# Statement budgets per request, including authentication, tenant status and
# permission resolution, measured without Redis (the uncached worst case).
# Raising one requires a recorded reason in the O03 progress log.
QUERY_BUDGETS = {
    "fees.invoices": 10,
    "communication.broadcasts": 10,
    "messages.history": 11,
}

WINDOWS = ({"limit": 5}, {"limit": 50}, {"limit": 50, "offset": 100})


async def _assert_budget(client, report, name, url, headers):
    measurements = [await measure_endpoint(client, name, url, headers, params) for params in WINDOWS]
    for measurement in measurements:
        report.add(measurement)
        print(f"O03 {name} {measurement}")
    counts = {measurement.queries for measurement in measurements}
    assert len(counts) == 1, f"{name} statement count varies with page size: {measurements}"
    assert counts.pop() <= QUERY_BUDGETS[name], measurements
    assert [measurement.rows for measurement in measurements] == [5, 50, HISTORY_ROWS - 100]


async def test_invoice_history_query_budget(client, school):
    fixture = await seed_representative_invoice_fixture(client, school)
    report = MeasurementReport()
    await _assert_budget(
        client, report, "fees.invoices",
        f"{API}/schools/{fixture.local_school_id}/fees/invoices", school["hm"],
    )
    report.write_if_requested()


async def test_broadcast_and_direct_message_history_query_budgets(client, school):
    teacher = await create_user(client, school["id"], school["hm"], "teacher")
    student = await create_user(client, school["id"], school["hm"], "student")
    student_headers = await login(client, student["email"], student["password"])
    teacher_headers = await login(client, teacher["email"], teacher["password"])
    started = datetime(2026, 1, 1, tzinfo=timezone.utc)
    engine = create_async_engine(TEST_URL)
    try:
        async with async_sessionmaker(engine, expire_on_commit=False)() as db, db.begin():
            for index in range(HISTORY_ROWS):
                db.add(Message(
                    school_id=UUID(school["id"]),
                    title=f"Representative broadcast {index}",
                    body=f"broadcast-{index}",
                    channel="email",
                    audience_type="students",
                    status="pending",
                    created_at=started + timedelta(seconds=index),
                ))
                db.add(DirectMessage(
                    school_id=UUID(school["id"]),
                    sender_id=UUID(student["id"]),
                    recipient_id=UUID(teacher["id"]),
                    body=f"Representative direct message {index}",
                    created_at=started + timedelta(seconds=index),
                ))
    finally:
        await engine.dispose()

    report = MeasurementReport()
    await _assert_budget(
        client, report, "communication.broadcasts",
        f"{API}/schools/{school['id']}/communication/broadcasts", student_headers,
    )
    await _assert_budget(
        client, report, "messages.history",
        f"{API}/schools/{school['id']}/messages", teacher_headers,
    )
    report.write_if_requested()


async def test_school_scoped_request_loads_school_once(client, school):
    """Tenant status and permission gates share one School load per request."""
    url = f"{API}/schools/{school['id']}/fees/invoices"
    assert (await client.get(url, headers=school["hm"])).status_code == 200
    with count_queries() as recorder:
        response = await client.get(url, headers=school["hm"])
    assert response.status_code == 200
    school_loads = [sql for sql in recorder.statements if sql.lstrip().startswith("SELECT schools.")]
    assert len(school_loads) == 1, school_loads
    assert not any("count(*)" in sql for sql in recorder.statements)
