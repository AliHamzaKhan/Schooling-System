import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class GradebookStudent {
  final String id;
  final String name;
  final Color accent;
  const GradebookStudent({
    required this.id,
    required this.name,
    required this.accent,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  factory GradebookStudent.fromJson(Map<String, dynamic> json) =>
      GradebookStudent(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        // Accent is presentation only; not part of the API contract.
        accent: AppColors.primary,
      );
}

class Gradebook {
  final String examTitle;
  final String breadcrumb;
  final int totalMarks;
  final int totalStudents;
  final List<GradebookStudent> students;
  const Gradebook({
    required this.examTitle,
    required this.breadcrumb,
    required this.totalMarks,
    required this.totalStudents,
    required this.students,
  });

  factory Gradebook.fromJson(Map<String, dynamic> json) => Gradebook(
        examTitle: json['exam_title'] as String? ?? '',
        breadcrumb: json['breadcrumb'] as String? ?? '',
        totalMarks: (json['total_marks'] as num?)?.toInt() ?? 0,
        totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
        students: ((json['students'] as List?) ?? [])
            .map((e) => GradebookStudent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
