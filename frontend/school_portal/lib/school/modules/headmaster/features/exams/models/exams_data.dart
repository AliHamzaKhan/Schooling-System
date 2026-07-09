import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Lifecycle state of an exam.
enum ExamStatus { live, upcoming, completed }

extension ExamStatusX on ExamStatus {
  String get label => switch (this) {
        ExamStatus.live => 'Live',
        ExamStatus.upcoming => 'Upcoming',
        ExamStatus.completed => 'Completed',
      };

  Color get color => switch (this) {
        ExamStatus.live => AppColors.error,
        ExamStatus.upcoming => AppColors.primary,
        ExamStatus.completed => AppColors.tertiary,
      };
}

/// One row in the Exam Schedule list.
class ExamScheduleItem {
  final String id;
  final String subject;
  final String grade;
  final String schedule;
  final String location;
  final IconData icon;
  final Color iconColor;
  final ExamStatus status;

  const ExamScheduleItem({
    required this.id,
    required this.subject,
    required this.grade,
    required this.schedule,
    required this.location,
    required this.icon,
    required this.iconColor,
    required this.status,
  });

  factory ExamScheduleItem.fromJson(Map<String, dynamic> json) =>
      ExamScheduleItem(
        id: '${json['id']}',
        subject: json['subject'] as String? ?? '',
        grade: '${json['grade'] ?? ''}',
        schedule: json['schedule'] as String? ?? '',
        location: json['location'] as String? ?? '',
        // icon/iconColor are presentation only — defaulted, not from the API.
        icon: Icons.school_outlined,
        iconColor: AppColors.primary,
        status: ExamStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => ExamStatus.upcoming,
        ),
      );
}

/// Lightweight recent-student row under "Student Results".
class RecentStudent {
  final String id;
  final String name;
  final String? avatarUrl;
  final Color accent;
  const RecentStudent({
    required this.id,
    required this.name,
    required this.accent,
    this.avatarUrl,
  });

  factory RecentStudent.fromJson(Map<String, dynamic> json) => RecentStudent(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        accent: AppColors.primary,
      );
}

/// Aggregate Exams & Results payload.
class ExamsData {
  final int activeExams;
  final int upcomingExams;
  final int pendingResults;
  final List<ExamScheduleItem> schedule;
  final List<RecentStudent> recent;
  final Map<String, int> gradeDistribution;

  const ExamsData({
    required this.activeExams,
    required this.upcomingExams,
    required this.pendingResults,
    required this.schedule,
    required this.recent,
    required this.gradeDistribution,
  });

  factory ExamsData.fromJson(Map<String, dynamic> json) => ExamsData(
        activeExams: (json['active_exams'] as num?)?.toInt() ?? 0,
        upcomingExams: (json['upcoming_exams'] as num?)?.toInt() ?? 0,
        pendingResults: (json['pending_results'] as num?)?.toInt() ?? 0,
        schedule: ((json['schedule'] as List?) ?? [])
            .map((e) => ExamScheduleItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        recent: ((json['recent'] as List?) ?? [])
            .map((e) => RecentStudent.fromJson(e as Map<String, dynamic>))
            .toList(),
        gradeDistribution:
            ((json['grade_distribution'] as Map?) ?? const {}).map(
          (k, v) => MapEntry('$k', (v as num).toInt()),
        ),
      );
}
