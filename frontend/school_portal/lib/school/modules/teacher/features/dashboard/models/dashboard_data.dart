import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Neutral fallbacks for presentation-only fields that the backend does not
/// supply (the rich icons/colours live in the mock fixtures / UI layer).
const _defaultRail = AppColors.primary;

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

  factory QuickAction.fromJson(Map<String, dynamic> json) => QuickAction(
        label: json['label'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        icon: Icons.bolt_outlined,
        color: _defaultRail,
      );
}

class ScheduleItem {
  final String time;
  final String period;
  final String title;
  final String location;
  final int students;
  final Color railColor;

  /// True for non-class blocks (Office Hours / Planning) — renders muted.
  final bool isPlanning;

  const ScheduleItem({
    required this.time,
    required this.period,
    required this.title,
    required this.location,
    required this.students,
    required this.railColor,
    this.isPlanning = false,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
        time: json['time'] as String? ?? '',
        period: json['period'] as String? ?? '',
        title: json['title'] as String? ?? '',
        location: json['location'] as String? ?? '',
        students: (json['students'] as num?)?.toInt() ?? 0,
        railColor: _defaultRail,
        isPlanning: json['is_planning'] as bool? ?? false,
      );
}

class TodoItem {
  final String id;
  final String title;
  final String dueLine;
  final bool urgent;
  final bool done;
  const TodoItem({
    required this.id,
    required this.title,
    required this.dueLine,
    this.urgent = false,
    this.done = false,
  });

  TodoItem copyWith({bool? done}) => TodoItem(
        id: id,
        title: title,
        dueLine: dueLine,
        urgent: urgent,
        done: done ?? this.done,
      );

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        id: '${json['id']}',
        title: json['title'] as String? ?? '',
        dueLine: json['due_line'] as String? ?? '',
        urgent: json['urgent'] as bool? ?? false,
        done: json['done'] as bool? ?? false,
      );
}

class RecentUpload {
  final String label;
  final String time;
  const RecentUpload({required this.label, required this.time});

  factory RecentUpload.fromJson(Map<String, dynamic> json) => RecentUpload(
        label: json['label'] as String? ?? '',
        time: json['time'] as String? ?? '',
      );
}

class DashboardData {
  final String greeting;
  final String summary;
  final List<QuickAction> actions;
  final List<ScheduleItem> schedule;
  final List<TodoItem> todos;
  final int pendingGrades;
  final int newSubmissions;
  final List<RecentUpload> uploads;

  const DashboardData({
    required this.greeting,
    required this.summary,
    required this.actions,
    required this.schedule,
    required this.todos,
    required this.pendingGrades,
    required this.newSubmissions,
    required this.uploads,
  });

  int get urgentCount => todos.where((t) => t.urgent && !t.done).length;

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        greeting: json['greeting'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        actions: ((json['actions'] as List?) ?? [])
            .map((e) => QuickAction.fromJson(e as Map<String, dynamic>))
            .toList(),
        schedule: ((json['schedule'] as List?) ?? [])
            .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        todos: ((json['todos'] as List?) ?? [])
            .map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        pendingGrades: (json['pending_grades'] as num?)?.toInt() ?? 0,
        newSubmissions: (json['new_submissions'] as num?)?.toInt() ?? 0,
        uploads: ((json['uploads'] as List?) ?? [])
            .map((e) => RecentUpload.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
