import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// One scheduled lesson in a single (day, time) cell.
class Lesson {
  final String subject;
  final String classLabel;
  final String teacher;
  final Color color;

  const Lesson({
    required this.subject,
    required this.classLabel,
    required this.teacher,
    required this.color,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        subject: json['subject'] as String? ?? '',
        classLabel: json['class_label'] as String? ?? '',
        teacher: json['teacher'] as String? ?? '',
        // Color is presentation only; not part of the API contract.
        color: AppColors.primary,
      );
}

/// A row in the timetable grid; either a [Lesson] or a break/empty row.
class TimeSlot {
  final String label;
  final bool isBreak;

  /// Map of day-name → Lesson; missing keys render as empty cells.
  final Map<String, Lesson> lessons;

  const TimeSlot({
    required this.label,
    required this.lessons,
    this.isBreak = false,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        label: json['label'] as String? ?? '',
        isBreak: json['is_break'] as bool? ?? false,
        lessons: ((json['lessons'] as Map?) ?? const {}).map(
          (k, v) => MapEntry('$k', Lesson.fromJson(v as Map<String, dynamic>)),
        ),
      );
}

class TimetableData {
  final List<String> days;
  final List<TimeSlot> slots;
  const TimetableData({required this.days, required this.slots});

  factory TimetableData.fromJson(Map<String, dynamic> json) => TimetableData(
        days: ((json['days'] as List?) ?? []).map((e) => '$e').toList(),
        slots: ((json['slots'] as List?) ?? [])
            .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
