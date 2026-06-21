import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

enum GuardianStatus { active, pending }

extension GuardianStatusX on GuardianStatus {
  String get label => switch (this) {
        GuardianStatus.active => 'Active',
        GuardianStatus.pending => 'Pending',
      };

  Color get color => switch (this) {
        GuardianStatus.active => AppColors.primary,
        GuardianStatus.pending => const Color(0xFFE8A317),
      };
}

class LinkedStudent {
  final String id;
  final String name;
  final String grade;
  final Color color;
  const LinkedStudent({
    required this.id,
    required this.name,
    required this.grade,
    required this.color,
  });

  String get label => '$name (Grade $grade)';

  factory LinkedStudent.fromJson(Map<String, dynamic> json) => LinkedStudent(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        grade: '${json['grade'] ?? ''}',
        // Color is presentation only; not part of the API contract.
        color: AppColors.primary,
      );
}

class Guardian {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final GuardianStatus status;
  final List<LinkedStudent> linkedStudents;

  const Guardian({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.linkedStudents,
    this.phone,
    this.avatarUrl,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  factory Guardian.fromJson(Map<String, dynamic> json) => Guardian(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        status: GuardianStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => GuardianStatus.active,
        ),
        linkedStudents: ((json['linked_students'] as List?) ?? [])
            .map((e) => LinkedStudent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
