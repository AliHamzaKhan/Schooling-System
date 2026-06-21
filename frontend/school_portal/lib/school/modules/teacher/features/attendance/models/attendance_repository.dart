import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'attendance_models.dart';

class AttendanceRepository {
  Future<ApiResponse<List<AttendanceClass>>> fetchClasses() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ApiResponse.ok(_classes);
  }

  Future<ApiResponse<List<AttendanceStudent>>> fetchStudents(String classId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ApiResponse.ok(_students);
  }

  static const _classes = <AttendanceClass>[
    AttendanceClass(
      id: 'MATH-G8',
      subject: 'Mathematics',
      grade: 'Grade 8',
      students: 28,
      icon: Icons.functions_rounded,
      color: AppColors.primary,
    ),
    AttendanceClass(
      id: 'ALG-101',
      subject: 'Algebra 101',
      grade: 'Grade 9',
      students: 24,
      icon: Icons.calculate_outlined,
      color: AppColors.aiAccent,
    ),
    AttendanceClass(
      id: 'CALC-II',
      subject: 'Calculus II',
      grade: 'Grade 11',
      students: 30,
      icon: Icons.science_outlined,
      color: AppColors.tertiary,
    ),
  ];

  static const _students = <AttendanceStudent>[
    AttendanceStudent(id: '8042-M', name: 'Alex Mercer', accent: Color(0xFFE8A317)),
    AttendanceStudent(id: '8045-T', name: 'Bella Torres', accent: AppColors.tertiary),
    AttendanceStudent(id: '8051-W', name: 'Caleb Wright', accent: AppColors.aiAccent),
    AttendanceStudent(id: '8062-P', name: 'Diana Patel', accent: AppColors.primary),
  ];
}
