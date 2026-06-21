import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class GradeFeedback {
  final String id;
  final String title;
  final String dateLine;
  final String quote;
  final String grade;
  final IconData icon;
  final Color iconColor;
  const GradeFeedback({
    required this.id,
    required this.title,
    required this.dateLine,
    required this.quote,
    required this.grade,
    required this.icon,
    required this.iconColor,
  });

  factory GradeFeedback.fromJson(Map<String, dynamic> json) => GradeFeedback(
        id: '${json['id']}',
        title: json['title'] as String? ?? '',
        dateLine: json['date_line'] as String? ?? '',
        quote: json['quote'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        // icon/iconColor are presentation only — defaulted, not from the API.
        icon: Icons.grading_rounded,
        iconColor: AppColors.primary,
      );
}

enum DayMark { present, absent }

class WeekDay {
  final String label;
  final DayMark mark;
  const WeekDay(this.label, this.mark);

  factory WeekDay.fromJson(Map<String, dynamic> json) => WeekDay(
        json['label'] as String? ?? '',
        DayMark.values.firstWhere(
          (m) => m.name == json['mark'],
          orElse: () => DayMark.present,
        ),
      );
}

class StudentDetail {
  final String id;
  final String name;
  final String? avatarUrl;
  final String grade;
  final String subject;
  final String currentGpa;
  final String attendancePercent;
  final List<String> trendLabels;
  final List<double> trendScores;
  final List<WeekDay> week;
  final List<GradeFeedback> recent;

  const StudentDetail({
    required this.id,
    required this.name,
    required this.grade,
    required this.subject,
    required this.currentGpa,
    required this.attendancePercent,
    required this.trendLabels,
    required this.trendScores,
    required this.week,
    required this.recent,
    this.avatarUrl,
  });

  factory StudentDetail.fromJson(Map<String, dynamic> json) => StudentDetail(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        grade: json['grade'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        currentGpa: '${json['current_gpa'] ?? ''}',
        attendancePercent: '${json['attendance_percent'] ?? ''}',
        trendLabels: ((json['trend_labels'] as List?) ?? [])
            .map((e) => '$e')
            .toList(),
        trendScores: ((json['trend_scores'] as List?) ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
        week: ((json['week'] as List?) ?? [])
            .map((e) => WeekDay.fromJson(e as Map<String, dynamic>))
            .toList(),
        recent: ((json['recent'] as List?) ?? [])
            .map((e) => GradeFeedback.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
