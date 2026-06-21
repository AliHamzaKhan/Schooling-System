# Super Admin & School-Level Permissions

The Super Admin is the **Platform Owner**. The system includes a flexible
permission management module where the Super Admin controls what each school is
allowed to access.

## Responsibilities

- Create and manage schools on the platform.
- Enable or disable modules per school.
- Assign subscription plans (see [`02-subscription-plans.md`](02-subscription-plans.md)).
- Define the baseline of permissions a Headmaster can receive.

## School-Level Module Toggles

The Super Admin can enable or disable each of the following modules for an
**entire school**. Disabling a module here hides it everywhere downstream — UI,
APIs, reports, and navigation.

- Student Management
- Teacher Management
- Guardian Management
- Attendance
- Homework & Assignments
- Exams
- Results
- Fee Management
- Timetable
- Library
- Transport
- Hostel
- HR & Payroll
- Inventory
- Messaging & Chat
- Online Classes
- AI Features
- Reports & Analytics
- Mobile App Access
- API Access

## Behaviour

- A module disabled at this level **cannot** be re-enabled by a Headmaster.
- Module availability is the outer boundary of everything below it.
- Toggling a module off must immediately cascade the removal to all lower roles
  (see [`04-hierarchical-inheritance.md`](04-hierarchical-inheritance.md)).

## Effective Module Set

The modules actually available to a school are the **intersection** of:

```
School Module Toggles  ∩  Subscription Plan Features
```

Both must allow a module for it to be visible to the school.
