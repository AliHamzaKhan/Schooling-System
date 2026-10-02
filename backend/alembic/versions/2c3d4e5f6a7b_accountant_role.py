"""Accountant role for every school that already has its roles.

New schools receive it from the default role provisioning.

Revision ID: 2c3d4e5f6a7b
Revises: 1b2c3d4e5f6a
"""

import sqlalchemy as sa
from alembic import op

revision = "2c3d4e5f6a7b"
down_revision = "1b2c3d4e5f6a"
branch_labels = None
depends_on = None

# module -> (view, create, edit, delete, approve, export); mirrors
# DEFAULT_ROLE_PERMISSIONS["accountant"] at the time of this migration.
_PERMISSIONS = {
    "fee_management": (True, True, True, False, False, True),
    "hr_payroll": (True, True, True, False, False, True),
    "reports": (True, False, False, False, False, True),
    "student_management": (True, False, False, False, False, False),
    "timetable": (True, False, False, False, False, False),
    "messaging": (True, True, False, False, False, False),
}


def upgrade():
    conn = op.get_bind()
    schools = conn.execute(sa.text(
        "SELECT DISTINCT school_id FROM roles WHERE school_id IS NOT NULL "
        "AND school_id NOT IN (SELECT school_id FROM roles WHERE code = 'accountant' AND school_id IS NOT NULL)"
    )).scalars().all()
    for school_id in schools:
        role_id = conn.execute(sa.text(
            "INSERT INTO roles (id, school_id, code, name, is_system, created_at, updated_at) "
            "VALUES (gen_random_uuid(), :school, 'accountant', 'Accountant', false, now(), now()) RETURNING id"
        ), {"school": school_id}).scalar_one()
        for module, (view, create, edit, delete, approve, export) in _PERMISSIONS.items():
            conn.execute(sa.text(
                "INSERT INTO role_permissions (id, role_id, module, can_view, can_create, can_edit, "
                "can_delete, can_approve, can_export, created_at, updated_at) VALUES (gen_random_uuid(), "
                ":role, :module, :view, :create, :edit, :delete, :approve, :export, now(), now())"
            ), {"role": role_id, "module": module, "view": view, "create": create, "edit": edit,
                "delete": delete, "approve": approve, "export": export})


def downgrade():
    # Only removes accountant roles nobody holds; assigned roles are kept.
    op.execute(
        "DELETE FROM role_permissions WHERE role_id IN (SELECT id FROM roles WHERE code = 'accountant' "
        "AND school_id IS NOT NULL AND id NOT IN (SELECT role_id FROM user_roles))"
    )
    op.execute(
        "DELETE FROM roles WHERE code = 'accountant' AND school_id IS NOT NULL "
        "AND id NOT IN (SELECT role_id FROM user_roles)"
    )
