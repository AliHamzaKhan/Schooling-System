"""Payment retries preserve a single durable ledger identity."""
import asyncio
from uuid import UUID, uuid4
from unittest.mock import patch

import pytest
from fastapi import HTTPException
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.models.fees import Invoice
from app.modules.fees.service import FeeService
from tests.conftest import API, TEST_URL
from tests.test_payment_concurrency import make_invoice
from tests.utils import create_user, login

PAYLOAD = {"amount": 30, "method": "cash", "paid_on": "2026-09-14"}


def endpoint(school, invoice):
    return f"{API}/schools/{school['id']}/fees/invoices/{invoice}"


@pytest.mark.parametrize("amount", [30, 100])
async def test_retry_returns_original_payment_even_after_full_payment(client, school, amount):
    path = endpoint(school, await make_invoice(client, school))
    key = str(uuid4())
    headers = school["hm"] | {"Idempotency-Key": key}
    body = PAYLOAD | {"amount": amount, "reference": "receipt ref", "note": "cash desk"}
    original = await client.post(path + "/payments", headers=headers, json=body)
    assert original.status_code == 201, original.text
    for _ in range(2):
        retried = await client.post(path + "/payments", headers=headers, json=body)
        assert retried.status_code == 201, retried.text
        assert retried.json() == original.json()
        assert retried.json()["id"] == key
    receipt = (await client.get(path + "/receipt", headers=school["hm"])).json()
    assert len(receipt["payments"]) == 1
    assert receipt["total_paid"] == amount
    assert receipt["invoice"]["amount_paid"] == amount


@pytest.mark.parametrize("changed", [
    {"amount": 31}, {"method": "bank_transfer"}, {"paid_on": "2026-09-15"},
    {"reference": "changed"}, {"note": "changed"},
])
async def test_key_reuse_with_changed_details_is_conflict(client, school, changed):
    path = endpoint(school, await make_invoice(client, school))
    headers = school["hm"] | {"Idempotency-Key": str(uuid4())}
    assert (await client.post(path + "/payments", headers=headers, json=PAYLOAD)).status_code == 201
    changed_response = await client.post(path + "/payments", headers=headers, json=PAYLOAD | changed)
    assert changed_response.status_code == 409, changed_response.text
    receipt = (await client.get(path + "/receipt", headers=school["hm"])).json()
    assert receipt["total_paid"] == 30 and len(receipt["payments"]) == 1


@pytest.mark.parametrize("same_payload", [True, False])
async def test_overlapping_retries_wait_and_deduplicate(client, school, same_payload):
    iid = await make_invoice(client, school)
    path = endpoint(school, iid)
    headers = school["hm"] | {"Idempotency-Key": str(uuid4())}
    engine = create_async_engine(TEST_URL)
    tasks = []
    try:
        async with async_sessionmaker(engine)() as blocker:
            await blocker.execute(select(Invoice).where(Invoice.id == UUID(iid)).with_for_update())
            tasks = [asyncio.create_task(client.post(path + "/payments", headers=headers, json=body))
                     for body in (PAYLOAD, PAYLOAD | {"amount": 30 if same_payload else 40})]
            async def wait_for_locks():
                async with engine.connect() as observer:
                    while True:
                        count = await observer.scalar(text("""
                            SELECT count(*) FROM pg_stat_activity
                            WHERE datname=current_database() AND usename=current_user
                              AND wait_event_type='Lock'
                        """))
                        await observer.commit()
                        if count >= 2:
                            return
                        await asyncio.sleep(0.02)
            await asyncio.wait_for(wait_for_locks(), 10)
            await blocker.commit()
        results = await asyncio.gather(*tasks)
        assert sorted(r.status_code for r in results) == ([201, 201] if same_payload else [201, 409])
        successes = [r.json() for r in results if r.status_code == 201]
        assert len({p["id"] for p in successes}) == 1
        receipt = (await client.get(path + "/receipt", headers=school["hm"])).json()
        assert len(receipt["payments"]) == 1
        assert receipt["total_paid"] == successes[0]["amount"]
    finally:
        for task in tasks:
            if not task.done():
                task.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)
        await engine.dispose()


async def test_key_cannot_be_reused_for_other_invoice_or_actor(client, school):
    first = endpoint(school, await make_invoice(client, school))
    second = endpoint(school, await make_invoice(client, school))
    key = str(uuid4())
    headers = school["hm"] | {"Idempotency-Key": key}
    assert (await client.post(first + "/payments", headers=headers, json=PAYLOAD)).status_code == 201
    assert (await client.post(second + "/payments", headers=headers, json=PAYLOAD)).status_code == 409
    assert (await client.post(first + "/payments", headers=school["sa"] | {"Idempotency-Key": key}, json=PAYLOAD)).status_code == 409
    student = await create_user(client, school["id"], school["hm"], "student")
    sh = await login(client, student["email"], student["password"])
    assert (await client.post(first + "/payments", headers=sh | {"Idempotency-Key": key}, json=PAYLOAD)).status_code == 403
    assert (await client.get(second + "/receipt", headers=school["hm"])).json()["payments"] == []
    wrong_school = first.replace(school["id"], str(uuid4()))
    assert (await client.post(wrong_school + "/payments", headers=headers, json=PAYLOAD)).status_code == 403
    assert (await client.post(wrong_school + "/payments", headers=school["sa"] | {"Idempotency-Key": key}, json=PAYLOAD)).status_code == 404


async def test_failed_transaction_does_not_consume_key(client, school):
    path = endpoint(school, await make_invoice(client, school))
    headers = school["hm"] | {"Idempotency-Key": str(uuid4())}
    original = FeeService.record_payment
    async def fail_after_flush(self, *args, **kwargs):
        await original(self, *args, **kwargs)
        raise HTTPException(503, "Simulated failure before commit")
    with patch.object(FeeService, "record_payment", fail_after_flush):
        assert (await client.post(path + "/payments", headers=headers, json=PAYLOAD)).status_code == 503
    assert (await client.get(path + "/receipt", headers=school["hm"])).json()["payments"] == []
    retried = await client.post(path + "/payments", headers=headers, json=PAYLOAD)
    assert retried.status_code == 201, retried.text
    assert len((await client.get(path + "/receipt", headers=school["hm"])).json()["payments"]) == 1


async def test_distinct_keys_allow_deliberate_partial_payments_and_invalid_key_fails(client, school):
    path = endpoint(school, await make_invoice(client, school))
    invalid = await client.post(path + "/payments", headers=school["hm"] | {"Idempotency-Key": "not-a-uuid"}, json=PAYLOAD)
    assert invalid.status_code == 422
    ids = []
    for _ in range(2):
        response = await client.post(path + "/payments", headers=school["hm"] | {"Idempotency-Key": str(uuid4())}, json=PAYLOAD)
        assert response.status_code == 201, response.text
        ids.append(response.json()["id"])
    assert ids[0] != ids[1]
    receipt = (await client.get(path + "/receipt", headers=school["hm"])).json()
    assert receipt["total_paid"] == 60 and len(receipt["payments"]) == 2
