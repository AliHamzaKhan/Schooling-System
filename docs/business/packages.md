# Subscription Packages

Three sellable packages. Every feature listed below already exists in the
platform (backend module + portal screens), so nothing here is a promise we
can't ship today.

Plan codes in the system: `basic`, `standard`, `premium` (sold as "Advanced").
A school's effective feature set is always:

```
School Module Toggles  ∩  Subscription Plan Modules
```

---

## 1. BASIC — "Run the school"

For small schools that want to get off registers and WhatsApp groups.

**Core records**
- Student management (admission, profiles, documents, ID cards)
- Teacher / staff management
- Guardian management + guardian portal login
- Class, section, and subject setup
- Academic year & student promotion

**Daily operations**
- Daily attendance (student + staff)
- Subject-wise / period-wise attendance
- Timetable & period scheduling
- Academic calendar and holidays
- School info page (about, contacts, principal message)

**Communication (push only)**
- Firebase push notifications to students, teachers and guardians
- School-wide and class-wide announcements
- Absence alerts pushed to guardians automatically

**Exams (basic)**
- Exam scheduling and datesheets
- Manual marks entry
- Report card / result generation and PDF export

**Homework**
- Homework assignment and submission tracking

**Apps included**
- School portal mobile app (Android + iOS) for teachers, students, guardians
- Headmaster web dashboard

**Not included:** WhatsApp/SMS, quizzes, AI, fees, payroll, library, transport,
hostel, inventory, online classes, API access.

---

## 2. STANDARD — "Run the school + reach the parents"

Everything in **Basic**, plus:

**Communication (multi-channel)**
- WhatsApp notifications (Twilio) — results, attendance, announcements, reminders
- SMS fallback when WhatsApp is undelivered
- Email notifications
- Two-way messaging: guardian ↔ teacher, teacher ↔ headmaster threads
- Delivery status tracking per message

**Assessments**
- Quizzes: teacher-created, timed, auto-graded
- AI quiz generation — generate a question bank from a topic, chapter, or
  pasted text; teacher reviews and publishes
- Question bank reuse across classes and terms
- Grading schemes, GPA / percentage, class ranking
- Result analytics per student, subject and class

**Attendance & academics**
- Attendance analytics and defaulter lists
- Leave management (student and staff leave requests + approval)
- Lesson plans and course/syllabus tracking

**Operations**
- Meetings & parent–teacher meeting scheduling
- Standard reports (attendance, results, enrolment) with Excel/PDF export
- Document management (student & staff files)

**Not included:** AI exam generation, fee management, payroll, transport,
hostel, library, inventory, online classes, API access.

---

## 3. ADVANCED — "Run the whole institution"

Everything in **Standard**, plus:

**AI suite**
- AI exam paper generation — full paper from syllabus/chapters with marks
  distribution and difficulty mix; teacher edits before publishing
- AI question bank generation at scale
- AI lesson-plan and homework assistance
- AI-assisted report card remarks
- AI performance insights (at-risk students, subject weak points)

**Finance**
- Fee management: fee heads, structures, per-class and per-student plans
- Invoice generation, partial payments, discounts and scholarships
- Fee collection ledger, receipts, and outstanding/defaulter tracking
- Automated fee reminders (push + WhatsApp + SMS) on a schedule
- Fee and revenue reports

**HR & Payroll**
- Staff records, contracts, designations
- Salary structures, allowances and deductions
- Monthly payroll runs and payslip generation
- Staff attendance-linked payroll and leave deductions
- Salary disbursement ledger

**Facilities**
- Library: catalogue, issue/return, fines
- Transport: routes, vehicles, drivers, student assignment
- Hostel: blocks, rooms, allocation
- Inventory & assets: stock, purchases, issuance

**Learning**
- Online classes (live class links, schedules, attendance)

**Platform**
- Advanced reports and custom dashboards
- Full audit logs
- API access for integration with third-party systems
- Priority support and onboarding/training
- Custom branding on the school app (logo, colors, splash)

---

## Comparison table

| Feature | Basic | Standard | Advanced |
|---|:--:|:--:|:--:|
| Student / teacher / guardian management | ✅ | ✅ | ✅ |
| Attendance (daily + subject-wise) | ✅ | ✅ | ✅ |
| Timetable & academic calendar | ✅ | ✅ | ✅ |
| Push notifications (Firebase) | ✅ | ✅ | ✅ |
| Announcements | ✅ | ✅ | ✅ |
| Exams, marks, report cards | ✅ | ✅ | ✅ |
| Homework | ✅ | ✅ | ✅ |
| Guardian portal + mobile apps | ✅ | ✅ | ✅ |
| Student promotion / academic year | ✅ | ✅ | ✅ |
| WhatsApp notifications | — | ✅ | ✅ |
| SMS + Email notifications | — | ✅ | ✅ |
| Two-way messaging | — | ✅ | ✅ |
| Quizzes (auto-graded) | — | ✅ | ✅ |
| AI quiz generation | — | ✅ | ✅ |
| Result analytics & ranking | — | ✅ | ✅ |
| Leave management | — | ✅ | ✅ |
| Meetings / PTM scheduling | — | ✅ | ✅ |
| Lesson plans & courses | — | ✅ | ✅ |
| Standard reports & exports | — | ✅ | ✅ |
| AI exam paper generation | — | — | ✅ |
| AI insights & remarks | — | — | ✅ |
| Fee management & collection | — | — | ✅ |
| Automated fee reminders | — | — | ✅ |
| HR & payroll / salary management | — | — | ✅ |
| Library | — | — | ✅ |
| Transport | — | — | ✅ |
| Hostel | — | — | ✅ |
| Inventory & assets | — | — | ✅ |
| Online classes | — | — | ✅ |
| Advanced reports & audit logs | — | — | ✅ |
| API access | — | — | ✅ |
| Custom app branding | — | — | ✅ |
| Priority support | — | — | ✅ |

---

## Module mapping (for seeding `subscription_plans.modules`)

Values come from `app.core.enums.Module`.

**basic**
```
student_management, teacher_management, guardian_management, attendance,
timetable, exams, results, homework, mobile_app
```

**standard** — basic +
```
messaging, ai_features, reports, leave_management, meetings
```

**premium (Advanced)** — standard +
```
fee_management, hr_payroll, library, transport, hostel, inventory,
online_classes, api_access
```

> Note: `ai_features` is a single toggle today, so Standard and Advanced share
> the same flag. To gate AI *exam* generation to Advanced only, we need either a
> second module value (e.g. `ai_advanced`) or a per-plan capability check inside
> the AI module. Flag for a decision before these plans go live.

---

## Pricing (to be filled)

| Plan | Monthly | 6-Month | Annual |
|---|--:|--:|--:|
| Basic | TBD | TBD | TBD |
| Standard | TBD | TBD | TBD |
| Advanced | TBD | TBD | TBD |

Billing periods supported by the system: `monthly`, `six_month`, `annual`.
Discounts (percentage or fixed) are applied per school subscription, so
promotional pricing does not require a new plan.
