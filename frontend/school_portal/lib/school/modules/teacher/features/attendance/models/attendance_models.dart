import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

enum AttendanceMark { unmarked, present, late, absent }

extension AttendanceMarkX on AttendanceMark {
  Color get color => switch (this) {
        AttendanceMark.present => AppColors.tertiary,
        AttendanceMark.late => const Color(0xFFE8A317),
        AttendanceMark.absent => AppColors.error,
        AttendanceMark.unmarked => AppColors.onSurfaceVariant,
      };

  IconData get icon => switch (this) {
        AttendanceMark.present => Icons.check_circle_outline_rounded,
        AttendanceMark.late => Icons.access_time_rounded,
        AttendanceMark.absent => Icons.cancel_outlined,
        AttendanceMark.unmarked => Icons.radio_button_unchecked_rounded,
      };

  String get label => switch (this) {
        AttendanceMark.present => 'Present',
        AttendanceMark.late => 'Late',
        AttendanceMark.absent => 'Absent',
        AttendanceMark.unmarked => 'Unmarked',
      };
}

/// A class/grade row in the Attendance tab list (entry point to marking).
class AttendanceClass {
  final String id;
  final String subject;
  final String grade;
  final int students;
  final IconData icon;
  final Color color;

  const AttendanceClass({
    required this.id,
    required this.subject,
    required this.grade,
    required this.students,
    required this.icon,
    required this.color,
  });

  factory AttendanceClass.fromJson(Map<String, dynamic> json) =>
      AttendanceClass(
        id: '${json['id']}',
        subject: json['subject'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        students: (json['students'] as num?)?.toInt() ?? 0,
        // icon/color are presentation only — defaulted, not from the API.
        icon: Icons.class_outlined,
        color: AppColors.primary,
      );
}

/// A student row in the marking screen.
class AttendanceStudent {
  final String id;
  final String name;
  final String? avatarUrl;
  final Color accent;

  const AttendanceStudent({
    required this.id,
    required this.name,
    required this.accent,
    this.avatarUrl,
  });

  String get initial =>
      name.isEmpty ? '?' : name.characters.first.toUpperCase();

  factory AttendanceStudent.fromJson(Map<String, dynamic> json) =>
      AttendanceStudent(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        accent: AppColors.primary,
      );
}
