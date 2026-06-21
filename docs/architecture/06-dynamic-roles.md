# Dynamic Role Management

In addition to the default roles, the system supports **custom school roles**.
The Headmaster can create roles tailored to the school's structure and assign
module-wise permissions to each.

## Default Roles

- Super Admin
- Headmaster
- Teacher
- Guardian
- Student

## Custom Role Examples

The Headmaster can create additional roles such as:

- Vice Principal
- Coordinator
- Accountant
- Librarian
- Receptionist
- Transport Manager
- HR Manager

## Per-Role, Module-Wise Permissions

For each role, the Headmaster can assign the following access levels, per module:

- **View**
- **Create**
- **Edit**
- **Delete**
- **Approve**
- **Export**

### Example Role Definition — Accountant

| Module | View | Create | Edit | Delete | Approve | Export |
|--------|:----:|:------:|:----:|:------:|:-------:|:------:|
| Fee Management | ✅ | ✅ | ✅ | — | ✅ | ✅ |
| Reports & Analytics | ✅ | — | — | — | — | ✅ |
| HR & Payroll | ✅ | — | — | — | — | — |

### Example Role Definition — Librarian

| Module | View | Create | Edit | Delete | Approve | Export |
|--------|:----:|:------:|:----:|:------:|:-------:|:------:|
| Library | ✅ | ✅ | ✅ | ✅ | — | ✅ |

## Behaviour

- Custom roles are scoped to a single school.
- Permissions assignable to a custom role are bounded by the Headmaster's
  permissions and the school's enabled modules.
- A custom role cannot be granted access to a disabled or unsubscribed module.
- Roles can be created, edited, and deleted by the Headmaster within their
  granted limits.
