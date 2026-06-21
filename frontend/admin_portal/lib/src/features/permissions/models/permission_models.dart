import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// A selectable role on the Role-Based Access Control screen.
class PermissionRole {
  final String id;
  final String label;
  final IconData icon;
  const PermissionRole({required this.id, required this.label, required this.icon});
}

/// A single toggleable permission within a [PermissionGroup].
class PermissionItem {
  final String key;
  final String title;
  final String subtitle;
  final bool enabled;

  const PermissionItem({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  PermissionItem copyWith({bool? enabled}) => PermissionItem(
        key: key,
        title: title,
        subtitle: subtitle,
        enabled: enabled ?? this.enabled,
      );
}

/// A titled group of permissions (e.g. "Global Access", "Data Operations").
class PermissionGroup {
  final String title;
  final IconData icon;
  final Color color;
  final List<PermissionItem> items;

  const PermissionGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  PermissionGroup copyWith({List<PermissionItem>? items}) => PermissionGroup(
        title: title,
        icon: icon,
        color: color,
        items: items ?? this.items,
      );
}

/// A school row on the "Select School to Configure" list.
class SchoolPermissionSummary {
  final String id;
  final String name;
  final String planLabel;
  final Color planColor;
  final int activeModules;
  final int totalModules;
  final IconData icon;
  final Color accent;

  const SchoolPermissionSummary({
    required this.id,
    required this.name,
    required this.planLabel,
    required this.planColor,
    required this.activeModules,
    required this.totalModules,
    required this.icon,
    required this.accent,
  });
}

/// Mock data + helpers backing the permissions module.
class PermissionsData {
  PermissionsData._();

  static const roles = <PermissionRole>[
    PermissionRole(id: 'admin', label: 'Administrator', icon: Icons.shield_outlined),
    PermissionRole(id: 'teacher', label: 'Teacher', icon: Icons.menu_book_outlined),
    PermissionRole(id: 'guardian', label: 'Guardian', icon: Icons.family_restroom_outlined),
    PermissionRole(id: 'student', label: 'Student', icon: Icons.school_outlined),
  ];

  static List<PermissionGroup> defaultPolicy() => [
        PermissionGroup(
          title: 'Global Access',
          icon: Icons.public_rounded,
          color: AppColors.primary,
          items: const [
            PermissionItem(
                key: 'login',
                title: 'Platform Login',
                subtitle: 'Allow user to authenticate',
                enabled: true),
            PermissionItem(
                key: 'api',
                title: 'API Access',
                subtitle: 'Generate API tokens',
                enabled: true),
            PermissionItem(
                key: 'mobile',
                title: 'Mobile App',
                subtitle: 'Login via mobile clients',
                enabled: false),
          ],
        ),
        PermissionGroup(
          title: 'Data Operations',
          icon: Icons.shield_outlined,
          color: AppColors.error,
          items: const [
            PermissionItem(
                key: 'export',
                title: 'Export Records',
                subtitle: 'Download student & staff data',
                enabled: true),
            PermissionItem(
                key: 'delete',
                title: 'Delete Records',
                subtitle: 'Permanently remove entities',
                enabled: false),
            PermissionItem(
                key: 'bulk',
                title: 'Bulk Edit',
                subtitle: 'Modify records in batches',
                enabled: true),
          ],
        ),
      ];

  static const schools = <SchoolPermissionSummary>[
    SchoolPermissionSummary(
      id: '8842-GH',
      name: 'Greenwood High',
      planLabel: 'Full Suite',
      planColor: AppColors.primary,
      activeModules: 12,
      totalModules: 15,
      icon: Icons.school_rounded,
      accent: AppColors.primary,
    ),
    SchoolPermissionSummary(
      id: '1029-SM',
      name: "St. Mary's Academy",
      planLabel: 'Standard Academic',
      planColor: AppColors.aiAccent,
      activeModules: 8,
      totalModules: 15,
      icon: Icons.account_balance_rounded,
      accent: Color(0xFFE8A317),
    ),
  ];
}
