import 'package:shared/shared.dart';

import 'student.dart';

class StudentsRepository {
  static const pageSize = 4;

  Future<ApiResponse<List<Student>>> fetch({
    String query = '',
    String? grade,
    String? section,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final q = query.toLowerCase();
    final filtered = _all.where((s) {
      final matchQ = q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.roll.toLowerCase().contains(q);
      final matchG = grade == null || grade == 'All Grades' || s.grade == grade;
      final matchSec =
          section == null || section == 'All Sections' || s.section == section;
      return matchQ && matchG && matchSec;
    }).toList();
    return ApiResponse.ok(filtered);
  }

  static const _all = <Student>[
    Student(
      id: 'S-1042',
      roll: '1042',
      name: 'Leo Vance',
      grade: '10th',
      section: 'Alpha',
      status: StudentStatus.active,
    ),
    Student(
      id: 'S-1043',
      roll: '1043',
      name: 'Mia Chen',
      grade: '11th',
      section: 'Beta',
      status: StudentStatus.active,
    ),
    Student(
      id: 'S-1044',
      roll: '1044',
      name: 'Elias Thorne',
      grade: '9th',
      section: 'Alpha',
      status: StudentStatus.pending,
    ),
    Student(
      id: 'S-1045',
      roll: '1045',
      name: 'Sophie Laine',
      grade: '12th',
      section: 'Gamma',
      status: StudentStatus.active,
    ),
    Student(
      id: 'S-1046',
      roll: '1046',
      name: 'Noah Patel',
      grade: '9th',
      section: 'Beta',
      status: StudentStatus.flagged,
    ),
  ];
}
