"""Subscription billing tests: plan CRUD, discounted assignment + payment ledger,
per-school status, and the Super Admin dashboard / revenue metrics.

These back the admin-portal Dashboard (live KPIs), the subscription-management
tabs (all/active/pending/history), and the Headmaster expiry alert.
"""
from datetime import date
from uuid import uuid4

from app.core.config import settings

API = settings.API_V1_PREFIX


def _add_months(start: date, months: int) -> date:
    import calendar

    zero = start.month - 1 + months
    year = start.year + zero // 12
    month = zero % 12 + 1
    day = min(start.day, calendar.monthrange(year, month)[1])
    return date(year, month, day)


async def _create_plan(client, sa, **overrides) -> dict:
    payload = {"name": "Plan " + uuid4().hex[:6], "price": 1000, "billing_period": "monthly"}
    payload.update(overrides)
    r = await client.post(f"{API}/subscription-plans", headers=sa, json=payload)
    assert r.status_code == 201, r.text
    return r.json()


# ------------------------------ plans ----------------------------------- #


async def test_seeded_plans_have_prices(client, sa_headers):
    r = await client.get(f"{API}/subscription-plans", headers=sa_headers)
    assert r.status_code == 200, r.text
    plans = r.json()
    assert plans, "seed should create the basic/standard/premium plans"
    assert all(p["price"] >= 0 for p in plans)
    assert {"monthly", "six_month", "annual"} >= {p["billing_period"] for p in plans}


async def test_create_update_archive_plan(client, sa_headers):
    plan = await _create_plan(client, sa_headers, name="Annual Gold", price=5000, billing_period="annual")
    assert plan["billing_period"] == "annual"
    assert plan["is_active"] is True
    assert plan["code"]  # auto-slugged

    pid = plan["id"]
    r = await client.patch(
        f"{API}/subscription-plans/{pid}", headers=sa_headers, json={"price": 5500}
    )
    assert r.status_code == 200, r.text
    assert r.json()["price"] == 5500

    r = await client.delete(f"{API}/subscription-plans/{pid}", headers=sa_headers)
    assert r.status_code == 200 and r.json()["is_active"] is False
    # Archived plan is hidden from the default list.
    r = await client.get(f"{API}/subscription-plans", headers=sa_headers)
    assert pid not in {p["id"] for p in r.json()}


async def test_plans_require_super_admin(client, school):
    r = await client.get(f"{API}/subscription-plans", headers=school["hm"])
    assert r.status_code == 403


# ------------------------- assignment + discounts ----------------------- #


async def test_assign_percent_discount_creates_payment(client, sa_headers, school):
    plan = await _create_plan(client, sa_headers, price=1000, billing_period="six_month")
    r = await client.post(
        f"{API}/subscriptions",
        headers=sa_headers,
        json={
            "school_id": school["id"],
            "plan_id": plan["id"],
            "discount_type": "percent",
            "discount_value": 10,
        },
    )
    assert r.status_code == 201, r.text
    sub = r.json()
    assert sub["net_amount"] == 900.0  # 1000 - 10%
    assert sub["status"] == "active"
    assert sub["end_date"] == _add_months(date.today(), 6).isoformat()

    # Revenue ledger picked up the net amount this month.
    rev = await client.get(f"{API}/admin/revenue", headers=sa_headers)
    assert rev.status_code == 200
    assert rev.json()["total"] >= 900.0


async def test_assign_fixed_discount(client, sa_headers, school):
    plan = await _create_plan(client, sa_headers, price=800)
    r = await client.post(
        f"{API}/subscriptions",
        headers=sa_headers,
        json={
            "school_id": school["id"],
            "plan_id": plan["id"],
            "discount_type": "fixed",
            "discount_value": 150,
        },
    )
    assert r.status_code == 201, r.text
    assert r.json()["net_amount"] == 650.0  # 800 - 150


async def test_pending_assignment_records_no_payment(client, sa_headers, school):
    plan = await _create_plan(client, sa_headers, price=500)
    r = await client.post(
        f"{API}/subscriptions",
        headers=sa_headers,
        json={"school_id": school["id"], "plan_id": plan["id"], "activate": False},
    )
    assert r.status_code == 201
    assert r.json()["status"] == "pending"

    pend = await client.get(f"{API}/subscriptions?status_filter=pending", headers=sa_headers)
    assert r.json()["id"] in {s["id"] for s in pend.json()}


