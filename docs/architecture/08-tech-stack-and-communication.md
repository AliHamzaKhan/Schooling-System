# Technology Stack & Communication System

## Technology Stack

### Frontend

- Flutter (Android, iOS, Web)
- GetX State Management
- GetX Routing
- GetX Dependency Injection
- Responsive UI for Mobile, Tablet, and Web

### Backend

- Python FastAPI
- PostgreSQL Database
- JWT Authentication
- Role-Based Access Control (RBAC)
- REST APIs
- Background Tasks & Scheduled Jobs

### Infrastructure

- Docker Support
- CI/CD Pipeline
- Cloud Storage for Documents
- Push Notifications
- WhatsApp Business API Integration
- Email Integration
- SMS Integration (Optional)

---

# Automated WhatsApp Notification System

The system automatically sends WhatsApp notifications to guardians, students,
teachers, and school management based on **configurable events**.

> All notification types are gated by the permission system — a module disabled
> upstream (see [`04-hierarchical-inheritance.md`](04-hierarchical-inheritance.md))
> will not trigger notifications for that module.

## Attendance Notifications

### Student Present

Send a WhatsApp message to the guardian when attendance is marked.

Example payload:

- Student Name
- Class
- Date
- Present Status
- Check-In Time

### Student Absent

Immediately notify the guardian when a student is marked absent.

### Late Arrival

Notify the guardian if the student arrives late.

### Early Departure

Notify the guardian when the student leaves before school closing time.

---

## Parent-Teacher Meeting Notifications

### Meeting Scheduled

Send a WhatsApp notification when a parent meeting is created.

### Meeting Reminder

Automatically send reminders:

- 1 day before
- 2 hours before
- 30 minutes before

### Meeting Updates

Notify participants if meeting details change.

### Meeting Cancellation

Send a cancellation notification with reason.

---

## Examination Notifications

### Exam Schedule Announcement

Send the complete exam timetable to guardians and students.

### Upcoming Exam Reminder

Automatic reminders:

- 7 days before
- 3 days before
- 1 day before

### Exam Hall/Room Updates

Notify students of room changes.

### Result Published

Notify when exam results are available.

---

## Fee Management Notifications

### Fee Generated

Send invoice details to the guardian.

### Upcoming Due Date Reminder

- 7 days before due date
- 3 days before due date
- 1 day before due date

### Overdue Fee Reminder

Automatic follow-up reminders for unpaid fees.

### Payment Received

Send a payment confirmation receipt.

---

## Homework & Assignment Notifications

### New Assignment

Notify the student and guardian.

### Upcoming Deadline Reminder

Automatic reminders before the due date.

### Assignment Submitted

Notify the guardian of successful submission.

### Assignment Not Submitted

Alert the guardian after the deadline passes.

---

## School Announcement Notifications

### General Announcements

School-wide notices.

### Emergency Alerts

Urgent notifications:

- School closure
- Weather alerts
- Safety announcements

### Holiday Announcements

Inform parents and students about upcoming holidays.

### Event Announcements

Sports day, annual day, competitions, etc.

---

## Leave Management Notifications

### Leave Request Submitted

Notify the Headmaster/Teacher.

### Leave Approved

Notify the guardian and student.

### Leave Rejected

Send the rejection reason.

---

## Academic Performance Notifications

### Low Attendance Alert

Notify the guardian when attendance falls below a configured threshold.

### Low Performance Alert

Notify the guardian when marks fall below a configured threshold.

### Outstanding Performance

Send achievement notifications.

### Progress Report Published

Notify guardians when report cards are available.

---

## Transport Notifications (Optional)

### Bus Started Route

Notify guardians.

### Bus Near Pickup Point

Real-time alert.

### Student Boarded Bus

Guardian receives confirmation.

### Student Dropped Off

Guardian receives confirmation.

---

## Security Notifications

### New Login Detected

Notify users of account access.

### Password Changed

Security confirmation.

### Profile Updated

Notify the account owner.

---

# Notification Configuration System

Admin and Headmaster can:

- Enable/Disable specific notification types.
- Configure WhatsApp templates.
- Configure reminder schedules.
- Choose delivery channels:
  - WhatsApp
  - Push Notification
  - Email
  - SMS
- Customize messages per school.

---

# Communication Center

A centralized communication module for schools.

### Broadcast Messaging

Target audiences:

- Entire school
- Specific class
- Section
- Teachers
- Guardians
- Students

### Scheduled Messages

Schedule notifications for future delivery.

### Message Templates

Reusable templates for:

- Attendance
- Fees
- Exams
- Meetings
- Announcements

### Delivery Tracking

Track message status:

- Sent
- Delivered
- Read
- Failed

---

# Expected Result

A complete school communication ecosystem built with Flutter (GetX), FastAPI,
and PostgreSQL, where all important academic, attendance, fee, examination, and
school events automatically trigger WhatsApp notifications — ensuring continuous
communication between the school and guardians while reducing manual
administrative work.
