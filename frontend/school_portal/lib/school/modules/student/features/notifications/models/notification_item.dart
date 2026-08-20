import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

enum NotificationKind { assignment, examResult, announcement }

extension NotificationKindX on NotificationKind {
  Color get color => switch (this) {
        NotificationKind.assignment => AppColors.primary,
        NotificationKind.examResult => const Color(0xFFE8A317),
        NotificationKind.announcement => AppColors.aiAccent,
      };

  IconData get icon => switch (this) {
        NotificationKind.assignment => AppIcons.assignmentOutlined,
        NotificationKind.examResult => AppIcons.barChartRounded,
        NotificationKind.announcement => AppIcons.campaignOutlined,
      };
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final NotificationKind kind;
  final bool unread;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.kind,
    this.unread = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: '${json['id']}',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        timeAgo: json['time_ago'] as String? ?? '',
        kind: NotificationKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => NotificationKind.announcement,
        ),
        unread: json['unread'] as bool? ?? false,
      );
}
