import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// One KPI tile on Attendance Overview.
class AttendanceMetric {
  final String label;
  final String value;
  final double trendPercent;
  final IconData icon;
  final Color color;

  const AttendanceMetric({
    required this.label,
    required this.value,
    required this.trendPercent,
    required this.icon,
    required this.color,
  });

  factory AttendanceMetric.fromJson(Map<String, dynamic> json) =>
      AttendanceMetric(
        label: json['label'] as String? ?? '',
        value: '${json['value'] ?? ''}',
        trendPercent: (json['trend_percent'] as num?)?.toDouble() ?? 0,
        // icon/color are presentation only — defaulted, not from the API.
        icon: Icons.insights_rounded,
        color: AppColors.primary,
      );
}

/// Single row in the Grade Level Breakdown list.
class GradeAttendance {
  final int grade;
  final String name;
  final int percent;
  final Color color;
  const GradeAttendance({
    required this.grade,
    required this.name,
    required this.percent,
    required this.color,
  });

  factory GradeAttendance.fromJson(Map<String, dynamic> json) => GradeAttendance(
        grade: (json['grade'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        percent: (json['percent'] as num?)?.toInt() ?? 0,
        color: AppColors.primary,
      );
}

enum AttendanceRange { week, month }

/// Aggregate payload for the Attendance Overview screen.
class AttendanceData {
  final List<AttendanceMetric> metrics;
  final int studentRatePercent;
  final int teacherRatePercent;
  final List<String> trendLabels;
  final List<double> studentTrend;
  final List<double> teacherTrend;
  final List<GradeAttendance> grades;

  const AttendanceData({
    required this.metrics,
    required this.studentRatePercent,
    required this.teacherRatePercent,
    required this.trendLabels,
    required this.studentTrend,
    required this.teacherTrend,
    required this.grades,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) => AttendanceData(
        metrics: ((json['metrics'] as List?) ?? [])
            .map((e) => AttendanceMetric.fromJson(e as Map<String, dynamic>))
            .toList(),
        studentRatePercent: (json['student_rate_percent'] as num?)?.toInt() ?? 0,
        teacherRatePercent: (json['teacher_rate_percent'] as num?)?.toInt() ?? 0,
        trendLabels:
            ((json['trend_labels'] as List?) ?? []).map((e) => '$e').toList(),
        studentTrend: ((json['student_trend'] as List?) ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
        teacherTrend: ((json['teacher_trend'] as List?) ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
        grades: ((json['grades'] as List?) ?? [])
            .map((e) => GradeAttendance.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
