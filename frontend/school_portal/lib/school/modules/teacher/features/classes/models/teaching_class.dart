import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class TeachingClass {
  final String id;
  final String subject;
  final String grade;
  final String description;
  final int students;
  final Color accent;
  const TeachingClass({
    required this.id,
    required this.subject,
    required this.grade,
    required this.description,
    required this.students,
    required this.accent,
  });

  factory TeachingClass.fromJson(Map<String, dynamic> json) => TeachingClass(
        id: '${json['id']}',
        subject: json['subject'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        description: json['description'] as String? ?? '',
        students: (json['students'] as num?)?.toInt() ?? 0,
        // Accent is presentation only; not part of the API contract.
        accent: AppColors.primary,
      );
}
