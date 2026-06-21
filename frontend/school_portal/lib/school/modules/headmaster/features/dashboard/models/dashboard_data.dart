import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Pending approval awaiting Headmaster sign-off.
class PendingApproval {
  final String id;
  final IconData icon;
  final String title;
  final String requestedBy;
  const PendingApproval({
    required this.id,
    required this.icon,
    required this.title,
    required this.requestedBy,
  });

  factory PendingApproval.fromJson(Map<String, dynamic> json) => PendingApproval(
        id: '${json['id']}',
        // icon is presentation only — defaulted, not from the API.
        icon: Icons.pending_actions_rounded,
        title: json['title'] as String? ?? '',
        requestedBy: json['requested_by'] as String? ?? '',
      );
}

/// Compact recent-announcement row shown on the dashboard.
class RecentAnnouncementSummary {
  final String id;
  final String title;
  final String preview;
  final String timeAgo;
  final Color accent;
  const RecentAnnouncementSummary({
    required this.id,
    required this.title,
    required this.preview,
    required this.timeAgo,
    required this.accent,
  });

  factory RecentAnnouncementSummary.fromJson(Map<String, dynamic> json) =>
      RecentAnnouncementSummary(
        id: '${json['id']}',
        title: json['title'] as String? ?? '',
        preview: json['preview'] as String? ?? '',
        timeAgo: json['time_ago'] as String? ?? '',
        accent: AppColors.primary,
      );
}

/// One headline KPI on the dashboard (Total Students, etc.).
class DashboardMetric {
  final String label;
  final String value;
  final double trendPercent;
  final IconData icon;
  final Color color;
  const DashboardMetric({
    required this.label,
    required this.value,
    required this.trendPercent,
    required this.icon,
    required this.color,
  });

  bool get hasTrend => trendPercent != 0;

  factory DashboardMetric.fromJson(Map<String, dynamic> json) => DashboardMetric(
        label: json['label'] as String? ?? '',
        value: '${json['value'] ?? ''}',
        trendPercent: (json['trend_percent'] as num?)?.toDouble() ?? 0,
        // icon/color are presentation only — defaulted, not from the API.
        icon: Icons.insights_rounded,
        color: AppColors.primary,
      );
}

/// Aggregate payload for the Headmaster Dashboard.
class DashboardData {
  final String greeting;
  final String date;
  final List<DashboardMetric> metrics;
  final List<PendingApproval> approvals;
  final List<RecentAnnouncementSummary> announcements;

  const DashboardData({
    required this.greeting,
    required this.date,
    required this.metrics,
    required this.approvals,
    required this.announcements,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        greeting: json['greeting'] as String? ?? '',
        date: json['date'] as String? ?? '',
        metrics: ((json['metrics'] as List?) ?? [])
            .map((e) => DashboardMetric.fromJson(e as Map<String, dynamic>))
            .toList(),
        approvals: ((json['approvals'] as List?) ?? [])
            .map((e) => PendingApproval.fromJson(e as Map<String, dynamic>))
            .toList(),
        announcements: ((json['announcements'] as List?) ?? [])
            .map((e) =>
                RecentAnnouncementSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
