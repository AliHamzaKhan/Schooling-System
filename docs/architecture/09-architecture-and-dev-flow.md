# Project Architecture & Development Flow

## System Architecture

The platform is built using a **centralized backend architecture** with
role-based access control, where all users operate through a single backend
while accessing different interfaces based on their assigned roles.

### Frontend Applications

The frontend is divided into two separate Flutter applications/modules:

#### 1. Admin Portal

For Platform Owners (Super Admin).

Responsibilities:

- School Management
- Subscription Management
- Billing & Payments
- School Approvals
- Headmaster Management
- Global Reports & Analytics
- Platform Configuration
- Permission Management
- Support Management

#### 2. School Portal

A single application serving:

- Headmaster
- Teacher
- Student
- Guardian
- School Staff

Access and screens are dynamically controlled through role-based permissions
after login (see [`07-permission-flow.md`](07-permission-flow.md)).

---

# Backend Architecture

## Single Centralized Backend

A single FastAPI backend serves all frontend applications and roles.

Benefits:

- Easier maintenance
- Centralized authentication
- Shared database structure
- Consistent business logic
- Simplified deployment

---

## Microservice Architecture

The backend is organized as independent services/modules for scalability and
maintainability.

### Authentication Service

- Login
- Registration
- JWT Management
- Refresh Tokens
- Permission Validation

### School Service

- School Management
- School Settings
- Academic Sessions

### User Management Service

- Headmasters
- Teachers
- Students
- Guardians
- Staff

### Academic Service

- Classes
- Sections
- Subjects
- Timetables

### Attendance Service

- Student Attendance
- Teacher Attendance
- Reports

### Examination Service

- Exams
- Marks
- Results
- Report Cards

### Fee Management Service

- Invoices
- Payments
- Receipts
- Fee Reports

### Communication Service

- WhatsApp
- Push Notifications
- Email
- SMS

### Permission Service

- Role Management
- Dynamic Permissions
- Subscription-Based Access

### Reporting Service

- School Reports
- Financial Reports
- Academic Reports
- Analytics

### Subscription & Billing Service

- Packages
- Renewals
- Billing
- Payment Gateways

### File Management Service

- Documents
- Assignments
- Student Files
- School Media

---

# Database Architecture

## PostgreSQL

A single PostgreSQL cluster with multi-tenant support.

### Tenant Structure

```
Platform
└── Schools
    ├── Headmaster
    ├── Teachers
    ├── Students
    ├── Guardians
    └── Staff
```

Each school's data remains isolated while sharing the same infrastructure.

---

# Development Workflow

## Source Control

### GitLab Repositories

#### Backend Repository

- FastAPI
- PostgreSQL
- Docker
- Microservices

#### Admin Frontend Repository

- Flutter Web
- Super Admin Portal

#### School Frontend Repository

- Flutter
- Web
- Android
- iOS
- Headmaster, Teacher, Student, Guardian

---

# Branch Strategy

### Main Branches

- `main` → Production
- `staging` → Pre-production
- `development` → Active Development

### Feature Branches

Examples:

- `feature/attendance`
- `feature/exams`
- `feature/fees`
- `feature/notifications`

---

# Docker Infrastructure

Every service is containerized.

### Containers

- API Gateway
- Authentication Service
- School Service
- Academic Service
- Attendance Service
- Examination Service
- Communication Service
- PostgreSQL
- Redis
- Nginx

Benefits:

- Easy deployment
- Environment consistency
- Horizontal scaling
- Service isolation

---

# CI/CD Pipeline (GitLab)

## Backend Pipeline

| Stage | Step |
|-------|------|
| 1 | Linting / Code Quality Checks |
| 2 | Unit Testing |
| 3 | Build Docker Images |
| 4 | Push Images to Registry |
| 5 | Deploy to Staging |
| 6 | Deploy to Production |

---

## Flutter Admin Pipeline

| Stage | Step |
|-------|------|
| 1 | Dependency Validation |
| 2 | Flutter Analyze |
| 3 | Unit Tests |
| 4 | Build Flutter Web |
| 5 | Deploy to Staging |
| 6 | Deploy to Production |

---

## Flutter School Portal Pipeline

### Web

- Build Flutter Web
- Deploy Automatically

### Android

- Generate APK
- Generate AAB
- Publish Internal Testing Build

### iOS

- Fastlane Integration
- Build IPA
- TestFlight Deployment

---

# Environment Strategy

| Environment | Infrastructure |
|-------------|----------------|
| Development | Local Docker Environment |
| Staging | Testing Server |
| Production | High Availability Infrastructure |

Separate environments have:

- Dedicated databases
- Dedicated storage
- Dedicated API endpoints

---

# Security

- JWT Authentication
- Refresh Tokens
- RBAC Permission System
- School-Level Data Isolation
- Audit Logs
- Rate Limiting
- API Security
- Database Encryption
- Backup & Recovery Strategy

---

# Expected Result

A scalable multi-tenant School Management SaaS platform built with Flutter
(GetX), FastAPI, PostgreSQL, Docker, and GitLab CI/CD. The system uses a single
centralized backend with modular microservices, separate Admin and School
frontends, dynamic permission management, automated deployments, and support for
Web, Android, and iOS from a unified architecture.
