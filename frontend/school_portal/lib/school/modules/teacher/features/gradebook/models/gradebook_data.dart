import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Marks sheet for one exam paper, from
/// `GET /schools/{id}/exams/papers/{paperId}/gradebook`.
///
/// The roster is the full enrolled class, marked or not — an unmarked class
/// still lists everyone, so the teacher can see who is outstanding.

class GradebookStudent {
  final String id;
  final String name;

  /// Existing mark, or null when this student hasn't been graded yet.
  final double? marks;
  final bool isAbsent;
  final Color accent;

  const GradebookStudent({
    required this.id,
    required this.name,
    required this.accent,
    this.marks,
    this.isAbsent = false,
  });

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory GradebookStudent.fromJson(Map<String, dynamic> json) =>
      GradebookStudent(
        id: '${json['student_id']}',
        name: json['student_name'] as String? ?? 'Student',
        marks: (json['marks_obtained'] as num?)?.toDouble(),
        isAbsent: json['is_absent'] as bool? ?? false,
        // Accent is presentation only; not part of the API contract.
        accent: AppColors.primary,
      );
}

class Gradebook {
  final String paperId;
  final String examName;
  final String subjectName;
  final String className;
  final double maxMarks;
  final double passMarks;
  final int totalStudents;
  final int markedCount;
  final List<GradebookStudent> students;

  const Gradebook({
    required this.paperId,
    required this.examName,
    required this.subjectName,
    required this.className,
    required this.maxMarks,
    required this.passMarks,
    required this.totalStudents,
    required this.markedCount,
    required this.students,
  });

  String get examTitle => '$examName — $subjectName';
  String get breadcrumb => '$className · out of ${maxMarks.toStringAsFixed(0)}';
  int get totalMarks => maxMarks.round();

  factory Gradebook.fromJson(Map<String, dynamic> json) => Gradebook(
        paperId: '${json['paper_id']}',
        examName: json['exam_name'] as String? ?? 'Exam',
        subjectName: json['subject_name'] as String? ?? 'Subject',
        className: json['class_name'] as String? ?? 'Class',
        maxMarks: (json['max_marks'] as num?)?.toDouble() ?? 100,
        passMarks: (json['pass_marks'] as num?)?.toDouble() ?? 0,
        totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
        markedCount: (json['marked_count'] as num?)?.toInt() ?? 0,
        students: ((json['students'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(GradebookStudent.fromJson)
            .toList(),
      );
}

/// An exam paper the teacher can grade, for the paper picker.
class GradablePaper {
  final String paperId;
  final String examName;
  final String subjectName;
  final double maxMarks;

  const GradablePaper({
    required this.paperId,
    required this.examName,
    required this.subjectName,
    required this.maxMarks,
  });

  String get label => '$examName — $subjectName';
}
