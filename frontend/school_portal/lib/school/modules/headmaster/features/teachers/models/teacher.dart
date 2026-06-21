import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

enum TeacherStatus { active, onLeave }

extension TeacherStatusX on TeacherStatus {
  String get label => switch (this) {
        TeacherStatus.active => 'Active',
        TeacherStatus.onLeave => 'On Leave',
      };

  Color get color => switch (this) {
        TeacherStatus.active => AppColors.tertiary,
        TeacherStatus.onLeave => const Color(0xFFE8A317),
      };
}

class Teacher {
  final String id;
  final String name;
  final String department;
  final String? avatarUrl;
  final TeacherStatus status;

  /// Accent rail color (cycles through the brand palette per teacher).
  final Color accent;

  const Teacher({
    required this.id,
    required this.name,
    required this.department,
    required this.status,
    required this.accent,
    this.avatarUrl,
  });

  String get initials {
    final parts = name.replaceAll(RegExp(r'^(Dr|Mr|Mrs|Ms)\.?\s+'), '')
        .trim()
        .split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        department: json['department'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        status: TeacherStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => TeacherStatus.active,
        ),
        // Accent is presentation only; not part of the API contract.
        accent: AppColors.primary,
      );
}
