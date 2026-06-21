import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'classes_data.dart';

class ClassesRepository {
  Future<ApiResponse<ClassDirectoryData>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  static const _mock = ClassDirectoryData(
    stats: [
      ClassStat(
        label: 'Total Students',
        value: '1,248',
        icon: Icons.school_rounded,
        color: AppColors.primary,
      ),
      ClassStat(
        label: 'Active Classes',
        value: '36',
        icon: Icons.meeting_room_outlined,
        color: Color(0xFFE8A317),
      ),
      ClassStat(
        label: 'Teachers Assigned',
        value: '42',
        icon: Icons.group_outlined,
        color: AppColors.aiAccent,
      ),
      ClassStat(
        label: 'Avg Class Size',
        value: '28',
        icon: Icons.groups_2_outlined,
        color: AppColors.tertiary,
      ),
    ],
    grades: [
      GradeGroup(
        grade: 1,
        level: GradeLevel.primary,
        sections: [
          ClassSection(
            id: 'G1-A',
            name: 'Section A',
            students: 25,
            teacher: 'Sarah Jenkins',
            accent: Color(0xFFE8A317),
          ),
          ClassSection(
            id: 'G1-B',
            name: 'Section B',
            students: 24,
            teacher: 'Michael Chang',
            accent: AppColors.primary,
          ),
        ],
      ),
      GradeGroup(
        grade: 2,
        level: GradeLevel.primary,
        sections: [
          ClassSection(
            id: 'G2-A',
            name: 'Section A',
            students: 28,
            teacher: 'David Miller',
            accent: AppColors.aiAccent,
          ),
        ],
      ),
      GradeGroup(
        grade: 8,
        level: GradeLevel.middle,
        sections: [
          ClassSection(
            id: 'G8-X',
            name: 'Section X',
            students: 30,
            teacher: 'Elena Lopez',
            accent: AppColors.tertiary,
          ),
        ],
      ),
    ],
  );
}
