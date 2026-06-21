import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// A column in the permission matrix (one role).
class MatrixRole {
  final String id;
  final String shortLabel; // header chip text, e.g. "Admin"
  final IconData icon;
  const MatrixRole(
      {required this.id, required this.shortLabel, required this.icon});
}

/// A permission row, grouped under a [MatrixCategory].
class MatrixPermission {
  final String key;
  final String label;
  const MatrixPermission({required this.key, required this.label});
}

class MatrixCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<MatrixPermission> permissions;
  const MatrixCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.permissions,
  });
}

/// The full matrix payload: columns (roles), grouped rows, and the initial
/// grant set as "permissionKey:roleId" composite keys.
class PermissionMatrix {
  final List<MatrixRole> roles;
  final List<MatrixCategory> categories;
  final Set<String> grants; // "perm:role"
  const PermissionMatrix({
    required this.roles,
    required this.categories,
    required this.grants,
  });
}

class MatrixRepository {
  Future<ApiResponse<PermissionMatrix>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  static const _roles = <MatrixRole>[
    MatrixRole(id: 'admin', shortLabel: 'Admin', icon: Icons.shield_outlined),
    MatrixRole(
        id: 'teacher', shortLabel: 'Teacher', icon: Icons.menu_book_outlined),
    MatrixRole(
        id: 'guardian',
        shortLabel: 'Guardian',
        icon: Icons.family_restroom_outlined),
    MatrixRole(
        id: 'student', shortLabel: 'Student', icon: Icons.school_outlined),
  ];

  static const _categories = <MatrixCategory>[
    MatrixCategory(
      title: 'Academics',
      icon: Icons.menu_book_rounded,
      color: AppColors.primary,
      permissions: [
        MatrixPermission(key: 'view_grades', label: 'View grades'),
        MatrixPermission(key: 'edit_grades', label: 'Edit grades'),
        MatrixPermission(key: 'manage_homework', label: 'Manage homework'),
      ],
    ),
    MatrixCategory(
      title: 'Attendance',
      icon: Icons.event_available_rounded,
      color: AppColors.tertiary,
      permissions: [
        MatrixPermission(key: 'view_attendance', label: 'View attendance'),
        MatrixPermission(key: 'mark_attendance', label: 'Mark attendance'),
      ],
    ),
    MatrixCategory(
      title: 'Finance',
      icon: Icons.payments_outlined,
      color: Color(0xFFE8A317),
      permissions: [
        MatrixPermission(key: 'view_fees', label: 'View fees'),
        MatrixPermission(key: 'collect_fees', label: 'Collect fees'),
        MatrixPermission(key: 'refund', label: 'Issue refunds'),
      ],
    ),
    MatrixCategory(
      title: 'Administration',
      icon: Icons.admin_panel_settings_outlined,
      color: AppColors.error,
      permissions: [
        MatrixPermission(key: 'manage_users', label: 'Manage users'),
        MatrixPermission(key: 'delete_records', label: 'Delete records'),
      ],
    ),
  ];

  static const _grants = <String>{
    'view_grades:admin', 'view_grades:teacher', 'view_grades:guardian',
    'view_grades:student',
    'edit_grades:admin', 'edit_grades:teacher',
    'manage_homework:admin', 'manage_homework:teacher',
    'view_attendance:admin', 'view_attendance:teacher',
    'view_attendance:guardian', 'view_attendance:student',
    'mark_attendance:admin', 'mark_attendance:teacher',
    'view_fees:admin', 'view_fees:guardian',
    'collect_fees:admin',
    'refund:admin',
    'manage_users:admin',
    'delete_records:admin',
  };

  static const _mock = PermissionMatrix(
    roles: _roles,
    categories: _categories,
    grants: _grants,
  );
}
