"""Probe id-keyed school GETs as family roles for an unrelated student's data.

Ids are harvested per resource type (``{exam_id}`` -> ids seen under paths
containing ``exam``) from the headmaster's view, two hops deep, so nested
resources such as papers, marks and results are reached. Any 200 response to
the synthetic guardian or student that contains the unrelated student's id or
name is reported.
"""
import json, os, re, httpx
API = "http://127.0.0.1:8000"
OUT = os.environ.get("E2E_OUT", os.getcwd())
ids = json.loads(open(os.path.join(OUT, "ids.txt")).read().strip().splitlines()[-1])
c = httpx.Client(timeout=30)
def tok(u, p): return {"Authorization": "Bearer " + c.post(f"{API}/api/v1/auth/login", data={"username": u, "password": p}).json()["access_token"]}
hm = tok("head@chromeschool.edu", "HeadPass123")
sid = ids["school"]
stranger = [u for u in c.get(f"{API}/api/v1/schools/{sid}/users", headers=hm, params={"role_code": "student", "limit": 200}).json() if u["email"] == "stranger@chromeschool.edu"][0]
MARKERS = [stranger["id"], "Unrelated Student", "STRANGER-SECRET", "Unrelated family fee"]
spec = c.get(f"{API}/api/v1/openapi.json").json()
gets = [p for p, ops in spec["paths"].items() if "get" in ops and p.startswith("/api/v1/schools/{school_id}")]
params = {p: [x for x in re.findall(r"{(\w+)}", p) if x != "school_id"] for p in gets}
SKIP = {"student_id", "user_id"}  # covered by leakscan.py

harvest: dict[str, set[str]] = {}
def collect(path, body):
    rows = body if isinstance(body, list) else body.get("items", []) if isinstance(body, dict) else []
    found = [r["id"] for r in rows if isinstance(r, dict) and isinstance(r.get("id"), str)][:40]
    harvest.setdefault(path, set()).update(found)
def candidates(name):
    word = name.rsplit("_id", 1)[0]
    return {i for path, s in harvest.items() if word in path for i in s}
def fill(path, values):
    url = path.replace("{school_id}", sid)
    for k, v in values.items(): url = url.replace("{" + k + "}", v)
    return API + url

for hop in range(3):
    for p, extra in params.items():
        if len(extra) != hop or set(extra) & SKIP: continue
        combos = [{}]
        for name in extra:
            combos = [dict(cmb, **{name: v}) for cmb in combos for v in list(candidates(name))[:15]]
        for cmb in combos[:30]:
            r = c.get(fill(p, cmb), headers=hm, params={"limit": 100})
            if r.status_code == 200 and r.headers.get("content-type", "").startswith("application/json"):
                collect(p, r.json())

roles = {"guardian": tok("guardian@chromeschool.edu", "Passw0rd1"), "student": tok("student@chromeschool.edu", "Passw0rd1")}
findings, probed = set(), 0
for p, extra in params.items():
    if not extra or set(extra) & SKIP: continue
    combos = [{}]
    for name in extra:
        combos = [dict(cmb, **{name: v}) for cmb in combos for v in list(candidates(name))[:15]]
    for cmb in combos[:40]:
        for role, h in roles.items():
            r = c.get(fill(p, cmb), headers=h); probed += 1
            if r.status_code == 200 and any(m in r.text for m in MARKERS):
                findings.add(f"{role}: GET {p} -> 200 exposes another family's student")
print(probed, "probes over", sum(1 for e in params.values() if e and not set(e) & SKIP), "id-keyed paths")
print("\n".join(sorted(findings)) or "no leaks found")
