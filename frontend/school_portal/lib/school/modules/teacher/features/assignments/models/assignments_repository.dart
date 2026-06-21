import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'assignment.dart';

class AssignmentsRepository {
  Future<ApiResponse<AssignmentsData>> load({String? classFilter}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final filtered = classFilter == null || classFilter == 'All Classes'
        ? _all
        : _all.where((a) => a.className == classFilter).toList();
    return ApiResponse.ok(AssignmentsData(stats: _stats, assignments: filtered));
  }

  static const _stats = AssignmentStats(
    toGrade: 42,
    toGradeDelta: 12,
    activeCount: 8,
    activeAcrossClasses: 3,
    averageTurnInRate: 0.94,
    averageTurnInDelta: 0.02,
  );

  static const _all = <Assignment>[
    Assignment(
      id: 'A-1',
      title: 'Quadratic Equations Worksheet',
      className: 'Algebra 101',
      dueLabel: 'Due Tomorrow, 11:59 PM',
      status: AssignmentStatus.active,
      turnedIn: 18,
      total: 24,
      icon: Icons.functions_rounded,
      iconAccent: AppColors.primary,
    ),
    Assignment(
      id: 'A-2',
      title: 'Midterm Review Packet',
      className: 'Calculus II',
      dueLabel: 'Not scheduled',
      status: AssignmentStatus.draft,
      turnedIn: 0,
      total: 30,
      icon: Icons.draw_outlined,
      iconAccent: Color(0xFFE8A317),
    ),
    Assignment(
      id: 'A-3',
      title: 'Week 4 Problem Set',
      className: 'Algebra 101',
      dueLabel: 'Due Oct 12',
      status: AssignmentStatus.closed,
      turnedIn: 24,
      total: 24,
      icon: Icons.checklist_rtl_outlined,
      iconAccent: AppColors.error,
    ),
    Assignment(
      id: 'A-4',
      title: 'Derivatives Pop Quiz',
      className: 'Calculus II',
      dueLabel: 'Due in 2 hours',
      status: AssignmentStatus.active,
      turnedIn: 12,
      total: 30,
      icon: Icons.warning_amber_rounded,
      iconAccent: AppColors.error,
    ),
  ];
}
