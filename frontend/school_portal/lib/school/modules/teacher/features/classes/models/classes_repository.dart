import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'teaching_class.dart';

class ClassesRepository {
  Future<ApiResponse<List<TeachingClass>>> fetch() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ApiResponse.ok(_all);
  }

  static const _all = <TeachingClass>[
    TeachingClass(
      id: 'C-1',
      subject: 'Mathematics',
      grade: 'Grade 8',
      description: 'Advanced Algebra & Geometry',
      students: 28,
      accent: AppColors.primary,
    ),
    TeachingClass(
      id: 'C-2',
      subject: 'Physics',
      grade: 'Grade 10',
      description: 'Mechanics & Thermodynamics',
      students: 24,
      accent: Color(0xFFE8A317),
    ),
    TeachingClass(
      id: 'C-3',
      subject: 'Mathematics',
      grade: 'Grade 11',
      description: 'Calculus Foundations',
      students: 18,
      accent: AppColors.aiAccent,
    ),
    TeachingClass(
      id: 'C-4',
      subject: 'Homeroom',
      grade: 'Grade 8',
      description: 'Section B Homeroom',
      students: 32,
      accent: AppColors.tertiary,
    ),
  ];
}
