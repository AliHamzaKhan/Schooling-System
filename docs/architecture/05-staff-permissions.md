# Headmaster-Controlled Staff Permissions

Within the permissions granted by the Super Admin, the Headmaster can further
control school staff access. Staff permissions are always a **subset** of the
Headmaster's own permissions.

## Principle

> The Headmaster can only delegate what the Headmaster has been granted.
> Staff access is bounded by Headmaster access, which is bounded by Super Admin
> and subscription limits.

## Teacher Permissions

The Headmaster can grant teachers any subset of the following:

- Attendance Management
- Assignment Management
- Study Material Management
- Exam Creation
- Marks Entry
- Result Viewing
- Student Notes
- Guardian Communication

## Access Levels per Permission

Each staff permission can be granted at one or more access levels:

- **View Only**
- **Create**
- **Edit**
- **Delete**
- **Approve**
- **Export**

---

## Example

If the Headmaster allows:

- Attendance
- Homework

but disables:

- Exam Management

Then teachers will only see **Attendance** and **Homework** features. The Exam
features are hidden from their UI, APIs, and navigation entirely.

---

## Behaviour

- If a module is disabled for the Headmaster (upstream), it cannot be granted to
  any staff member, regardless of the Headmaster's intent.
- Disabling a permission for a teacher removes the related features from their
  UI, navigation, and API access.
- Student and Guardian visibility for a feature depends on the corresponding
  staff/teacher feature being active (see
  [`04-hierarchical-inheritance.md`](04-hierarchical-inheritance.md)).
