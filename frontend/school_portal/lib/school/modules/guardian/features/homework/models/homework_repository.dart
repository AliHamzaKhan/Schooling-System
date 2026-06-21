import 'package:shared/shared.dart';

import 'homework_data.dart';

class HomeworkRepository {
  Future<ApiResponse<HomeworkData>> load(String childId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ApiResponse.ok(_byChild[childId] ?? _byChild['c1']!);
  }

  static const _byChild = <String, HomeworkData>{
    'c1': HomeworkData(
      pending: 2,
      submitted: 1,
      items: [
        HomeworkItem(
            subject: 'Science',
            title: 'Chapter 3 worksheet',
            dueDate: 'Oct 18',
            status: HomeworkStatus.pending),
        HomeworkItem(
            subject: 'Mathematics',
            title: 'Fractions practice set',
            dueDate: 'Oct 19',
            status: HomeworkStatus.pending),
        HomeworkItem(
            subject: 'English',
            title: 'Book report — Chapter 1',
            dueDate: 'Oct 14',
            status: HomeworkStatus.submitted),
        HomeworkItem(
            subject: 'History',
            title: 'Timeline project',
            dueDate: 'Oct 10',
            status: HomeworkStatus.graded,
            grade: '9/10'),
      ],
    ),
    'c2': HomeworkData(
      pending: 1,
      submitted: 0,
      items: [
        HomeworkItem(
            subject: 'English',
            title: 'Reading log',
            dueDate: 'Oct 16',
            status: HomeworkStatus.pending),
        HomeworkItem(
            subject: 'Mathematics',
            title: 'Counting worksheet',
            dueDate: 'Oct 11',
            status: HomeworkStatus.overdue),
        HomeworkItem(
            subject: 'Science',
            title: 'Plant diagram',
            dueDate: 'Oct 8',
            status: HomeworkStatus.graded,
            grade: '8/10'),
      ],
    ),
  };
}
