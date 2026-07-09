"""Core enumerations for the permission system.

These mirror the module list and action levels documented in
docs/permissions/01-super-admin.md and 03-headmaster-permissions.md.
"""
from enum import Enum


class Module(str, Enum):
    """The 20 toggleable modules a Super Admin can enable per school."""

    STUDENT_MANAGEMENT = "student_management"
    TEACHER_MANAGEMENT = "teacher_management"
    GUARDIAN_MANAGEMENT = "guardian_management"
    ATTENDANCE = "attendance"
    HOMEWORK = "homework"
    EXAMS = "exams"
    RESULTS = "results"
    FEE_MANAGEMENT = "fee_management"
    TIMETABLE = "timetable"
    LIBRARY = "library"
    TRANSPORT = "transport"
    HOSTEL = "hostel"
    HR_PAYROLL = "hr_payroll"
    INVENTORY = "inventory"
    MESSAGING = "messaging"
    ONLINE_CLASSES = "online_classes"
    AI_FEATURES = "ai_features"
    REPORTS = "reports"
    LEAVE_MANAGEMENT = "leave_management"
    MEETINGS = "meetings"
    MOBILE_APP = "mobile_app"
    API_ACCESS = "api_access"


class PermissionAction(str, Enum):
    """Access levels grantable per module."""

    VIEW = "view"
    CREATE = "create"
    EDIT = "edit"
    DELETE = "delete"
    APPROVE = "approve"
    EXPORT = "export"


class SystemRole(str, Enum):
    """Built-in roles seeded for every platform/school."""

    SUPER_ADMIN = "super_admin"
    HEADMASTER = "headmaster"
    TEACHER = "teacher"
    GUARDIAN = "guardian"
    STUDENT = "student"


class PlanCode(str, Enum):
    BASIC = "basic"
    STANDARD = "standard"
    PREMIUM = "premium"


class SchoolStatus(str, Enum):
    PENDING = "pending"
    ACTIVE = "active"
    SUSPENDED = "suspended"


class EnrollmentStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"


class AttendanceStatus(str, Enum):
    PRESENT = "present"
    ABSENT = "absent"
    LATE = "late"
    EARLY_DEPARTURE = "early_departure"
    EXCUSED = "excused"


class ExamStatus(str, Enum):
    DRAFT = "draft"
    SCHEDULED = "scheduled"
    COMPLETED = "completed"


class ResultStatus(str, Enum):
    PASS = "pass"
    FAIL = "fail"


class InvoiceStatus(str, Enum):
    UNPAID = "unpaid"
    PARTIAL = "partial"
    PAID = "paid"


class PaymentMethod(str, Enum):
    CASH = "cash"
    CARD = "card"
    BANK_TRANSFER = "bank_transfer"
    ONLINE = "online"
    CHEQUE = "cheque"


class SubmissionStatus(str, Enum):
    SUBMITTED = "submitted"
    LATE = "late"
    GRADED = "graded"
    APPROVED = "approved"
    REJECTED = "rejected"


class LessonStatus(str, Enum):
    PLANNED = "planned"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"


class CalendarEventType(str, Enum):
    HOLIDAY = "holiday"
    EVENT = "event"
    EXAM = "exam"
    ACADEMIC = "academic"
    OTHER = "other"


class PromotionOutcome(str, Enum):
    PROMOTED = "promoted"
    RETAINED = "retained"
    GRADUATED = "graduated"


class QuestionType(str, Enum):
    MCQ = "mcq"
    TRUE_FALSE = "true_false"
    SHORT = "short"


class QuizStatus(str, Enum):
    DRAFT = "draft"
    PUBLISHED = "published"
    CLOSED = "closed"


class AttemptStatus(str, Enum):
    IN_PROGRESS = "in_progress"
    SUBMITTED = "submitted"
    GRADED = "graded"


class Channel(str, Enum):
    WHATSAPP = "whatsapp"
    SMS = "sms"
    PUSH = "push"
    EMAIL = "email"


class AudienceType(str, Enum):
    ENTIRE_SCHOOL = "entire_school"
    CLASS = "class"
    SECTION = "section"
    TEACHERS = "teachers"
    GUARDIANS = "guardians"
    STUDENTS = "students"


class MessageStatus(str, Enum):
    SCHEDULED = "scheduled"
    PENDING = "pending"
    SENT = "sent"
    PARTIAL = "partial"
    FAILED = "failed"


class DeliveryStatus(str, Enum):
    SENT = "sent"
    DELIVERED = "delivered"
    READ = "read"
    FAILED = "failed"


class LoanStatus(str, Enum):
    BORROWED = "borrowed"
    RETURNED = "returned"


class NotificationEvent(str, Enum):
    """Configurable event triggers from docs/permissions/08."""

    ATTENDANCE_PRESENT = "attendance_present"
    ATTENDANCE_ABSENT = "attendance_absent"
    ATTENDANCE_LATE = "attendance_late"
    EXAM_SCHEDULED = "exam_scheduled"
    RESULT_PUBLISHED = "result_published"
    FEE_GENERATED = "fee_generated"
    FEE_DUE_REMINDER = "fee_due_reminder"
    FEE_OVERDUE = "fee_overdue"
    PAYMENT_RECEIVED = "payment_received"
    NEW_ASSIGNMENT = "new_assignment"
    ASSIGNMENT_DEADLINE = "assignment_deadline"
    ANNOUNCEMENT = "announcement"
    MEETING_SCHEDULED = "meeting_scheduled"
    LEAVE_STATUS = "leave_status"
