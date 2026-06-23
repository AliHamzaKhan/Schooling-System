import 'package:flutter/material.dart';

/// A child (student) linked to the signed-in guardian. The Guardian module is
/// multi-child: every feature reads the currently selected [Child] from the
/// [GuardianSessionController].
class Child {
  final String id; // the student's user id
  final String name;
  final String grade; // e.g. "Grade 5 — Section B"
  final String? photoUrl;

  /// The student's active section (needed to scope timetable + homework).
  /// Null when the student is not yet enrolled in a section.
  final String? sectionId;

  /// At-a-glance figures used by dashboard summary cards.
  final int attendancePercent; // 0..100
  final double gpa; // 0..4
  final int pendingHomework;
  final bool feesDue;

  const Child({
    required this.id,
    required this.name,
    required this.grade,
    this.photoUrl,
    this.sectionId,
    required this.attendancePercent,
    required this.gpa,
    required this.pendingHomework,
    required this.feesDue,
  });

  /// Parse a child from the backend `ChildOut` shape
  /// (`GET /schools/{id}/me/children`). At-a-glance stats are not part of that
  /// payload — they default to 0/false and the per-feature screens show the
  /// live detail.
  factory Child.fromJson(Map<String, dynamic> json) {
    final section = json['section_name'] as String?;
    final cls = json['class_name'] as String?;
    final level = json['grade_level'];
    final gradeLabel = [
      if (cls != null && cls.isNotEmpty) cls else if (level != null) 'Grade $level',
      if (section != null && section.isNotEmpty) 'Section $section',
    ].join(' — ');
    return Child(
      id: '${json['student_id'] ?? json['id']}',
      name: json['full_name'] as String? ?? json['name'] as String? ?? '',
      grade: gradeLabel,
      photoUrl: json['photo_url'] as String?,
      sectionId: json['section_id']?.toString(),
      attendancePercent: (json['attendance_percent'] as num?)?.toInt() ?? 0,
      gpa: (json['gpa'] as num?)?.toDouble() ?? 0,
      pendingHomework: (json['pending_homework'] as num?)?.toInt() ?? 0,
      feesDue: json['fees_due'] as bool? ?? false,
    );
  }

  /// Initials for the avatar fallback ("Aanya Khan" -> "AK").
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
