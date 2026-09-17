"""Import all models so Alembic autogenerate and metadata see them."""
from app.models.academic import (
    Section,
    SchoolClass,
    StudentEnrollment,
    Subject,
    TimetableSlot,
)
from app.models.associations import user_roles
from app.models.attendance import AttendanceRecord
from app.models.teacher_attendance import TeacherAttendance
from app.models.examination import (
    Exam,
    ExamCategory,
    ExamResult,
    ExamSeat,
    ExamSubject,
    Mark,
)
from app.models.fees import FeeStructure, Invoice, Payment
from app.models.communication import (
    DeviceToken,
    Message,
    MessageDelivery,
    NotificationConfig,
    NotificationTemplate,
    NotificationOutbox,
)
from app.models.course import (
    BookChapter,
    Course,
    CourseBook,
    CourseNote,
    ReadingProgress,
)
from app.models.direct_message import DirectMessage
from app.models.homework import Assignment, Submission
from app.models.hr import Payslip, StaffProfile
from app.models.inventory import InventoryItem, StockTransaction
from app.models.ai import AIInteraction
from app.models.leave import LeaveRequest
from app.models.meeting import Meeting
from app.models.quiz import Quiz, QuizAnswer, QuizAssignment, QuizAttempt, QuizQuestion
from app.models.promotion import PromotionRecord
from app.models.calendar import CalendarEvent
from app.models.document import StudentDocument
from app.models.lesson import LessonPlan
from app.models.transport import (
    Driver,
    Route,
    RouteStop,
    TransportAssignment,
    TransportRequest,
    TransportTrip,
    TripStudentEvent,
    Vehicle,
    VehicleLocation,
)
from app.models.base import Base
from app.models.role import Role, RolePermission
from app.models.school import AcademicSession, School, SchoolModule
from app.models.password_reset import PasswordReset
from app.models.school_info import SchoolInfo
from app.models.session import RefreshSession
from app.models.subscription import (
    SchoolSubscription,
    SubscriptionPayment,
    SubscriptionPlan,
)
from app.models.user import User

__all__ = [
    "NotificationOutbox",
    "Base",
    "user_roles",
    "Role",
    "RolePermission",
    "AcademicSession",
    "School",
    "SchoolModule",
    "SubscriptionPlan",
    "SchoolSubscription",
    "SubscriptionPayment",
    "User",
    "RefreshSession",
    "PasswordReset",
    "SchoolClass",
    "Section",
    "Subject",
    "TimetableSlot",
    "StudentEnrollment",
    "AttendanceRecord",
    "TeacherAttendance",
    "Exam",
    "ExamCategory",
    "ExamSubject",
    "Mark",
    "ExamResult",
    "ExamSeat",
    "FeeStructure",
    "Invoice",
    "Payment",
    "Assignment",
    "Submission",
    "Course",
    "CourseBook",
    "BookChapter",
    "CourseNote",
    "ReadingProgress",
    "SchoolInfo",
    "NotificationTemplate",
    "NotificationConfig",
    "Message",
    "MessageDelivery",
    "DirectMessage",
    "DeviceToken",
    "Vehicle",
    "Driver",
    "Route",
    "RouteStop",
    "TransportAssignment",
    "TransportRequest",
    "TransportTrip",
    "TripStudentEvent",
    "VehicleLocation",
    "StaffProfile",
    "Payslip",
    "InventoryItem",
    "StockTransaction",
    "AIInteraction",
    "LeaveRequest",
    "Meeting",
    "Quiz",
    "QuizQuestion",
    "QuizAttempt",
    "QuizAnswer",
    "QuizAssignment",
    "PromotionRecord",
    "CalendarEvent",
    "StudentDocument",
    "LessonPlan",
]
