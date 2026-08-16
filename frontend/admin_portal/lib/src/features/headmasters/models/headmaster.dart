import 'package:flutter/material.dart';
import '../../../ui/admin_theme.dart';

/// Employment/onboarding state of a headmaster.
enum HeadmasterStatus { active, onLeave, pendingSetup }

extension HeadmasterStatusX on HeadmasterStatus {
  String get label => switch (this) {
        HeadmasterStatus.active => 'Active',
        HeadmasterStatus.onLeave => 'On Leave',
        HeadmasterStatus.pendingSetup => 'Pending Setup',
      };

  Color get color => switch (this) {
        HeadmasterStatus.active => AdminPalette.positive,
        HeadmasterStatus.onLeave => AdminPalette.warning,
        HeadmasterStatus.pendingSetup => AdminPalette.danger,
      };
}

/// A school headmaster managed from the admin Headmaster Management screen.
class Headmaster {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? school;

  /// Backend school id this headmaster belongs to — needed to target
  /// update/deactivate calls (`/schools/{schoolId}/users/{id}`).
  final String? schoolId;
  final HeadmasterStatus status;
  final String? avatarUrl;

  const Headmaster({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.phone,
    this.school,
    this.schoolId,
    this.avatarUrl,
  });

  /// Up-to-two-letter initials for the avatar placeholder.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  factory Headmaster.fromJson(Map<String, dynamic> j) => Headmaster(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        phone: j['phone'] as String?,
        school: j['school'] as String?,
        status: HeadmasterStatus.values.byName(j['status'] as String? ?? 'active'),
        avatarUrl: j['avatarUrl'] as String?,
      );
}
