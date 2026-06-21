import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Severity of a guardian alert — drives the accent colour and leading icon in
/// the notification UI system.
enum AlertLevel { info, success, warning, critical }

extension AlertLevelStyle on AlertLevel {
  Color get color => switch (this) {
        AlertLevel.info => AppColors.primary,
        AlertLevel.success => AppColors.tertiary,
        AlertLevel.warning => const Color(0xFFE8A317),
        AlertLevel.critical => AppColors.error,
      };

  IconData get icon => switch (this) {
        AlertLevel.info => Icons.info_outline_rounded,
        AlertLevel.success => Icons.check_circle_outline_rounded,
        AlertLevel.warning => Icons.warning_amber_rounded,
        AlertLevel.critical => Icons.error_outline_rounded,
      };
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final AlertLevel level;
  final String? childName; // which child this concerns, if any
  final bool read;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.level,
    this.childName,
    this.read = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: '${json['id']}',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        timeAgo: json['time_ago'] as String? ?? '',
        level: AlertLevel.values.firstWhere(
          (l) => l.name == json['level'],
          orElse: () => AlertLevel.info,
        ),
        childName: json['child_name'] as String?,
        read: json['read'] as bool? ?? false,
      );

  NotificationItem copyWith({bool? read}) => NotificationItem(
        id: id,
        title: title,
        body: body,
        timeAgo: timeAgo,
        level: level,
        childName: childName,
        read: read ?? this.read,
      );
}
