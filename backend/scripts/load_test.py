"""Seed a representative school and measure API latency under concurrent load.

Two steps, against a running API (never production)::

    # 1. Synthetic school: classes x sections x students, invoices, attendance.
    python scripts/load_test.py seed --api http://127.0.0.1:8000/api/v1 \
        --admin-email admin@platform.com --admin-password '...' --state /tmp/load.json

    # 2. Concurrent mixed-role traffic for a fixed duration.
    python scripts/load_test.py run --state /tmp/load.json --users 50 --seconds 60

``run`` prints p50/p95/p99 and error counts per endpoint group and checks them
against the targets in ``TARGETS_MS`` (exit 1 if a target is missed). Accounts
are synthetic; no real school data is used. Each virtual user signs in once,
so login rate limits are not exercised.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import random
import statistics
import time
import uuid
from datetime import date, timedelta

import httpx

# p95 targets per endpoint group (milliseconds) for the representative school
# at the agreed concurrency. See docs/OPERATIONS_RUNBOOK.md "Speed targets".
TARGETS_MS = {"dashboard": 500, "list": 400, "detail": 300, "report": 800}
PASSWORD = "LoadTest123"


async def _login(client: httpx.AsyncClient, api: str, email: str, password: str) -> dict[str, str]:
    for attempt in range(8):
        response = await client.post(f"{api}/auth/login", data={"username": email, "password": password})
        if response.status_code == 429:
            await asyncio.sleep(2 ** min(attempt, 4))
            continue
        response.raise_for_status()
        return {"Authorization": f"Bearer {response.json()['access_token']}"}
    raise RuntimeError("login stayed rate limited")


def _ok(response: httpx.Response) -> dict | list:
    if response.status_code >= 400:
        raise RuntimeError(f"{response.request.method} {response.request.url.path} -> {response.status_code}: {response.text[:300]}")
    return response.json()


async def seed(args) -> None:
    api = args.api.rstrip("/")
    tag = uuid.uuid4().hex[:6]
    async with httpx.AsyncClient(timeout=60, trust_env=False) as client:
        sa = await _login(client, api, args.admin_email, args.admin_password)
        school = _ok(await client.post(f"{api}/schools", headers=sa, json={"name": f"Load School {tag}", "code": f"L-{tag}"}))
        sid = school["id"]
        _ok(await client.post(f"{api}/schools/{sid}/subscription", headers=sa, json={"plan_code": "premium"}))
        _ok(await client.post(f"{api}/schools/{sid}/status", headers=sa, json={"status": "active"}))
        head_email = f"head-{tag}@loadschool.edu"
        _ok(await client.post(f"{api}/schools/{sid}/headmaster", headers=sa,
                              json={"email": head_email, "password": PASSWORD, "full_name": "Load Head"}))
        hm = await _login(client, api, head_email, PASSWORD)
        base = f"{api}/schools/{sid}"
        semaphore = asyncio.Semaphore(args.parallel)

        async def user(role: str, index: int) -> dict:
            email = f"{role}-{index}-{tag}@loadschool.edu"
            async with semaphore:
                body = _ok(await client.post(f"{base}/users", headers=hm, json={
                    "email": email, "password": PASSWORD, "full_name": f"{role.title()} {index}", "role_codes": [role],
                }))
            return {"id": body["id"], "email": email}

        teachers = await asyncio.gather(*(user("teacher", i) for i in range(args.classes)))
        subject = _ok(await client.post(f"{base}/academic/subjects", headers=hm, json={"code": "MATH", "name": "Mathematics"}))
        sections, students = [], []
        for c in range(args.classes):
            klass = _ok(await client.post(f"{base}/academic/classes", headers=hm, json={"name": f"Grade {c + 1}", "level": c + 1}))
            for s in range(args.sections):
                section = _ok(await client.post(f"{base}/academic/classes/{klass['id']}/sections", headers=hm, json={
                    "name": chr(65 + s), "class_teacher_id": teachers[c]["id"] if s == 0 else None,
                }))
                roster = await asyncio.gather(*(user("student", len(students) + i) for i in range(args.students)))
                for student in roster:
                    async with semaphore:
                        _ok(await client.post(f"{base}/sections/{section['id']}/students", headers=hm, json={"student_id": student["id"]}))
                sections.append({"id": section["id"], "class_id": klass["id"], "teacher": teachers[c], "students": roster})
                students.extend(roster)
            for month in range(args.invoice_months):
                _ok(await client.post(f"{base}/fees/invoices/bulk", headers=hm, json={
                    "class_id": klass["id"], "title": f"Tuition month {month + 1}", "amount": 1000,
                    "due_date": (date.today() - timedelta(days=30 * (args.invoice_months - month))).isoformat(),
                }))
        guardians = await asyncio.gather(*(user("guardian", i) for i in range(args.guardians)))
        for index, guardian in enumerate(guardians):
            for child in students[index * 2:index * 2 + 2]:
                _ok(await client.post(f"{base}/guardians/{guardian['id']}/children", headers=hm, json={"student_id": child["id"]}))
        teacher_headers: dict[str, dict] = {}
        for section in sections:
            if section["teacher"]["id"] not in teacher_headers:
                teacher_headers[section["teacher"]["id"]] = await _login(client, api, section["teacher"]["email"], PASSWORD)
            for day in range(args.attendance_days):
                when = date.today() - timedelta(days=day + 1)
                _ok(await client.post(f"{base}/attendance", headers=hm, json={
                    "section_id": section["id"], "attendance_date": when.isoformat(),
                    "entries": [{"student_id": s["id"], "status": random.choice(["present"] * 9 + ["absent"])} for s in section["students"]],
                }))
    state = {
        "api": api, "school_id": sid, "headmaster": head_email, "subject_id": subject["id"],
        "teachers": [t["email"] for t in teachers],
        "teacher_sections": {s["teacher"]["email"]: s["id"] for s in sections if s["id"]},
        "guardians": [g["email"] for g in guardians],
        "students": [{"id": s["id"], "email": s["email"]} for s in students[: max(args.guardians * 2, 20)]],
        "student_ids": [s["id"] for s in students], "section_ids": [s["id"] for s in sections],
        "size": {"classes": args.classes, "sections": len(sections), "students": len(students),
                 "invoices": len(students) * args.invoice_months, "attendance_records": len(students) * args.attendance_days},
    }
    with open(args.state, "w", encoding="utf-8") as handle:
        json.dump(state, handle, indent=2)
    print(json.dumps(state["size"]))


def _scenarios(state: dict) -> dict[str, list]:
    base = f"/schools/{state['school_id']}"
    student_id = lambda: random.choice(state["student_ids"])  # noqa: E731
    homeroom = state["teacher_sections"].get  # a teacher reads only their own section
    return {
        "headmaster": [
            ("dashboard", lambda me: f"{base}/reports/overview"),
            ("list", lambda me: f"{base}/fees/invoices?limit=50&status=overdue"),
            ("list", lambda me: f"{base}/fees/students?limit=20"),
            ("report", lambda me: f"{base}/reports/finance"),
            ("report", lambda me: f"{base}/reports/attendance"),
            ("detail", lambda me: f"{base}/students/{student_id()}/attendance?limit=30"),
            ("list", lambda me: f"{base}/leave/requests?limit=20"),
        ],
        "teacher": [
            ("dashboard", lambda me: f"{base}/academic/me/dashboard"),
            ("list", lambda me: f"{base}/academic/me/sections"),
            ("list", lambda me: f"{base}/sections/{homeroom(me)}/students"),
            ("list", lambda me: f"{base}/homework/assignments?limit=20"),
            ("list", lambda me: f"{base}/attendance?section_id={homeroom(me)}&attendance_date={(date.today() - timedelta(days=1)).isoformat()}"),
        ],
        "guardian": [
            ("dashboard", lambda me: f"{base}/me/children"),
            ("list", lambda me: f"{base}/fees/invoices?limit=20"),
            ("list", lambda me: f"{base}/communication/broadcasts?limit=20"),
        ],
        "student": [
            ("dashboard", lambda me: f"{base}/academic/me/dashboard"),
            ("list", lambda me: f"{base}/homework/assignments?limit=20"),
            ("list", lambda me: f"{base}/exams?limit=20"),
        ],
    }


async def run(args) -> int:
    with open(args.state, encoding="utf-8") as handle:
        state = json.load(handle)
    api = state["api"]
    scenarios = _scenarios(state)
    mix = ["headmaster"] * 1 + ["teacher"] * 3 + ["guardian"] * 4 + ["student"] * 2
    samples: dict[tuple[str, str], list[float]] = {}
    errors: dict[tuple[str, str], int] = {}
    limits = httpx.Limits(max_connections=args.users, max_keepalive_connections=args.users)
    async with httpx.AsyncClient(base_url=api, timeout=30, limits=limits, trust_env=False) as client:
        accounts = {
            "headmaster": [state["headmaster"]], "teacher": state["teachers"],
            "guardian": state["guardians"], "student": [s["email"] for s in state["students"]],
        }
        tokens: dict[str, dict] = {}

        async def headers_for(role: str, index: int) -> tuple[str, dict]:
            email = accounts[role][index % len(accounts[role])]
            if email not in tokens:
                tokens[email] = await _login(client, api, email, PASSWORD)
            return email, tokens[email]

        roles = [mix[i % len(mix)] for i in range(args.users)]
        prepared = [await headers_for(role, i) for i, role in enumerate(roles)]
        deadline = time.perf_counter() + args.seconds

        async def virtual_user(role: str, email: str, headers: dict) -> None:
            while time.perf_counter() < deadline:
                group, path = random.choice(scenarios[role])
                key = (role, group)
                started = time.perf_counter()
                try:
                    response = await client.get(path(email), headers=headers)
                    failed = response.status_code >= 400
                except httpx.HTTPError:
                    failed = True
                samples.setdefault(key, []).append((time.perf_counter() - started) * 1000)
                if failed:
                    errors[key] = errors.get(key, 0) + 1
                await asyncio.sleep(random.uniform(0, args.think_ms / 1000))

        started = time.perf_counter()
        await asyncio.gather(*(virtual_user(role, *prepared[i]) for i, role in enumerate(roles)))
        elapsed = time.perf_counter() - started

    def pct(values: list[float], q: float) -> float:
        ordered = sorted(values)
        return round(ordered[min(len(ordered) - 1, int(q * len(ordered)))], 1)

    rows, missed = [], []
    by_group: dict[str, list[float]] = {}
    for (role, group), values in sorted(samples.items()):
        by_group.setdefault(group, []).extend(values)
        rows.append({"role": role, "group": group, "requests": len(values), "errors": errors.get((role, group), 0),
                     "p50_ms": round(statistics.median(values), 1), "p95_ms": pct(values, 0.95), "p99_ms": pct(values, 0.99)})
    groups = {}
    for group, values in sorted(by_group.items()):
        p95 = pct(values, 0.95)
        groups[group] = {"requests": len(values), "p95_ms": p95, "target_ms": TARGETS_MS[group], "met": p95 <= TARGETS_MS[group]}
        if p95 > TARGETS_MS[group]:
            missed.append(group)
    total = sum(len(v) for v in samples.values())
    total_errors = sum(errors.values())
    report = {"size": state["size"], "users": args.users, "seconds": round(elapsed, 1), "requests": total,
              "throughput_rps": round(total / elapsed, 1), "error_rate": round(total_errors / max(total, 1), 4),
              "groups": groups, "detail": rows}
    print(json.dumps(report, indent=2))
    return 1 if missed or total_errors / max(total, 1) > 0.01 else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    s = sub.add_parser("seed")
    s.add_argument("--api", default="http://127.0.0.1:8000/api/v1")
    s.add_argument("--admin-email", required=True)
    s.add_argument("--admin-password", required=True)
    s.add_argument("--state", required=True)
    s.add_argument("--classes", type=int, default=10)
    s.add_argument("--sections", type=int, default=2)
    s.add_argument("--students", type=int, default=30, help="students per section")
    s.add_argument("--guardians", type=int, default=50)
    s.add_argument("--invoice-months", type=int, default=3)
    s.add_argument("--attendance-days", type=int, default=20)
    s.add_argument("--parallel", type=int, default=8)
    r = sub.add_parser("run")
    r.add_argument("--state", required=True)
    r.add_argument("--users", type=int, default=50)
    r.add_argument("--seconds", type=int, default=60)
    r.add_argument("--think-ms", type=int, default=500, help="max pause between a user's requests")
    args = parser.parse_args()
    if args.command == "seed":
        asyncio.run(seed(args))
        return 0
    return asyncio.run(run(args))


if __name__ == "__main__":
    raise SystemExit(main())
