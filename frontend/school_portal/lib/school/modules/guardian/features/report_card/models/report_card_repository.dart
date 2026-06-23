import 'package:shared/shared.dart';

import 'report_card_data.dart';

/// Bundled mock fixtures for the Report Card screen, keyed by child id. Used as
/// the internal data source while [GuardianRepository] runs in mock mode.
class ReportCardRepository {
  Future<ApiResponse<ReportCardData>> load(String childId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ApiResponse.ok(_byChild[childId] ?? _byChild['c1']!);
  }

  static const _byChild = <String, ReportCardData>{
    'c1': ReportCardData(
      termLabel: 'Term 1 Results',
      gpa: 3.8,
      subjects: [
        ReportSubject(
            subject: 'Mathematics',
            course: 'Advanced Algebra',
            grade: 'A',
            percent: 94),
        ReportSubject(
            subject: 'Science', course: 'Biology', grade: 'B+', percent: 88),
        ReportSubject(
            subject: 'History',
            course: 'World History',
            grade: 'A-',
            percent: 91),
      ],
      gpaTrend: [
        GpaTrendPoint(label: 'Q1', gpa: 3.4),
        GpaTrendPoint(label: 'Q2', gpa: 3.6),
        GpaTrendPoint(label: 'Q3', gpa: 3.8),
      ],
    ),
    'c2': ReportCardData(
      termLabel: 'Term 1 Results',
      gpa: 3.4,
      subjects: [
        ReportSubject(
            subject: 'English',
            course: 'Reading & Writing',
            grade: 'A-',
            percent: 90),
        ReportSubject(
            subject: 'Mathematics',
            course: 'Numbers & Shapes',
            grade: 'B',
            percent: 78),
        ReportSubject(
            subject: 'Science',
            course: 'Discovery',
            grade: 'B+',
            percent: 83),
      ],
      gpaTrend: [
        GpaTrendPoint(label: 'Q1', gpa: 3.1),
        GpaTrendPoint(label: 'Q2', gpa: 3.2),
        GpaTrendPoint(label: 'Q3', gpa: 3.4),
      ],
    ),
  };
}
