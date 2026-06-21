# Hierarchical Permission Inheritance

Permissions assigned (or revoked) at a higher level automatically affect all
lower roles. A restriction at any level cascades downward and **cannot** be
overridden below.

## Cascade Order

```
Super Admin
   ↓
School Subscription Permissions
   ↓
Headmaster Permissions
   ↓
Custom Staff Permissions
   ↓
Teacher / Staff Access
   ↓
Student & Guardian Visibility
```

## Rule

> A user can never access a feature that is restricted at a higher level.

When a module is disabled upstream, it is fully hidden — removed from UI, APIs,
reports, and navigation for every affected role.

---

## Example 1 — Disabling Fee Management

If the Super Admin disables **Fee Management**, then:

- Headmaster cannot access Fees.
- Teachers cannot access Fee-related features.
- Guardians cannot view Fee details.
- Students cannot view Fee status.

The entire module becomes hidden across the platform.

---

## Example 2 — Disabling the Examination Module

If the Super Admin disables the **Examination Module**, then:

- Headmaster cannot create exams.
- Teachers cannot create exams or enter marks.
- Students cannot view exams.
- Guardians cannot view results.

---

## Enforcement Notes

- Inheritance is evaluated **top-down at every request** — the effective
  permission set is recomputed, never cached past an upstream change.
- Revoking a permission upstream must invalidate any downstream grants that
  depended on it.
- Hidden modules must not leak through any surface: navigation menus, API
  endpoints, exported reports, search results, or deep links.
