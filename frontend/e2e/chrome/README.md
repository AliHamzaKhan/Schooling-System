# Chrome acceptance harness

Scripted browser checks for the Flutter web portals, run in Chromium through
Playwright. They automate the [U02 headmaster checklist](../../../docs/U02_HEADMASTER_BROWSER_CHECKLIST.md)
plus F02 session and F03 role-route acceptance. Use a **disposable development
database with synthetic data only**.

## Run

```bash
# 1. API on a disposable database
cd backend
createdb schooling_chrome
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/schooling_chrome \
  ENVIRONMENT=development python -m app.seed
DATABASE_URL=... ENVIRONMENT=development uvicorn app.main:app --port 8000

# 2. Profile web builds (release builds refuse a local HTTP API by design)
for p in admin_portal school_portal; do
  (cd frontend/$p && flutter build web --profile \
     --dart-define=APP_ENV=development \
     --dart-define=API_BASE_URL=http://localhost:8000/api/v1)
done

# 3. Serve each build with an index.html fallback so deep links can refresh
python spa.py ../../admin_portal/build/web 8080 &
python spa.py ../../school_portal/build/web 8081 &

# 4. Install, seed synthetic data, run (outputs go to E2E_OUT or the cwd)
npm install
npm pack @fontsource/roboto@5 && tar xzf fontsource-roboto-*.tgz
python seed.py && python seed2.py
npm run login && npm run u02 && npm run roles && npm run session
```

`node accountant.mjs` creates the synthetic Accountant (if missing), checks the
Finance home and that the Accountant's waiver waits for the Headmaster, approves
it as the Headmaster in the UI, confirms the invoice changed, and checks school
photos need a signed-in member (401 without a token).

`python leakscan.py` probes every school-scoped GET in the OpenAPI document as
the synthetic guardian and student, substituting an unrelated student's id, and
reports any response that exposes that student.

Each check prints `PASS`/`FAIL`; results are written as JSON and screenshots to
`shots/`. CanvasKit is served from the build and Roboto from `@fontsource`, so the
run does not depend on `gstatic.com`.

## Notes on driving Flutter web

- Semantics are enabled by clicking `flt-semantics-placeholder`; checks read the
  accessibility tree, so a missing label is also an accessibility defect.
- Click on-screen semantics nodes by coordinates; Playwright's scroll-into-view
  moves the DOM node but not the Flutter canvas. Scroll with the mouse wheel.
- Clear fields with End + Backspace; Ctrl+A is not reliable in Flutter inputs.
- Nodes outside the viewport are not in the semantics tree; verify off-screen
  results through the API.
