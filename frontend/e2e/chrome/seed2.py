import json, os, httpx
OUT = os.environ.get('E2E_OUT', os.getcwd())
API="http://127.0.0.1:8000/api/v1"
ids=json.loads(open(f'{OUT}/ids.txt').read().strip().splitlines()[-1])
c=httpx.Client(timeout=30)
def login(e,p):
    r=c.post(f"{API}/auth/login",data={"username":e,"password":p}); r.raise_for_status()
    return {"Authorization":"Bearer "+r.json()["access_token"]}
hm=login("head@chromeschool.edu","HeadPass123"); sid=ids["school"]
def show(name,r): print(name, r.status_code, r.text[:160] if r.status_code>=300 else "")
show("enroll", c.post(f"{API}/schools/{sid}/sections/{ids['section']}/students",headers=hm,json={"student_id":ids["student"]}))
show("class teacher", c.patch(f"{API}/schools/{sid}/academic/sections/{ids['section']}",headers=hm,json={"class_teacher_id":ids["teacher"]}))
show("guardian link", c.post(f"{API}/schools/{sid}/guardians/{ids['guardian']}/children",headers=hm,json={"student_id":ids["student"],"relationship":"Parent"}))
r=c.post(f"{API}/schools/{sid}/academic/subjects",headers=hm,json={"code":"MATH","name":"Mathematics"}); show("subject",r)
subj=r.json().get("id") if r.status_code==201 else None
if subj:
    show("homework", c.post(f"{API}/schools/{sid}/homework/assignments",headers=hm,json={"section_id":ids["section"],"subject_id":subj,"title":"Synthetic fractions worksheet","due_date":"2026-10-15"}))
show("invoice", c.post(f"{API}/schools/{sid}/fees/invoices",headers=hm,json={"student_id":ids["student"],"title":"October tuition (synthetic)","amount":5000,"due_date":"2026-09-20"}))
ids["subject"]=subj
open(f'{OUT}/ids.txt','a').write("\n"+json.dumps(ids))