# ------------------------------ tabs / lists ---------------------------- #


async def test_list_filters(client, sa_headers, school):
    plan = await _create_plan(client, sa_headers, price=300)
    await client.post(
        f"{API}/subscriptions",
        headers=sa_headers,
        json={"school_id": school["id"], "plan_id": plan["id"]},
    )
    for f in ("all", "active", "pending", "history"):
        r = await client.get(f"{API}/subscriptions?status_filter={f}", headers=sa_headers)
        assert r.status_code == 200, r.text
    active = await client.get(f"{API}/subscriptions?status_filter=active", headers=sa_headers)
    assert all(s["status"] == "active" for s in active.json())


async def test_renew_and_cancel(client, sa_headers, school):
    plan = await _create_plan(client, sa_headers, price=400, billing_period="monthly")
    sub = (
        await client.post(
            f"{API}/subscriptions",
            headers=sa_headers,
            json={"school_id": school["id"], "plan_id": plan["id"]},
        )
    ).json()
    end_before = date.fromisoformat(sub["end_date"])

    r = await client.post(f"{API}/subscriptions/{sub['id']}/renew", headers=sa_headers, json={})
    assert r.status_code == 200, r.text
    assert date.fromisoformat(r.json()["end_date"]) > end_before

    r = await client.post(f"{API}/subscriptions/{sub['id']}/cancel", headers=sa_headers)
    assert r.status_code == 200 and r.json()["status"] == "cancelled"


# ------------------------------ status ---------------------------------- #


