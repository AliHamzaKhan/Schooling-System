# Permission & Role Management System — Overview

This document set describes the complete hierarchical permission system for the
Schooling System platform. Each module is documented in its own file.

## Module Index

| # | Module | File |
|---|--------|------|
| 1 | Super Admin & School-Level Permissions | [`01-super-admin.md`](01-super-admin.md) |
| 2 | Subscription-Based Permissions | [`02-subscription-plans.md`](02-subscription-plans.md) |
| 3 | Headmaster Permission Management | [`03-headmaster-permissions.md`](03-headmaster-permissions.md) |
| 4 | Hierarchical Permission Inheritance | [`04-hierarchical-inheritance.md`](04-hierarchical-inheritance.md) |
| 5 | Headmaster-Controlled Staff Permissions | [`05-staff-permissions.md`](05-staff-permissions.md) |
| 6 | Dynamic Role Management | [`06-dynamic-roles.md`](06-dynamic-roles.md) |
| 7 | Permission Flow & Enforcement | [`07-permission-flow.md`](07-permission-flow.md) |
| 8 | Technology Stack & Communication System | [`08-tech-stack-and-communication.md`](08-tech-stack-and-communication.md) |
| 9 | Project Architecture & Development Flow | [`09-architecture-and-dev-flow.md`](09-architecture-and-dev-flow.md) |
| 10 | Development Process & Roadmap | [`10-development-process-and-roadmap.md`](10-development-process-and-roadmap.md) |

## Core Concept

The platform enforces a **top-down permission cascade**. Access granted at any
level is always bounded by the level above it. A user can never access a feature
that is restricted at a higher level.

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

## Actors

| Actor | Scope | Sets Permissions For |
|-------|-------|----------------------|
| Super Admin (Platform Owner) | All schools | Schools, subscriptions, modules |
| Headmaster | Single school | Staff, teachers, custom roles |
| Teacher / Staff | Assigned classes/areas | (Inherits) |
| Guardian | Linked students | (Inherits, view-only) |
| Student | Self | (Inherits, view-only) |

## Permission Action Types

Most permissions can be granted at one or more of these access levels:

- **View Only**
- **Create**
- **Edit**
- **Delete**
- **Approve**
- **Export**

## Expected Result

A complete hierarchical permission system where:

- Super Admin controls schools and subscriptions.
- Super Admin decides which modules a school can access.
- Headmaster receives only allowed permissions.
- Headmaster manages staff permissions within those limits.
- Teachers, Students, and Guardians automatically inherit access restrictions.
- Hidden modules are removed from UI, APIs, reports, and navigation to ensure
  complete security and consistency across the platform.
