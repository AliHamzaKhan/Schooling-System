"""Executable O03 proof for the tenant-fair representative fixture.

Run only through ``scripts/run_isolated_tests.py`` as documented in
``tests.representative_fixture``.  The test asserts a full two-page history,
a partial tail, and foreign rows whose due dates would otherwise displace
local entries.
"""
from app.core.config import settings

from tests.representative_fixture import (
    REPRESENTATIVE_FOREIGN_INVOICES,
    REPRESENTATIVE_VISIBLE_INVOICES,
    seed_representative_invoice_fixture,
)


API = settings.API_V1_PREFIX


async def test_representative_invoice_fixture_keeps_pages_tenant_fair(client, school):
    fixture = await seed_representative_invoice_fixture(client, school)
    invoices_url = f"{API}/schools/{fixture.local_school_id}/fees/invoices"

    first = await client.get(invoices_url, headers=school["hm"], params={"limit": fixture.page_size})
    second = await client.get(
        invoices_url,
        headers=school["hm"],
        params={"limit": fixture.page_size, "offset": fixture.page_size},
    )
    tail = await client.get(
        invoices_url,
        headers=school["hm"],
        params={"limit": fixture.page_size, "offset": fixture.page_size * 2},
    )
    assert first.status_code == second.status_code == tail.status_code == 200

    ids = fixture.local_invoice_ids
    first_ids = [invoice["id"] for invoice in first.json()]
    second_ids = [invoice["id"] for invoice in second.json()]
    tail_ids = [invoice["id"] for invoice in tail.json()]
    assert first_ids == list(ids[: fixture.page_size])
    assert second_ids == list(ids[fixture.page_size : fixture.page_size * 2])
    assert tail_ids == list(ids[fixture.page_size * 2 :])
    assert len(first_ids) == len(second_ids) == fixture.page_size
    assert len(tail_ids) == REPRESENTATIVE_VISIBLE_INVOICES % fixture.page_size
    assert not set(first_ids + second_ids + tail_ids).intersection(fixture.foreign_invoice_ids)
    assert len(ids) == REPRESENTATIVE_VISIBLE_INVOICES
    assert len(fixture.foreign_invoice_ids) == REPRESENTATIVE_FOREIGN_INVOICES
