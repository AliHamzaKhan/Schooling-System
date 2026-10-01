"""Probe every school-scoped GET as family roles for an unrelated student's data."""
import json, os, re, httpx
API = "http://127.0.0.1:8000/api/v1"
ids = json.loads(open(os.path.join(os.environ.get('E2E_OUT', os.getcwd()), 'ids.txt')).read().strip().splitlines()[-1])
c = httpx.Client(timeout=30)
def tok(u, p): return {"Authorization": "Bearer " + c.post(f"{API}/auth/login", data={"username": u, "password": p}).json()["access_token"]}
hm = tok("head@chromeschool.edu", "HeadPass123")
sid = ids["school"]
stranger = [u for u in c.get(f"{API}/schools/{sid}/users", headers=hm, params={"role_code": "student", "limit": 200}).json() if u["email"] == "stranger@chromeschool.edu"][0]
sec = c.get(f"{API}/schools/{sid}/academic/classes", headers=hm).json()
# Give the stranger records in several modules so a leak would be visible.
c.post(f"{API}/schools/{sid}/sections/{ids['section']}/students", headers=hm, json={"student_id": stranger["id"]})
marker_ids = {stranger["id"]}
spec = c.get(f"{API}/openapi.json").json()
paths = [p for p, ops in spec["paths"].items() if "get" in ops and p.startswith("/api/v1/schools/{school_id}")]
callers = {"guardian": tok("guardian@chromeschool.edu", "Passw0rd1"), "student": tok("student@chromeschool.edu", "Passw0rd1")}
findings = []
for role, h in callers.items():
    for p in paths:
        params = re.findall(r"{(\w+)}", p)
        if any(x not in ("school_id", "student_id", "user_id") for x in params):
            continue
        url = "http://127.0.0.1:8000" + p.replace("{school_id}", sid).replace("{student_id}", stranger["id"]).replace("{user_id}", stranger["id"])
        query = {} if "{student_id}" in p else {"student_id": stranger["id"]}
        r = c.get(url, headers=h, params=query)
        if r.status_code == 200 and (stranger["id"] in r.text or "Unrelated Student" in r.text):
            findings.append(f"{role}: GET {p} params={query} -> 200 exposes stranger")
print(len(paths), "school GET paths probed")
print("\n".join(findings) or "no leaks found")
