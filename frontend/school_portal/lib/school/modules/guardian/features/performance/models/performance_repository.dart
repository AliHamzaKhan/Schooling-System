import 'package:shared/shared.dart';

import 'performance_data.dart';

class PerformanceRepository {
  Future<ApiResponse<PerformanceData>> load(String childId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ApiResponse.ok(_byChild[childId] ?? _byChild['c1']!);
  }

  static const _byChild = <String, PerformanceData>{
    'c1': PerformanceData(
      gpa: 3.8,
      classRank: 4,
      classSize: 32,
      termLabel: 'Term 2 — 2025/26',
      gpaTrend: [3.4, 3.5, 3.6, 3.8],
      subjects: [
        SubjectGrade(subject: 'Mathematics', grade: 'A', percent: 92, deltaPercent: 4),
        SubjectGrade(subject: 'Science', grade: 'A-', percent: 88, deltaPercent: 2),
        SubjectGrade(subject: 'English', grade: 'B+', percent: 84, deltaPercent: -1),
        SubjectGrade(subject: 'History', grade: 'A', percent: 91, deltaPercent: 6),
        SubjectGrade(subject: 'Art', grade: 'A+', percent: 96, deltaPercent: 0),
      ],
    ),
    'c2': PerformanceData(
      gpa: 3.4,
      classRank: 9,
      classSize: 28,
      termLabel: 'Term 2 — 2025/26',
      gpaTrend: [3.2, 3.1, 3.3, 3.4],
      subjects: [
        SubjectGrade(subject: 'Mathematics', grade: 'B', percent: 78, deltaPercent: -2),
        SubjectGrade(subject: 'Science', grade: 'B+', percent: 83, deltaPercent: 3),
        SubjectGrade(subject: 'English', grade: 'A-', percent: 87, deltaPercent: 5),
        SubjectGrade(subject: 'Reading', grade: 'A', percent: 90, deltaPercent: 1),
      ],
    ),
  };
}
