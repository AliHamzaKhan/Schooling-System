"""Static mappings derived from the spec docs.

PLAN_MODULES encodes docs/permissions/02-subscription-plans.md. These are used
to seed subscription plans; the database remains the source of truth at runtime.
"""
from app.core.enums import Module, PermissionAction, PlanCode, SystemRole

# Core people-management modules are available in every plan: every school must
# be able to manage its teachers/students/guardians and create staff regardless
# of tier. The subscription gates only feature modules (exams, fees, online
# classes, AI, etc.). (Product decision, 2026-06-17.)
_CORE_MANAGEMENT = [
    Module.STUDENT_MANAGEMENT,
    Module.TEACHER_MANAGEMENT,
    Module.GUARDIAN_MANAGEMENT,
]

# Basic plan modules
_BASIC = _CORE_MANAGEMENT + [
    Module.ATTENDANCE,
    Module.TIMETABLE,
    Module.MESSAGING,  # Announcements live under Messaging & Chat
    Module.LEAVE_MANAGEMENT,  # Core school operations, available to all plans
    Module.MEETINGS,
]

# Standard = Basic + exams/results/homework
_STANDARD = _BASIC + [
    Module.EXAMS,
    Module.RESULTS,
    Module.HOMEWORK,
]

# Premium = every module
_PREMIUM = list(Module)

PLAN_MODULES: dict[PlanCode, list[Module]] = {
    PlanCode.BASIC: _BASIC,
    PlanCode.STANDARD: _STANDARD,
    PlanCode.PREMIUM: _PREMIUM,
}

PLAN_NAMES: dict[PlanCode, str] = {
    PlanCode.BASIC: "Basic Plan",
    PlanCode.STANDARD: "Standard Plan",
    PlanCode.PREMIUM: "Premium Plan",
}

# Default monthly list price seeded per plan (admin-editable at runtime).
PLAN_PRICES: dict[PlanCode, float] = {
    PlanCode.BASIC: 299.0,
    PlanCode.STANDARD: 799.0,
    PlanCode.PREMIUM: 1499.0,
}

# Default student cap seeded per plan (None = unlimited; admin-editable).
PLAN_MAX_STUDENTS: dict[PlanCode, int | None] = {
    PlanCode.BASIC: 200,
    PlanCode.STANDARD: 750,
    PlanCode.PREMIUM: None,
}

# --------------------------------------------------------------------------- #
# Role provisioning
# --------------------------------------------------------------------------- #

_A = PermissionAction
_ALL = set(PermissionAction)

# Default permission baselines applied when a school's roles are provisioned
# (docs/permissions/03 Headmaster, 05 Teacher/Staff). The Super Admin may refine
# Headmaster permissions, and the Headmaster may refine staff permissions, via
# the Role & Permission Management module. Effective access is still gated by
# the subscription/module cascade at runtime.
DEFAULT_ROLE_PERMISSIONS: dict[str, dict[Module, set[PermissionAction]]] = {
    # The Headmaster runs the whole school: grant all actions on every module.
    # Effective access is still bounded by the subscription/toggle cascade, so a
    # module the plan omits stays unavailable regardless.
    SystemRole.HEADMASTER.value: {module: _ALL for module in Module},
    SystemRole.TEACHER.value: {
        Module.ATTENDANCE: {_A.VIEW, _A.CREATE, _A.EDIT},
        Module.HOMEWORK: {_A.VIEW, _A.CREATE, _A.EDIT, _A.DELETE},
        Module.EXAMS: {_A.VIEW, _A.CREATE, _A.EDIT},
        Module.RESULTS: {_A.VIEW, _A.CREATE, _A.EDIT},
        Module.STUDENT_MANAGEMENT: {_A.VIEW},
        Module.TIMETABLE: {_A.VIEW},
        Module.MESSAGING: {_A.VIEW, _A.CREATE},
    },
    SystemRole.GUARDIAN.value: {
        Module.ATTENDANCE: {_A.VIEW},
        Module.RESULTS: {_A.VIEW},
        Module.EXAMS: {_A.VIEW},
        Module.HOMEWORK: {_A.VIEW},
        Module.FEE_MANAGEMENT: {_A.VIEW},
        Module.TIMETABLE: {_A.VIEW},
        Module.MEETINGS: {_A.VIEW},
        Module.MESSAGING: {_A.VIEW, _A.CREATE},
    },
    SystemRole.STUDENT.value: {
        Module.ATTENDANCE: {_A.VIEW},
        Module.RESULTS: {_A.VIEW},
        Module.EXAMS: {_A.VIEW},
        Module.HOMEWORK: {_A.VIEW},
        Module.TIMETABLE: {_A.VIEW},
        Module.MESSAGING: {_A.VIEW},
    },
    # A driver reads their assigned students/trips and updates trip state
    # (start/end, board/drop). No create/delete — the Headmaster owns setup.
    SystemRole.DRIVER.value: {
        Module.TRANSPORT: {_A.VIEW, _A.EDIT},
    },
}

ROLE_DISPLAY_NAMES: dict[str, str] = {
    SystemRole.HEADMASTER.value: "Headmaster",
    SystemRole.TEACHER.value: "Teacher",
    SystemRole.GUARDIAN.value: "Guardian",
    SystemRole.STUDENT.value: "Student",
    SystemRole.DRIVER.value: "Driver",
}

# Maps a role code to the module that governs creating/managing such a user.
ROLE_MODULE_MAP: dict[str, Module] = {
    SystemRole.TEACHER.value: Module.TEACHER_MANAGEMENT,
    SystemRole.STUDENT.value: Module.STUDENT_MANAGEMENT,
    SystemRole.GUARDIAN.value: Module.GUARDIAN_MANAGEMENT,
    # Creating/managing a driver is governed by the Transport module.
    SystemRole.DRIVER.value: Module.TRANSPORT,
}

# Module governing creation of custom/staff roles (anything not in ROLE_MODULE_MAP).
DEFAULT_STAFF_MODULE: Module = Module.TEACHER_MANAGEMENT

# --------------------------------------------------------------------------- #
# Examination grading
# --------------------------------------------------------------------------- #

# (minimum percentage inclusive, grade). Checked high-to-low.
GRADE_BANDS: list[tuple[float, str]] = [
    (90.0, "A+"),
    (80.0, "A"),
    (70.0, "B"),
    (60.0, "C"),
    (50.0, "D"),
    (0.0, "F"),
]


def grade_for(percentage: float) -> str:
    for minimum, grade in GRADE_BANDS:
        if percentage >= minimum:
            return grade
    return "F"
