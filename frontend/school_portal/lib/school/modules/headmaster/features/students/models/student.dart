import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

enum StudentStatus { active, pending, flagged }

extension StudentStatusX on StudentStatus {
  String get label => switch (this) {
        StudentStatus.active => 'Active',
        StudentStatus.pending => 'Pending',
        StudentStatus.flagged => 'Flagged',
      };

  Color get color => switch (this) {
        StudentStatus.active => AppColors.primary,
        StudentStatus.pending => const Color(0xFFE8A317),
        StudentStatus.flagged => AppColors.error,
      };
}

class Student {
  final String id;
  final String roll;
  final String name;
  final String grade;
  final String section;
  final String? avatarUrl;
  final StudentStatus status;

  const Student({
    required this.id,
    required this.roll,
    required this.name,
    required this.grade,
    required this.section,
    required this.status,
    this.avatarUrl,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: '${json['id']}',
        roll: '${json['roll'] ?? ''}',
        name: json['name'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        section: json['section'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        status: StudentStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => StudentStatus.active,
        ),
      );
}
