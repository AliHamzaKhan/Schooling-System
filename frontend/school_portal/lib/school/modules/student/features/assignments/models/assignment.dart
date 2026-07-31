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

/// The student's own submission for an assignment, when one exists. Mirrors the
/// backend `my_submission` (SubmissionBrief) so the detail screen can render the
/// real turned-in state instead of reopening the submit form.
class StudentSubmission {
  /// Raw backend status: submitted | late | graded | approved | rejected.
  final String status;
  final String submittedOn;
  final String? attachmentUrl;
  final double? marksObtained;
  final String? feedback;

  /// When the teacher first opened this submission (the read receipt), or null.
  final String? seenAt;

  const StudentSubmission({
    required this.status,
    required this.submittedOn,
    this.attachmentUrl,
    this.marksObtained,
    this.feedback,
    this.seenAt,
  });

  bool get isLate => status == 'late';
  bool get isGraded => status == 'graded';
  bool get isReviewed =>
      status == 'graded' || status == 'approved' || status == 'rejected';
  bool get isRejected => status == 'rejected';

  /// The teacher has opened this submission (read receipt) or already acted.
  bool get isSeen => (seenAt ?? '').isNotEmpty || isReviewed;

  factory StudentSubmission.fromJson(Map<String, dynamic> json) =>
      StudentSubmission(
        status: (json['status'] as String? ?? '').toLowerCase(),
        submittedOn: json['submitted_on'] as String? ?? '',
        attachmentUrl: json['attachment_url'] as String?,
        marksObtained: (json['marks_obtained'] as num?)?.toDouble(),
        feedback: json['feedback'] as String?,
        seenAt: json['seen_at'] as String?,
      );
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

  /// The student's own submission, when they have turned this in.
  final StudentSubmission? submission;

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
    this.submission,
  });

  bool get isSubmitted => submission != null;

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
