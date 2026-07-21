import 'package:flutter/material.dart';

import '../../calendar/models/timetable_slot.dart';

/// Teacher home data, straight from `GET /schools/{id}/academic/me/dashboard`.
///
/// Every field is database-derived. There is no fixture behind this screen:
/// an empty to-do list means the teacher genuinely has nothing outstanding,
/// not that data is missing.

/// A navigation shortcut. Defined in the UI rather than fetched — these are
/// routes, not records, so there is nothing for the backend to return.
class QuickAction {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  const QuickAction({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

/// An item the teacher actually has to act on — ungraded submissions, or an
/// exam that is coming up.
class TodoItem {
  final String id;
  final String title;
  final String dueLine;
  final bool urgent;

  /// "grading" | "exam" — drives the leading icon.
  final String kind;

  const TodoItem({
    required this.id,
    required this.title,
    required this.dueLine,
    required this.kind,
    this.urgent = false,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        id: '${json['id']}',
        title: json['title'] as String? ?? '',
        dueLine: json['due_line'] as String? ?? '',
        urgent: json['urgent'] as bool? ?? false,
        kind: json['kind'] as String? ?? 'grading',
      );
}

/// Something this teacher recently created.
class RecentActivity {
  final String label;
  final DateTime time;
  final String kind;

  const RecentActivity({
    required this.label,
    required this.time,
    required this.kind,
  });

  /// "2h ago" / "3d ago" — relative, so it reads correctly whenever it loads.
  String get relative {
    final d = DateTime.now().difference(time);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays < 30) return '${d.inDays}d ago';
    return '${(d.inDays / 30).floor()}mo ago';
  }

  factory RecentActivity.fromJson(Map<String, dynamic> json) => RecentActivity(
        label: json['label'] as String? ?? '',
        time: DateTime.tryParse('${json['time']}')?.toLocal() ?? DateTime.now(),
        kind: json['kind'] as String? ?? 'assignment',
      );
}

class DashboardData {
  final String greeting;
  final String summary;
  final DateTime today;

  /// Today's periods, in start-time order.
  final List<TeacherSlot> schedule;
  final List<TodoItem> todos;
  final List<RecentActivity> recentActivity;
  final int pendingGrades;
  final int newSubmissions;
  final int sectionsTaught;

  const DashboardData({
    required this.greeting,
    required this.summary,
    required this.today,
    required this.schedule,
    required this.todos,
    required this.recentActivity,
    required this.pendingGrades,
    required this.newSubmissions,
    required this.sectionsTaught,
  });

  int get urgentCount => todos.where((t) => t.urgent).length;

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        greeting: json['greeting'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        today: DateTime.tryParse('${json['today']}') ?? DateTime.now(),
        schedule: ((json['schedule'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(TeacherSlot.fromJson)
            .toList(),
        todos: ((json['todos'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(TodoItem.fromJson)
            .toList(),
        recentActivity: ((json['recent_activity'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(RecentActivity.fromJson)
            .toList(),
        pendingGrades: (json['pending_grades'] as num?)?.toInt() ?? 0,
        newSubmissions: (json['new_submissions'] as num?)?.toInt() ?? 0,
        sectionsTaught: (json['sections_taught'] as num?)?.toInt() ?? 0,
      );
}
