import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class UpcomingExam {
  final String id;
  final String title;
  final String date;
  final String time;
  final String location;
  final String dateShort;
  final Color accent;

  const UpcomingExam({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.dateShort,
    required this.accent,
  });

  factory UpcomingExam.fromJson(Map<String, dynamic> json) => UpcomingExam(
        id: '${json['id']}',
        title: json['title'] as String? ?? '',
        date: json['date'] as String? ?? '',
        time: json['time'] as String? ?? '',
        location: json['location'] as String? ?? '',
        dateShort: json['date_short'] as String? ?? '',
        // Accent is cosmetic and not part of the backend contract.
        accent: AppColors.primary,
      );
}

class ExamCountdown {
  final int days;
  final int hours;
  final String title;
  final String date;
  final String time;
  final String location;

  const ExamCountdown({
    required this.days,
    required this.hours,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
  });

  factory ExamCountdown.fromJson(Map<String, dynamic> json) => ExamCountdown(
        days: (json['days'] as num?)?.toInt() ?? 0,
        hours: (json['hours'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        date: json['date'] as String? ?? '',
        time: json['time'] as String? ?? '',
        location: json['location'] as String? ?? '',
      );
}

class ExamsData {
  final int comingThisMonth;
  final ExamCountdown next;
  final List<UpcomingExam> timeline;
  const ExamsData({
    required this.comingThisMonth,
    required this.next,
    required this.timeline,
  });

  factory ExamsData.fromJson(Map<String, dynamic> json) => ExamsData(
        comingThisMonth: (json['coming_this_month'] as num?)?.toInt() ?? 0,
        next: ExamCountdown.fromJson(
            (json['next'] as Map<String, dynamic>?) ?? const {}),
        timeline: ((json['timeline'] as List?) ?? [])
            .map((e) => UpcomingExam.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
