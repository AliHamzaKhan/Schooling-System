"""Synthetic data for Chrome acceptance (disposable dev database only)."""
import json, os, httpx
OUT = os.environ.get("E2E_OUT", os.getcwd())
API="http://127.0.0.1:8000/api/v1"
c=httpx.Client(timeout=30)
def login(e,p):
    r=c.post(f"{API}/auth/login",data={"username":e,"password":p}); r.raise_for_status()
    return {"Authorization":"Bearer "+r.json()["access_token"]}
sa=login("admin@platform.com","ChangeMe123!")
r=c.post(f"{API}/schools",headers=sa,json={"name":"Synthetic Chrome School","code":"CHROME-02"}); r.raise_for_status(); sid=r.json()["id"]
c.post(f"{API}/schools/{sid}/subscription",headers=sa,json={"plan_code":"premium"}).raise_for_status()
c.post(f"{API}/schools/{sid}/status",headers=sa,json={"status":"active"}).raise_for_status()
c.post(f"{API}/schools/{sid}/headmaster",headers=sa,json={"email":"head@chromeschool.edu","password":"HeadPass123","full_name":"Synthetic Head"}).raise_for_status()
hm=login("head@chromeschool.edu","HeadPass123")
users={}
for role,email,name in [("teacher","teacher@chromeschool.edu","Synthetic Teacher"),("student","student@chromeschool.edu","Synthetic Student"),("guardian","guardian@chromeschool.edu","Synthetic Guardian"),("driver","driver@chromeschool.edu","Synthetic Driver")]:
    r=c.post(f"{API}/schools/{sid}/users",headers=hm,json={"email":email,"password":"Passw0rd1","full_name":name,"role_codes":[role]})
    print(role, r.status_code); 
    if r.status_code==201: users[role]=r.json()["id"]
r=c.post(f"{API}/schools/{sid}/academic/classes",headers=hm,json={"name":"Grade 1","level":1}); cid=r.json()["id"]
r=c.post(f"{API}/schools/{sid}/academic/classes/{cid}/sections",headers=hm,json={"name":"A"}); sec=r.json()["id"]
ids = {"school":sid,"class":cid,"section":sec,**users}
print(json.dumps(ids))
open(f"{OUT}/ids.txt", "w").write(json.dumps(ids))
