import 'package:flutter/material.dart';

import '../../../ui/tokens/app_colors.dart';

/// Compact relative time for a message/thread ("now", "5m", "3h", "2d", or a
/// short date for anything older than a week).
String messagingRelativeTime(DateTime? t) {
  if (t == null) return '';
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[t.month - 1]} ${t.day}';
}

/// Clock time for a message bubble ("9:05 AM").
String messagingClock(DateTime? t) {
  if (t == null) return '';
  final h24 = t.hour;
  final period = h24 < 12 ? 'AM' : 'PM';
  final h = h24 % 12 == 0 ? 12 : h24 % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m $period';
}

/// A stable accent for a role label, used on avatars and role chips.
Color messagingRoleColor(String role) => switch (role.toLowerCase()) {
      'teacher' => AppColors.primary,
      'guardian' => AppColors.tertiary,
      'student' => AppColors.aiAccent,
      'headmaster' => AppColors.primaryContainer,
      _ => AppColors.secondary,
    };
