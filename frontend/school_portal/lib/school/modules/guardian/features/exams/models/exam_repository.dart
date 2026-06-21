import 'package:shared/shared.dart';

import 'exam_data.dart';

class ExamRepository {
  Future<ApiResponse<ExamData>> load(String childId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ApiResponse.ok(_byChild[childId] ?? _byChild['c1']!);
  }

  static const _byChild = <String, ExamData>{
    'c1': ExamData(
      termLabel: 'Term 2 Mid-terms',
      upcoming: [
        ExamEntry(
            subject: 'Mathematics',
            date: 'Oct 24',
            time: '09:00 AM',
            room: 'Hall A',
            syllabus: 'Units 1–4'),
        ExamEntry(
            subject: 'Science',
            date: 'Oct 26',
            time: '11:00 AM',
            room: 'Lab 2',
            syllabus: 'Chapters 1–3'),
      ],
      results: [
        ExamEntry(
            subject: 'English',
            date: 'Sep 20',
            time: '09:00 AM',
            room: 'Hall A',
            result: 'A- — 88%'),
      ],
    ),
    'c2': ExamData(
      termLabel: 'Term 2 Unit Tests',
      upcoming: [
        ExamEntry(
            subject: 'English',
            date: 'Oct 25',
            time: '10:00 AM',
            room: 'Room 5',
            syllabus: 'Reading & spelling'),
      ],
      results: [
        ExamEntry(
            subject: 'Mathematics',
            date: 'Sep 18',
            time: '10:00 AM',
            room: 'Room 5',
            result: 'B — 78%'),
        ExamEntry(
            subject: 'Science',
            date: 'Sep 22',
            time: '11:00 AM',
            room: 'Room 5',
            result: 'B+ — 83%'),
      ],
    ),
  };
}
