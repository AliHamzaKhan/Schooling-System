# U02 — Headmaster web: physical browser acceptance checklist

Run this yourself in a real browser against a live backend. It is the physical
acceptance step for the headmaster desktop journey (U02.3–U02.4); the automated
harnesses cover controller state, but visual/refresh behaviour is confirmed only
here. No preview was opened on your behalf.

Related tracker: [Product Enhancement Plan](PRODUCT_ENHANCEMENT_PLAN.md) ·
[progress log](PEP_PROGRESS.md). Use synthetic data only; do not exercise real
school records.

## Setup

- [ ] Sign in as a headmaster; you land on the school dashboard/module directory.
- [ ] School name and the active academic session are visible in the sidebar.
- [ ] Module search filters the directory by name/description; a no-match query
      shows the recoverable "no results" state, not a blank panel.

## Mutation journeys (U02.4.3)

**Create a class**
- [ ] Open Classes → New Class. Submitting an empty name shows "Class name is
      required" inline; nothing is created.
- [ ] Re-submit with the name of an existing class → "A class named … already
      exists"; still nothing created.
- [ ] Submit a new valid name (optionally level/room). The sheet closes, a
      "Class created" confirmation shows, and the new class appears in the list
      without a manual reload.
- [ ] Trigger a backend failure (e.g. stop the API briefly) and submit → the
      sheet stays open and shows the backend message; the list is unchanged.

**Add a section**
- [ ] Classes → a class → Add Section. Empty name → "Section name is required".
- [ ] A valid section name is created and the class's section list refreshes.

**Timetable authoring**
- [ ] Timetable → New Class. Empty name is rejected; a valid class is created
      and the timetable view refreshes.

**School settings save**
- [ ] Settings → clear the name and Save → "School name cannot be empty."; no
      save occurs.
- [ ] Enter a fee day of 40 → "Enter a fee day between 1 and 31."; a salary day
      of 0 → "Enter a salary day between 1 and 31."
- [ ] Enter valid values and Save → "Settings saved"; reopening Settings shows
      the persisted values.
- [ ] With the API failing, Save surfaces the backend error and does not claim
      success.

## Refresh safety (U02.3.x)

- [ ] With a module open, press the browser Refresh (F5). The page reloads to
      the same screen with real data — no empty list, no "arguments required".
- [ ] Copy a detail URL (e.g. a class roster, a student/section report, an
      exam-category timetable), open it in a new tab → it loads the correct
      canonical record, not stale or empty data.
- [ ] Browser Back/Forward returns to the previous screen with its data intact.
- [ ] Open a module your role/plan does not permit by its direct URL → access is
      denied and the feature page is not constructed (no partial render).

## States to confirm on each screen above

- [ ] Loading indicator while data is fetched.
- [ ] Empty state where a list legitimately has no rows.
- [ ] Retryable error state when a read fails (and a failed refresh clears the
      previously shown data rather than leaving it as if current).
- [ ] Validation/denied/timeout messages are legible and specific.

## Accessibility spot-checks

- [ ] Keyboard only: Tab through a form (e.g. Settings) reaches every field and
      the submit button with a visible focus ring; Enter submits.
- [ ] Browser zoom to 200% (or OS large text): forms reflow without clipped
      actions or horizontal scrolling of the whole page.
- [ ] Reduced-motion OS setting: dialogs/sheets appear without decorative
      scale/badge animation.

## Record the result

- [ ] Note pass/fail per section with the browser + OS used and screenshots of
      any failure (synthetic data only). File failures against the relevant U02
      packet in the [progress log](PEP_PROGRESS.md).
