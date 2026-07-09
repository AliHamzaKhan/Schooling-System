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
from app.models.examination import Exam, ExamResult, ExamSeat, ExamSubject, Mark
from app.models.fees import FeeStructure, Invoice, Payment
from app.models.communication import (
    DeviceToken,
    Message,
    MessageDelivery,
    NotificationConfig,
    NotificationTemplate,
)
from app.models.direct_message import DirectMessage
from app.models.homework import Assignment, Submission
from app.models.library import Book, BookLoan
from app.models.hostel import HostelAllocation, HostelBlock, HostelRoom
from app.models.hr import Payslip, StaffProfile
from app.models.inventory import InventoryItem, StockTransaction
from app.models.ai import AIInteraction
from app.models.leave import LeaveRequest
from app.models.meeting import Meeting
from app.models.online_class import OnlineClass
from app.models.quiz import Quiz, QuizAnswer, QuizAssignment, QuizAttempt, QuizQuestion
from app.models.promotion import PromotionRecord
from app.models.calendar import CalendarEvent
from app.models.document import StudentDocument
from app.models.lesson import LessonPlan
from app.models.transport import Route, RouteStop, TransportAssignment, Vehicle
from app.models.base import Base
from app.models.role import Role, RolePermission
from app.models.school import AcademicSession, School, SchoolModule
from app.models.session import RefreshSession
from app.models.subscription import SubscriptionPlan
from app.models.user import User

__all__ = [
    "Base",
    "user_roles",
    "Role",
    "RolePermission",
    "AcademicSession",
    "School",
    "SchoolModule",
    "SubscriptionPlan",
    "User",
    "RefreshSession",
    "SchoolClass",
    "Section",
    "Subject",
    "TimetableSlot",
    "StudentEnrollment",
    "AttendanceRecord",
    "Exam",
    "ExamSubject",
    "Mark",
    "ExamResult",
    "ExamSeat",
    "FeeStructure",
    "Invoice",
    "Payment",
    "Assignment",
    "Submission",
    "NotificationTemplate",
    "NotificationConfig",
    "Message",
    "MessageDelivery",
    "DirectMessage",
    "DeviceToken",
    "Book",
    "BookLoan",
    "Vehicle",
    "Route",
    "RouteStop",
    "TransportAssignment",
    "HostelBlock",
    "HostelRoom",
    "HostelAllocation",
    "StaffProfile",
    "Payslip",
    "InventoryItem",
    "StockTransaction",
    "OnlineClass",
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
