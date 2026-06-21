import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

enum StudentAssignmentStatus { inProgress, notStarted, submitted }

extension StudentAssignmentStatusX on StudentAssignmentStatus {
  String get label => switch (this) {
        StudentAssignmentStatus.inProgress => 'In Progress',
        StudentAssignmentStatus.notStarted => 'Not Started',
        StudentAssignmentStatus.submitted => 'Submitted',
      };

  Color get color => switch (this) {
        StudentAssignmentStatus.inProgress => AppColors.primary,
        StudentAssignmentStatus.notStarted => AppColors.onSurfaceVariant,
        StudentAssignmentStatus.submitted => AppColors.tertiary,
      };
}

class StudentAssignment {
  final String id;
  final String subject;
  final String title;
  final String description;
  final String dueLine;
  final bool dueIsUrgent;
  final StudentAssignmentStatus status;
  final Color accent;
  final int points;

  /// Filename of an attached reference, if any.
  final String? attachment;

  const StudentAssignment({
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    required this.dueLine,
    required this.status,
    required this.accent,
    required this.points,
    this.dueIsUrgent = false,
    this.attachment,
  });

  factory StudentAssignment.fromJson(Map<String, dynamic> json) {
    final status = StudentAssignmentStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => StudentAssignmentStatus.notStarted,
    );
    return StudentAssignment(
      id: '${json['id']}',
      subject: json['subject'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dueLine: json['due_line'] as String? ?? '',
      status: status,
      // Accent is presentation — derive it from the status enum.
      accent: status.color,
      points: (json['points'] as num?)?.toInt() ?? 0,
      dueIsUrgent: json['due_is_urgent'] as bool? ?? false,
      attachment: json['attachment'] as String?,
    );
  }
}

class AssignmentsSummary {
  final int completed;
  final int total;
  final int inProgress;
  final int toDo;
  const AssignmentsSummary({
    required this.completed,
    required this.total,
    required this.inProgress,
    required this.toDo,
  });

  int get percent => total == 0 ? 0 : ((completed / total) * 100).round();

  factory AssignmentsSummary.fromJson(Map<String, dynamic> json) =>
      AssignmentsSummary(
        completed: (json['completed'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        inProgress: (json['in_progress'] as num?)?.toInt() ?? 0,
        toDo: (json['to_do'] as num?)?.toInt() ?? 0,
      );
}

class AssignmentsData {
  final AssignmentsSummary summary;
  final List<StudentAssignment> assignments;
  const AssignmentsData({required this.summary, required this.assignments});

  factory AssignmentsData.fromJson(Map<String, dynamic> json) => AssignmentsData(
        summary: AssignmentsSummary.fromJson(
            (json['summary'] as Map<String, dynamic>?) ?? const {}),
        assignments: ((json['assignments'] as List?) ?? [])
            .map((e) => StudentAssignment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
