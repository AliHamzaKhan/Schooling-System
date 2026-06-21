import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Kind of activity surfaced in the dashboard timeline feed. Drives the icon
/// and accent colour of each entry.
enum ActivityKind { attendance, grade, homework, fee, exam, meeting, notice }

extension ActivityKindStyle on ActivityKind {
  IconData get icon => switch (this) {
        ActivityKind.attendance => Icons.event_available_rounded,
        ActivityKind.grade => Icons.grading_rounded,
        ActivityKind.homework => Icons.assignment_outlined,
        ActivityKind.fee => Icons.payments_outlined,
        ActivityKind.exam => Icons.school_outlined,
        ActivityKind.meeting => Icons.groups_outlined,
        ActivityKind.notice => Icons.campaign_outlined,
      };

  Color get color => switch (this) {
        ActivityKind.attendance => AppColors.tertiary,
        ActivityKind.grade => AppColors.primary,
        ActivityKind.homework => const Color(0xFFE8A317),
        ActivityKind.fee => AppColors.error,
        ActivityKind.exam => AppColors.primary,
        ActivityKind.meeting => AppColors.secondary,
        ActivityKind.notice => AppColors.aiAccent,
      };
}

/// One entry in the timeline-based activity feed.
class ActivityItem {
  final ActivityKind kind;
  final String title;
  final String detail;
  final String timeAgo; // e.g. "2h ago", "Yesterday"

  const ActivityItem({
    required this.kind,
    required this.title,
    required this.detail,
    required this.timeAgo,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
        kind: ActivityKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => ActivityKind.notice,
        ),
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        timeAgo: json['time_ago'] as String? ?? '',
      );
}
