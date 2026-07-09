import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Education level a grade belongs to (controls badge tint).
enum GradeLevel { primary, middle, high }

extension GradeLevelX on GradeLevel {
  String get label => switch (this) {
        GradeLevel.primary => 'Primary',
        GradeLevel.middle => 'Middle',
        GradeLevel.high => 'High',
      };

  Color get color => switch (this) {
        GradeLevel.primary => AppColors.primary,
        GradeLevel.middle => AppColors.tertiary,
        GradeLevel.high => AppColors.aiAccent,
      };
}

/// One section inside a grade (Section A, Section B, …).
class ClassSection {
  final String id;
  final String name;
  final int students;
  final String? teacher;
  final String? teacherAvatarUrl;
  final Color accent;

  const ClassSection({
    required this.id,
    required this.name,
    required this.students,
    required this.accent,
    this.teacher,
    this.teacherAvatarUrl,
  });

  factory ClassSection.fromJson(Map<String, dynamic> json) => ClassSection(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        students: (json['students'] as num?)?.toInt() ?? 0,
        teacher: json['teacher'] as String?,
        teacherAvatarUrl: json['teacher_avatar_url'] as String?,
        accent: AppColors.primary,
      );
}

/// One grade group with its sections. [classId]/[className] identify the
/// backing class so the UI can add sections to it or edit/delete it.
class GradeGroup {
  final String classId;
  final String className;
  final int grade;
  final GradeLevel level;
  final List<ClassSection> sections;
  const GradeGroup({
    this.classId = '',
    this.className = '',
    required this.grade,
    required this.level,
    required this.sections,
  });

  factory GradeGroup.fromJson(Map<String, dynamic> json) => GradeGroup(
        classId: '${json['class_id'] ?? json['id'] ?? ''}',
        className: json['class_name'] as String? ?? '',
        grade: (json['grade'] as num?)?.toInt() ?? 0,
        level: GradeLevel.values.firstWhere(
          (l) => l.name == json['level'],
          orElse: () => GradeLevel.primary,
        ),
        sections: ((json['sections'] as List?) ?? [])
            .map((e) => ClassSection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Top-of-screen KPIs (Total Students, Active Classes, etc.).
class ClassStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const ClassStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  factory ClassStat.fromJson(Map<String, dynamic> json) => ClassStat(
        label: json['label'] as String? ?? '',
        value: '${json['value'] ?? ''}',
        // icon/color are presentation only — defaulted, not from the API.
        icon: Icons.insights_rounded,
        color: AppColors.primary,
      );
}

/// Aggregate payload for Class Directory.
class ClassDirectoryData {
  final List<ClassStat> stats;
  final List<GradeGroup> grades;
  const ClassDirectoryData({required this.stats, required this.grades});

  factory ClassDirectoryData.fromJson(Map<String, dynamic> json) =>
      ClassDirectoryData(
        stats: ((json['stats'] as List?) ?? [])
            .map((e) => ClassStat.fromJson(e as Map<String, dynamic>))
            .toList(),
        grades: ((json['grades'] as List?) ?? [])
            .map((e) => GradeGroup.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
