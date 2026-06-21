# Headmaster Permission Management

The Headmaster does **not** automatically receive access to every feature.
Instead, the Super Admin defines the Headmaster's permissions per school, within
the boundary of the school's enabled modules and subscription plan.

## Principle

> The Headmaster can only be granted permissions for modules that the Super Admin
> has enabled and the subscription plan includes.

## Headmaster Permission List

The Super Admin can grant the Headmaster any subset of the following:

- Manage Teachers
- Manage Students
- Manage Guardians
- Manage Attendance
- Manage Exams
- Manage Results
- Manage Fees
- Manage Timetable
- Manage Announcements
- Manage Leave Requests
- View Reports
- Export Reports
- Manage School Settings
- Create Staff Accounts

## Access Levels per Permission

Each permission can be granted at one or more access levels:

- **View Only**
- **Create**
- **Edit**
- **Delete**
- **Approve**
- **Export**

### Example Permission Matrix

| Permission | View | Create | Edit | Delete | Approve | Export |
|------------|:----:|:------:|:----:|:------:|:-------:|:------:|
| Manage Teachers | ✅ | ✅ | ✅ | ✅ | — | — |
| Manage Exams | ✅ | ✅ | ✅ | — | ✅ | ✅ |
| View Reports | ✅ | — | — | — | — | ✅ |
| Manage Fees | ✅ | ✅ | ✅ | — | ✅ | ✅ |

## Behaviour

- The Headmaster's granted permissions form the boundary for all staff and
  custom roles within the school.
- A Headmaster cannot grant a staff member a permission the Headmaster does not
  hold.
- Permissions for a disabled module are not shown to the Headmaster at all.

See [`05-staff-permissions.md`](05-staff-permissions.md) for how the Headmaster
delegates these permissions to staff.
