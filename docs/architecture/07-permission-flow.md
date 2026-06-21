# Permission Flow & Enforcement

This document describes how permissions resolve from the platform owner down to
students and guardians, and how the system enforces them.

## Permission Flow

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

## Golden Rule

> A user can never access a feature that is restricted at a higher level.

Each level can only **narrow** access, never widen it beyond what the level
above allows.

## Effective Permission Resolution

For any user and feature, the effective access is the intersection of every
level above them:

```
Effective Access =
      School Module Toggle (Super Admin)
    ∩ Subscription Plan Feature
    ∩ Headmaster Permission
    ∩ Role / Staff Permission
    ∩ User Assignment (e.g. class, area)
```

If any term denies access, the feature is unavailable.

## Enforcement Surfaces

When a feature is restricted, it must be removed/blocked consistently across:

- **UI** — components and screens not rendered.
- **Navigation** — menu items, links, and breadcrumbs hidden.
- **APIs** — endpoints return authorization errors; not just hidden in UI.
- **Reports** — restricted data excluded from generated and exported reports.
- **Search & deep links** — restricted records not discoverable or reachable.

## Expected Result

A complete hierarchical permission system where:

- Super Admin controls schools and subscriptions.
- Super Admin decides which modules a school can access.
- Headmaster receives only allowed permissions.
- Headmaster manages staff permissions within those limits.
- Teachers, Students, and Guardians automatically inherit access restrictions.
- Hidden modules are removed from UI, APIs, reports, and navigation to ensure
  complete security and consistency across the platform.
