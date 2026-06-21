import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'assignment.dart';

class AssignmentsRepository {
  Future<ApiResponse<AssignmentsData>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  Future<ApiResponse<StudentAssignment>> fetchOne(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final found = _mock.assignments.firstWhere(
      (a) => a.id == id,
      orElse: () => _industrialRevolution,
    );
    return ApiResponse.ok(found);
  }

  static const _industrialRevolution = StudentAssignment(
    id: 'A-IR',
    subject: 'History 101',
    title: 'The Industrial Revolution',
    description:
        'Write a 3-5 page essay analyzing the primary socioeconomic impacts '
        'of the Industrial Revolution in Great Britain between 1760 and 1840. '
        'Focus particularly on urbanization, labor conditions, and class '
        'structure changes. Please cite at least three primary sources from '
        'the provided reading list.',
    dueLine: 'Due: Friday, Oct 27, 11:59 PM',
    status: StudentAssignmentStatus.notStarted,
    accent: Color(0xFFE8A317),
    points: 100,
    attachment: 'Reading_List_Chapter4.pdf',
  );

  static const _mock = AssignmentsData(
    summary: AssignmentsSummary(
      completed: 7,
      total: 10,
      inProgress: 2,
      toDo: 1,
    ),
    assignments: [
      StudentAssignment(
        id: 'A-1',
        subject: 'Algebra 101',
        title: 'Quadratic Equations Practice',
        description:
            'Complete problems 1-15 in Chapter 4. Show all work for partial credit.',
        dueLine: 'Due Tomorrow, 11:59 PM',
        dueIsUrgent: true,
        status: StudentAssignmentStatus.inProgress,
        accent: AppColors.primary,
        points: 20,
      ),
      StudentAssignment(
        id: 'A-2',
        subject: 'World History',
        title: 'Industrial Revolution Essay',
        description:
            'Write a 500-word essay on the socioeconomic impacts of early textil…',
        dueLine: 'Due Friday, 5:00 PM',
        status: StudentAssignmentStatus.notStarted,
        accent: AppColors.aiAccent,
        points: 50,
      ),
      StudentAssignment(
        id: 'A-3',
        subject: 'Biology Lab',
        title: 'Cellular Mitosis Report',
        description:
            'Review lab notes and submit the final data table outlining the cell cycle…',
        dueLine: 'Due Next Monday, 8:00 AM',
        status: StudentAssignmentStatus.notStarted,
        accent: AppColors.tertiary,
        points: 40,
      ),
    ],
  );
}
