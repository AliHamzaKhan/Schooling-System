"""Invoice list pagination must be bounded after tenant filtering."""

from app.core.config import settings

from tests.test_broadcast_isolation import another_school
from tests.utils import create_user

API = settings.API_V1_PREFIX


async def _invoice(client, school_id, headers, student_id, title, due_date):
    response = await client.post(
        f"{API}/schools/{school_id}/fees/invoices",
        headers=headers,
        json={
            "student_id": student_id,
            "title": title,
            "amount": 1000,
            "due_date": due_date,
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


async def test_invoice_list_paginates_after_school_scope(client, school):
    """A foreign invoice never consumes a local invoice page slot."""
    school_id, headmaster = school["id"], school["hm"]
    local_student = await create_user(client, school_id, headmaster, "student")
    oldest = await _invoice(
        client, school_id, headmaster, local_student["id"], "Oldest", "2030-01-01",
    )
    newest = await _invoice(
        client, school_id, headmaster, local_student["id"], "Newest", "2030-01-02",
    )

    foreign_school_id = await another_school(client, school["sa"])
    foreign_student = await create_user(client, foreign_school_id, school["sa"], "student")
    await _invoice(
        client, foreign_school_id, school["sa"], foreign_student["id"], "Foreign", "2029-01-01",
    )

    first_page = await client.get(
        f"{API}/schools/{school_id}/fees/invoices",
        headers=headmaster,
        params={"limit": 1, "offset": 0},
    )
    assert first_page.status_code == 200, first_page.text
    assert [invoice["id"] for invoice in first_page.json()] == [oldest["id"]]

    second_page = await client.get(
        f"{API}/schools/{school_id}/fees/invoices",
        headers=headmaster,
        params={"limit": 1, "offset": 1},
    )
    assert [invoice["id"] for invoice in second_page.json()] == [newest["id"]]

    assert (await client.get(
        f"{API}/schools/{school_id}/fees/invoices",
        headers=headmaster,
        params={"limit": 101},
    )).status_code == 422
    assert (await client.get(
        f"{API}/schools/{school_id}/fees/invoices",
        headers=headmaster,
        params={"offset": -1},
    )).status_code == 422

    foreign_class = await client.post(
        f"{API}/schools/{foreign_school_id}/academic/classes",
        headers=school["sa"],
        json={"name": "Foreign grade"},
    )
    assert foreign_class.status_code == 201, foreign_class.text
    for path in ("invoices", "students"):
        denied = await client.get(
            f"{API}/schools/{school_id}/fees/{path}",
            headers=headmaster,
            params={"class_id": foreign_class.json()["id"]},
        )
        assert denied.status_code == 404, denied.text
