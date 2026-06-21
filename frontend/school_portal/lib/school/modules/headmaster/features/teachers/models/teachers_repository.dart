import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'teacher.dart';

class TeachersRepository {
  Future<ApiResponse<List<Teacher>>> fetch({String query = ''}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (query.isEmpty) return ApiResponse.ok(_all);
    final q = query.toLowerCase();
    return ApiResponse.ok(_all
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            t.department.toLowerCase().contains(q))
        .toList());
  }

  static const _all = <Teacher>[
    Teacher(
      id: 'T-001',
      name: 'Dr. Alan Grant',
      department: 'Science Dept.',
      status: TeacherStatus.active,
      accent: AppColors.primary,
    ),
    Teacher(
      id: 'T-002',
      name: 'Sarah Jenkins',
      department: 'Arts & Lit',
      status: TeacherStatus.onLeave,
      accent: Color(0xFFE8A317),
    ),
    Teacher(
      id: 'T-003',
      name: 'Marcus Cole',
      department: 'Mathematics',
      status: TeacherStatus.active,
      accent: AppColors.aiAccent,
    ),
    Teacher(
      id: 'T-004',
      name: 'Elena Ruiz',
      department: 'Music',
      status: TeacherStatus.active,
      accent: AppColors.tertiary,
    ),
  ];
}