async def test_school_status_for_headmaster(client, sa_headers, school):
    plan = await _create_plan(client, sa_headers, price=1000)
    await client.post(
        f"{API}/subscriptions",
        headers=sa_headers,
        json={"school_id": school["id"], "plan_id": plan["id"]},
    )
    r = await client.get(
        f"{API}/schools/{school['id']}/subscription/status", headers=school["hm"]
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["has_subscription"] is True
    assert body["status"] == "active"
    assert body["days_remaining"] is not None


async def test_status_blocked_for_other_school(client, sa_headers, school):
    other = uuid4()
    r = await client.get(
        f"{API}/schools/{other}/subscription/status", headers=school["hm"]
    )
    assert r.status_code == 403


# ------------------------------ dashboard ------------------------------- #


async def test_admin_dashboard(client, sa_headers, school):
    plan = await _create_plan(client, sa_headers, price=1200)
    await client.post(
        f"{API}/subscriptions",
        headers=sa_headers,
        json={"school_id": school["id"], "plan_id": plan["id"]},
    )
    r = await client.get(f"{API}/admin/dashboard", headers=sa_headers)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["total_schools"] >= 1
    assert body["active_subscriptions"] >= 1
    assert body["monthly_revenue"] >= 1200.0


# ------------------------------ billing + metrics ----------------------- #


async def test_admin_billing(client, sa_headers, school):
    plan = await _create_plan(client, sa_headers, price=1000)
    await client.post(
        f"{API}/subscriptions",
        headers=sa_headers,
        json={"school_id": school["id"], "plan_id": plan["id"]},
    )
    r = await client.get(f"{API}/admin/billing", headers=sa_headers)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["total_revenue"] >= 1000.0
    assert body["payment_count"] >= 1
    assert len(body["recent"]) >= 1
    assert body["recent"][0]["school_name"] is not None


async def test_admin_transactions(client, sa_headers, school):
    plan = await _create_plan(client, sa_headers, price=1000)
    await client.post(
        f"{API}/subscriptions",
        headers=sa_headers,
        json={"school_id": school["id"], "plan_id": plan["id"]},
    )
    for rng in ("month", "year", "all"):
        r = await client.get(
            f"{API}/admin/transactions", headers=sa_headers, params={"range": rng}
        )
        assert r.status_code == 200, r.text
        body = r.json()
        assert body["range"] == rng
        assert body["count"] >= 1
        assert body["total"] >= 1000.0
        assert len(body["transactions"]) >= 1
        assert body["transactions"][0]["school_name"] is not None
        # The chart series buckets sum to the range total.
        assert sum(b["count"] for b in body["buckets"]) == body["count"]


async def test_transactions_require_super_admin(client, school):
    r = await client.get(f"{API}/admin/transactions", headers=school["hm"])
    assert r.status_code == 403


async def test_admin_metrics(client, sa_headers, school):
    plan = await _create_plan(client, sa_headers, price=1200)
    await client.post(
        f"{API}/subscriptions",
        headers=sa_headers,
        json={"school_id": school["id"], "plan_id": plan["id"]},
    )
    r = await client.get(f"{API}/admin/metrics", headers=sa_headers)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["total_schools"] >= 1
    assert body["total_users"] >= 1
    assert body["active_subscriptions"] >= 1
    assert any(p["count"] >= 1 for p in body["plan_distribution"])


async def test_school_payments_ledger(client, sa_headers, school):
    plan = await _create_plan(client, sa_headers, price=1200, billing_period="monthly")
    r = await client.post(
        f"{API}/subscriptions",
        headers=sa_headers,
        json={"school_id": school["id"], "plan_id": plan["id"]},
    )
    assert r.status_code == 201, r.text

    pays = await client.get(f"{API}/schools/{school['id']}/payments", headers=sa_headers)
    assert pays.status_code == 200, pays.text
    rows = pays.json()
    assert len(rows) == 1
    assert rows[0]["amount"] == 1200.0
    assert rows[0]["plan_name"] == plan["name"]
    assert rows[0]["status"] == "paid"


async def test_school_payments_require_super_admin(client, school):
    r = await client.get(f"{API}/schools/{school['id']}/payments", headers=school["hm"])
    assert r.status_code == 403


# --------------------------- student cap enforcement -------------------- #


async def _make_student(client, sid, hm):
    from uuid import uuid4 as _u
    email = f"student-{_u().hex[:8]}@test.edu"
    return await client.post(
        f"{API}/schools/{sid}/users",
        headers=hm,
        json={
            "email": email,
            "password": "Passw0rd1",
            "full_name": "Cap Student",
            "role_codes": ["student"],
        },
    )


async def test_plan_and_subscription_carry_max_students(client, sa_headers, school):
    plan = await _create_plan(client, sa_headers, price=500, max_students=3,
                              modules=["student_management"])
    assert plan["max_students"] == 3
    r = await client.post(
        f"{API}/subscriptions",
        headers=sa_headers,
        json={"school_id": school["id"], "plan_id": plan["id"]},
    )
    assert r.status_code == 201, r.text
    # Cap is snapshot onto the subscription from the plan.
    assert r.json()["max_students"] == 3


async def test_student_cap_blocks_over_limit_and_frees_on_delete(client, sa_headers, school):
    plan = await _create_plan(client, sa_headers, price=500, max_students=2,
                              modules=["student_management"])
    r = await client.post(
        f"{API}/subscriptions",
        headers=sa_headers,
        json={"school_id": school["id"], "plan_id": plan["id"]},
    )
    assert r.status_code == 201, r.text

    sid, hm = school["id"], school["hm"]
    # Two students fit …
    s1 = await _make_student(client, sid, hm)
    assert s1.status_code == 201, s1.text
    s2 = await _make_student(client, sid, hm)
    assert s2.status_code == 201, s2.text
    # … the third is blocked by the cap.
    s3 = await _make_student(client, sid, hm)
    assert s3.status_code == 403, s3.text

    # Status reports live usage against the cap.
    st = await client.get(f"{API}/schools/{sid}/subscription/status", headers=hm)
    assert st.status_code == 200, st.text
    body = st.json()
    assert body["max_students"] == 2
    assert body["current_students"] == 2

    # Deactivating a student frees a slot, so a new one can be created again.
    d = await client.post(
        f"{API}/schools/{sid}/users/{s1.json()['id']}/deactivate", headers=hm
    )
    assert d.status_code == 200, d.text
    s4 = await _make_student(client, sid, hm)
    assert s4.status_code == 201, s4.text


async def test_unlimited_plan_never_blocks_students(client, sa_headers, school):
    plan = await _create_plan(client, sa_headers, price=500,  # no max_students → unlimited
                              modules=["student_management"])
    assert plan["max_students"] is None
    r = await client.post(
        f"{API}/subscriptions",
        headers=sa_headers,
        json={"school_id": school["id"], "plan_id": plan["id"]},
    )
    assert r.status_code == 201, r.text
    sid, hm = school["id"], school["hm"]
    for _ in range(3):
        s = await _make_student(client, sid, hm)
        assert s.status_code == 201, s.text
