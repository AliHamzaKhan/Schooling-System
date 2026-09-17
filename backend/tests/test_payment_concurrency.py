import asyncio
from uuid import UUID

import pytest
from sqlalchemy import select, text, update
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.models.fees import Invoice

from .conftest import API, TEST_URL
from .utils import create_user


async def make_invoice(client, school, amount=100):
    student = await create_user(client, school["id"], school["hm"], "student")
    response = await client.post(f"{API}/schools/{school['id']}/fees/invoices", headers=school["hm"], json={
        "student_id": student["id"], "title": "Concurrency test", "amount": amount, "due_date": "2027-01-01",
    })
    assert response.status_code == 201, response.text
    return response.json()["id"]


@pytest.mark.parametrize("amounts,expected_statuses,total", [
    ([75, 75], [201, 400], 75),
    ([30, 40], [201, 201], 70),
    ([100, 100], [201, 400], 100),
])
async def test_concurrent_payments_are_serialized(client, school, amounts, expected_statuses, total):
    iid = await make_invoice(client, school)
    path = f"{API}/schools/{school['id']}/fees/invoices/{iid}"
    engine = create_async_engine(TEST_URL)
    tasks = []
    try:
        async with async_sessionmaker(engine)() as blocker:
            await blocker.execute(select(Invoice).where(Invoice.id == UUID(iid)).with_for_update())
            tasks = [asyncio.create_task(client.post(path + "/payments", headers=school["hm"], json={
                "amount": amount, "method": "cash", "paid_on": "2026-09-14",
            })) for amount in amounts]

            # Wait until both requests contend on the database lock, rather than
            # relying on request timing to accidentally reproduce a race.
            async def wait_for_contention():
                async with engine.connect() as observer:
                    while True:
                        count = await observer.scalar(text("""
                            SELECT count(*) FROM pg_stat_activity
                            WHERE datname=current_database() AND usename=current_user
                              AND wait_event_type='Lock'
                        """))
                        await observer.commit()  # refresh PostgreSQL's statistics snapshot
                        if count >= 2:
                            return
                        await asyncio.sleep(0.02)

            await asyncio.wait_for(wait_for_contention(), timeout=10)
            await blocker.commit()
        responses = await asyncio.gather(*tasks)
        assert sorted(r.status_code for r in responses) == expected_statuses, [r.text for r in responses]
        receipt = await client.get(path + "/receipt", headers=school["hm"])
        assert receipt.status_code == 200, receipt.text
        body = receipt.json()
        assert sum(p["amount"] for p in body["payments"]) == total
        assert body["total_paid"] == total
        assert body["invoice"]["amount_paid"] == total
        assert body["invoice"]["balance"] == 100 - total
    finally:
        for task in tasks:
            if not task.done():
                task.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)
        await engine.dispose()


async def test_cached_balance_cannot_allow_payment_beyond_ledger(client, school):
    iid = await make_invoice(client, school)
    path = f"{API}/schools/{school['id']}/fees/invoices/{iid}"
    payload = {"amount": 80, "method": "cash", "paid_on": "2026-09-14"}
    first = await client.post(path + "/payments", headers=school["hm"], json=payload)
    assert first.status_code == 201, first.text
    engine = create_async_engine(TEST_URL)
    try:
        async with engine.begin() as db:
            await db.execute(update(Invoice).where(Invoice.id == UUID(iid)).values(amount_paid=0))
    finally:
        await engine.dispose()
    second = await client.post(path + "/payments", headers=school["hm"], json=payload | {"amount": 30})
    assert second.status_code == 400, second.text
    receipt = await client.get(path + "/receipt", headers=school["hm"])
    assert receipt.json()["total_paid"] == 80
    assert receipt.json()["invoice"]["amount_paid"] == 80
    assert receipt.json()["invoice"]["balance"] == 20
    assert len(receipt.json()["payments"]) == 1


@pytest.mark.parametrize("amount", ["Infinity", "NaN", "-Infinity"])
async def test_non_finite_money_is_rejected(client, school, amount):
    iid = await make_invoice(client, school)
    path = f"{API}/schools/{school['id']}/fees/invoices/{iid}"
    response = await client.post(path + "/payments", headers=school["hm"], json={
        "amount": amount, "method": "cash", "paid_on": "2026-09-14",
    })
    assert response.status_code == 422, response.text
    receipt = await client.get(path + "/receipt", headers=school["hm"])
    assert receipt.json()["payments"] == []
