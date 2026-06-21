import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// A managed role on the Role Management screen. `level` drives the
/// hierarchical visualization (0 = highest authority). `system` roles are
/// built-in and cannot be deleted.
class ManagedRole {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int level; // 0 = top of hierarchy
  final int userCount;
  final int permissionCount;
  final bool system;
  final bool active;

  const ManagedRole({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.level,
    required this.userCount,
    required this.permissionCount,
    required this.system,
    required this.active,
  });

  ManagedRole copyWith({bool? active}) => ManagedRole(
        id: id,
        name: name,
        description: description,
        icon: icon,
        color: color,
        level: level,
        userCount: userCount,
        permissionCount: permissionCount,
        system: system,
        active: active ?? this.active,
      );
}

class RolesRepository {
  Future<ApiResponse<List<ManagedRole>>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(List<ManagedRole>.from(_mock));
  }

  static const _mock = <ManagedRole>[
    ManagedRole(
      id: 'super_admin',
      name: 'Super Admin',
      description: 'Full platform control across all schools',
      icon: Icons.shield_moon_outlined,
      color: AppColors.primary,
      level: 0,
      userCount: 3,
      permissionCount: 42,
      system: true,
      active: true,
    ),
    ManagedRole(
      id: 'school_admin',
      name: 'School Admin',
      description: 'Manage a single school and its staff',
      icon: Icons.admin_panel_settings_outlined,
      color: AppColors.aiAccent,
      level: 1,
      userCount: 28,
      permissionCount: 31,
      system: true,
      active: true,
    ),
    ManagedRole(
      id: 'teacher',
      name: 'Teacher',
      description: 'Classes, attendance, grades and homework',
      icon: Icons.menu_book_outlined,
      color: Color(0xFFE8A317),
      level: 2,
      userCount: 412,
      permissionCount: 18,
      system: true,
      active: true,
    ),
    ManagedRole(
      id: 'guardian',
      name: 'Guardian',
      description: 'View linked children\'s progress and fees',
      icon: Icons.family_restroom_outlined,
      color: AppColors.tertiary,
      level: 3,
      userCount: 1860,
      permissionCount: 9,
      system: true,
      active: true,
    ),
    ManagedRole(
      id: 'student',
      name: 'Student',
      description: 'Assignments, exams and personal schedule',
      icon: Icons.school_outlined,
      color: AppColors.secondary,
      level: 3,
      userCount: 2304,
      permissionCount: 7,
      system: true,
      active: true,
    ),
    ManagedRole(
      id: 'accountant',
      name: 'Accountant',
      description: 'Custom role — fee collection and reports',
      icon: Icons.calculate_outlined,
      color: AppColors.primary,
      level: 2,
      userCount: 14,
      permissionCount: 11,
      system: false,
      active: false,
    ),
  ];
}
