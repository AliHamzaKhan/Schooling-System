import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

enum AssignmentStatus { active, draft, closed }

extension AssignmentStatusX on AssignmentStatus {
  String get label => switch (this) {
        AssignmentStatus.active => 'ACTIVE',
        AssignmentStatus.draft => 'DRAFT',
        AssignmentStatus.closed => 'CLOSED',
      };

  Color get color => switch (this) {
        AssignmentStatus.active => AppColors.error,
        AssignmentStatus.draft => AppColors.onSurfaceVariant,
        AssignmentStatus.closed => AppColors.aiAccent,
      };

  Color get rail => switch (this) {
        AssignmentStatus.active => AppColors.primary,
        AssignmentStatus.draft => const Color(0xFFE8A317),
        AssignmentStatus.closed => AppColors.aiAccent,
      };
}

/// One row in the Assignments Management list.
class Assignment {
  final String id;
  final String title;
  final String className;
  final String dueLabel;
  final AssignmentStatus status;
  final int turnedIn;
  final int total;
  final IconData icon;
  final Color iconAccent;
  final double? maxMarks;

  const Assignment({
    required this.id,
    required this.title,
    required this.className,
    required this.dueLabel,
    required this.status,
    required this.turnedIn,
    required this.total,
    required this.icon,
    required this.iconAccent,
    this.maxMarks,
  });

  double get progress => total == 0 ? 0 : turnedIn / total;

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: '${json['id']}',
        title: json['title'] as String? ?? '',
        className: json['class_name'] as String? ?? '',
        dueLabel: json['due_label'] as String? ?? '',
        status: AssignmentStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => AssignmentStatus.active,
        ),
        turnedIn: (json['turned_in'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        // icon/iconAccent are presentation only — defaulted, not from the API.
        icon: Icons.assignment_outlined,
        iconAccent: AppColors.primary,
      );
}

/// Headline KPIs at the top of the Tasks tab.
class AssignmentStats {
  final int toGrade;
  final int toGradeDelta;
  final int activeCount;
  final int activeAcrossClasses;
  final double averageTurnInRate;
  final double averageTurnInDelta;

  const AssignmentStats({
    required this.toGrade,
    required this.toGradeDelta,
    required this.activeCount,
    required this.activeAcrossClasses,
    required this.averageTurnInRate,
    required this.averageTurnInDelta,
  });

  factory AssignmentStats.fromJson(Map<String, dynamic> json) => AssignmentStats(
        toGrade: (json['to_grade'] as num?)?.toInt() ?? 0,
        toGradeDelta: (json['to_grade_delta'] as num?)?.toInt() ?? 0,
        activeCount: (json['active_count'] as num?)?.toInt() ?? 0,
        activeAcrossClasses:
            (json['active_across_classes'] as num?)?.toInt() ?? 0,
        averageTurnInRate:
            (json['average_turn_in_rate'] as num?)?.toDouble() ?? 0,
        averageTurnInDelta:
            (json['average_turn_in_delta'] as num?)?.toDouble() ?? 0,
      );
}

class AssignmentsData {
  final AssignmentStats stats;
  final List<Assignment> assignments;
  const AssignmentsData({required this.stats, required this.assignments});

  factory AssignmentsData.fromJson(Map<String, dynamic> json) => AssignmentsData(
        stats: AssignmentStats.fromJson(
            (json['stats'] as Map<String, dynamic>?) ?? const {}),
        assignments: ((json['assignments'] as List?) ?? [])
            .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
