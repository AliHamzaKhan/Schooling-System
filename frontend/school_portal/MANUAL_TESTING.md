# Manual test plan — bottom nav + dashboard rollout

Everything below needs a running app. The widget tests in
`test/dashboard_kit_test.dart` cover structure, semantics and layout maths;
none of them can see a pixel, a safe area, an OS gesture, or real data.

Scope: the icon-only `PortalNavBar` (all four modules) and the shared dashboard
shape now used by student, teacher, headmaster and guardian.

**Devices worth using:** iPhone SE (smallest), iPhone 15 Pro (notch + home
indicator), one Android with gesture navigation, one tablet.

---

## 1. Bottom navigation — every module

| # | What to do | Pass looks like |
|---|---|---|
| 1.1 | Open each module (student, teacher, headmaster, guardian) and look at the bar | Icons only, no labels. Active tab is a filled navy rounded square with a white icon; the rest are plain grey icons |
| 1.2 | Tap through every tab | Highlight moves with no flicker, and the square animates rather than jumping |
| 1.3 | Compare student (4 tabs) with the others (5 tabs) | Even spacing in both; icons not bunched at the centre or pushed to the edges |
| 1.4 | On a notched iPhone and an Android with gesture nav, look at the bottom edge | The bar sits above the home indicator / gesture pill; nothing clipped, no double gap |
| 1.5 | Open any screen with a text field and focus it | Nav bar hides while the keyboard is up and comes back on dismiss |
| 1.6 | On a non-Home tab, press Android back | Returns to the Home tab |
| 1.7 | On the Home tab, press Android back | Nothing happens — you are **not** dropped back to login |
| 1.8 | Scroll a tab's list, switch tabs, switch back | Scroll position is preserved |
| 1.9 | Long-press a nav icon | Tooltip shows the tab name |
| 1.10 | Turn on VoiceOver (iOS) / TalkBack (Android) and swipe through the bar | Each tab is announced by name, and the current one is announced as selected |
| 1.11 | Tap near the edge of each icon | Whole 56×48 area responds, not just the coloured square |

## 2. Student dashboard

| # | What to do | Pass looks like |
|---|---|---|
| 2.1 | Sign in as a student with real data | Identity card first, then Attendance / Pending homework / Exams / Next exam, then Leave Application, then six shortcut tiles |
| 2.2 | Check the identity card subtitle | Reads "Student" — grade/section is **not** in `/auth/me` yet (see note below) |
| 2.3 | Sign in as a student with **no** upcoming exam | "Next exam" shows `—` and "None scheduled", not `0d` |
| 2.4 | Tap the "Next exam" card | Opens the exam detail for that exam |
| 2.5 | Tap each of the six shortcuts | Results, Timetable, Quizzes, Courses, Messages, My School each open the right screen |
| 2.6 | Tap Leave Application | Opens the leave screen |
| 2.7 | Pull down to refresh | Spinner appears and the numbers reload |
| 2.8 | Scroll to the bottom | "Due Soon" assignments and the monthly attendance card are still there and still tappable |

## 3. Teacher dashboard

| # | What to do | Pass looks like |
|---|---|---|
| 3.1 | Sign in as a teacher | Classes today / Pending grades / New submissions / Sections, then Leave Requests, then three shortcut tiles |
| 3.2 | Read the shortcut labels | "Attendance", "Assignment", "Announce" — check these read sensibly to a teacher; they are the last word of the old action names |
| 3.3 | Tap each shortcut | Mark attendance, add assignment and announce each open |
| 3.4 | Tap the stat cards | Classes today → calendar; Pending grades and New submissions → tasks |
| 3.5 | Sign in as a teacher with nothing scheduled today | "0 / Nothing scheduled", and the schedule section below is empty rather than broken |
| 3.6 | Check the identity card | Shows the teacher's name from the profile, not the greeting text |

## 4. Headmaster dashboard

| # | What to do | Pass looks like |
|---|---|---|
| 4.1 | Sign in as a headmaster | Identity card, Leave Requests row, three shortcuts (Settings, Salaries, School Info), then the KPI grid |
| 4.2 | Check the KPI cards still work | Trend pills show, and the "+" create affordance on the cards that had one still opens the create flow |
| 4.3 | Tap each shortcut and the Leave Requests row | All four destinations open |
| 4.4 | Sign in on an account near subscription expiry | The expiry alert still appears, above the KPI grid |
| 4.5 | Scroll down | Teacher attendance, pending approvals and recent announcements are unchanged |

## 5. Guardian dashboard — regression only

It was rebuilt on the shared widgets, so it should look **identical** to before.

| # | What to do | Pass looks like |
|---|---|---|
| 5.1 | Sign in as a guardian with one child | Same as the screenshot: profile card, 2×2 grid, Leave Application, six shortcuts, Recent Activity |
| 5.2 | Sign in as a guardian with **two or more** children | The child switcher strip appears above the identity card, and switching children updates every number |
| 5.3 | Tap the Fees card when fees are due | Shows "Due / Tap to view" in red and opens the fees screen |

## 6. Layout stress — do these on at least one screen per module

| # | What to do | Pass looks like |
|---|---|---|
| 6.1 | iPhone SE (or any 320–375pt width) | Stat cards do not overflow; "Pending homework" wraps to two lines without clipping |
| 6.2 | OS text size at maximum (Settings → Accessibility → larger text) | Values and labels ellipsize instead of overflowing; the yellow/black overflow stripes never appear |
| 6.3 | A very long user name | Identity card name ellipsizes on one line and does not push the avatar |
| 6.4 | Rotate to landscape, and open on a tablet | Grid and tiles stay usable — flag anything that looks stretched |
| 6.5 | Dark mode, if the app supports it | Nav bar background and the active square still have contrast |

---

## Known gap, not a bug

The screenshot's identity subtitle is "Grade 5 — Section A". The guardian
module has that because a child record carries grade and section; `/auth/me`
carries neither for a student, so the student card says "Student" instead of
inventing one. When the profile payload gains those fields, the only change is
`StudentDashboardController.roleLine`.
