# Development Process & Roadmap

This document defines the **structured development process** the AI must follow
when generating code for this project. It is the governing methodology — no code
is written outside this flow.

## Guiding Principle

Before writing any code, first **analyze and categorize the implementation
flow**, identify dependencies between modules, and produce a development
roadmap. Foundational architecture is completed before feature development.

The project is already divided into:

- Modules
- Features
- Technologies
- User Roles
- Backend Services
- Frontend Applications

(See [`00-overview.md`](00-overview.md) through
[`09-architecture-and-dev-flow.md`](09-architecture-and-dev-flow.md).)

---

## Expected Development Flow

| # | Step | Output |
|---|------|--------|
| 1 | Analyze the complete project architecture | Architecture understanding |
| 2 | Identify module dependencies and implementation priorities | Dependency map + priority order |
| 3 | Define the folder structure and project architecture | Project skeleton |
| 4 | Create database design and relationships | Schema / ERD |
| 5 | Create backend foundation | FastAPI setup, PostgreSQL config, Auth & Authorization, RBAC permission system, common utilities and shared services |
| 6 | Implement backend modules one by one **in dependency order** | Working backend modules |
| 7 | Create API documentation and contracts | API specs |
| 8 | Develop Flutter frontend structure using GetX architecture | Frontend skeleton |
| 9 | Implement frontend modules according to backend completion status | Working frontend modules |
| 10 | Integrate APIs module by module | Connected modules |
| 11 | Add testing, validation, and error handling | Tested modules |
| 12 | Configure Docker containers and microservices | Containerized services |
| 13 | Configure GitLab CI/CD pipelines | Automated pipelines |
| 14 | Final integration, optimization, and deployment preparation | Release-ready build |

---

## Important Rules

- **Do not** generate random or isolated code files.
- Always **explain what module is being implemented and why** it comes before
  the next module.
- Complete **foundational architecture before feature development**.
- Maintain **production-ready** code standards.
- Follow **scalable architecture patterns**.
- Ensure **consistency** between backend, frontend, database, permissions, and
  APIs.
- Keep all generated code aligned with the overall project structure and
  development roadmap.

---

## Interaction Contract

> Whenever development is requested, the AI must **first provide the
> implementation sequence and execution plan**, then begin coding **module by
> module** according to that plan.

So on any "start development" request:

1. Present the implementation sequence / execution plan for the requested scope.
2. State which module is being implemented and why it comes first.
3. Only then begin coding, module by module, in dependency order.

---

## Recommended Foundation-First Ordering

A concrete ordering consistent with the dependency rules above:

1. **Project skeleton & config** — folder structure, settings, env management.
2. **Database layer** — models, migrations, relationships (multi-tenant aware).
3. **Authentication Service** — login, registration, JWT, refresh tokens.
4. **Permission Service / RBAC** — roles, dynamic permissions, subscription gating.
   *(Everything downstream depends on this — see
   [`07-permission-flow.md`](07-permission-flow.md).)*
5. **School & User Management Services** — schools, headmasters, teachers,
   students, guardians, staff.
6. **Academic Service** — classes, sections, subjects, timetables.
7. **Feature modules in dependency order** — Attendance → Examination → Fees →
   Homework → Communication → Reporting → Billing → File Management.
8. **Frontend foundation (GetX)** then frontend modules mirroring backend
   completion.
9. **Integration, testing, Docker, CI/CD, deployment.**
