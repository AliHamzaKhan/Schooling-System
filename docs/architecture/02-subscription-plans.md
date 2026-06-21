# Subscription-Based Permissions

Different subscription plans unlock different feature sets. The subscription plan
acts as a second gate alongside the Super Admin's school-level module toggles.

## Plans

### Basic Plan

- Student Management
- Attendance
- Timetable
- Announcements

### Standard Plan

- **All Basic features**, plus:
- Exams
- Results
- Homework
- Guardian Portal

### Premium Plan

- **All features**, including:
- AI Tools
- Advanced Reports
- HR & Payroll
- Online Classes
- API Integrations

## Plan Comparison

| Feature | Basic | Standard | Premium |
|---------|:-----:|:--------:|:-------:|
| Student Management | ✅ | ✅ | ✅ |
| Attendance | ✅ | ✅ | ✅ |
| Timetable | ✅ | ✅ | ✅ |
| Announcements | ✅ | ✅ | ✅ |
| Exams | — | ✅ | ✅ |
| Results | — | ✅ | ✅ |
| Homework | — | ✅ | ✅ |
| Guardian Portal | — | ✅ | ✅ |
| AI Tools | — | — | ✅ |
| Advanced Reports | — | — | ✅ |
| HR & Payroll | — | — | ✅ |
| Online Classes | — | — | ✅ |
| API Integrations | — | — | ✅ |

## Behaviour

- A feature not included in the plan is treated as disabled, even if the
  school-level toggle would allow it.
- Upgrading a plan unlocks the additional features immediately (subject to the
  school-level toggles still being on).
- Downgrading a plan must hide newly-restricted modules across UI, APIs, and
  reports.

## Relationship to School-Level Toggles

The effective module set for a school is:

```
School Module Toggles  ∩  Subscription Plan Features
```

See [`01-super-admin.md`](01-super-admin.md) for the school-level toggles.
