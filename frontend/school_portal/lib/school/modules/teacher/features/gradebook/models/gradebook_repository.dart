import 'package:shared/shared.dart';

import 'gradebook_data.dart';

class GradebookRepository {
  Future<ApiResponse<Gradebook>> load(String? examId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  static const _mock = Gradebook(
    examTitle: 'Midterm Calculus Exam',
    breadcrumb: 'Gradebook > Grade 10 Advanced Math',
    totalMarks: 100,
    totalStudents: 28,
    students: [
      GradebookStudent(id: 'STU-001', name: 'Alice Liddell', accent: AppColors.aiAccent),
      GradebookStudent(id: 'STU-002', name: 'Bob Marley', accent: AppColors.tertiary),
      GradebookStudent(id: 'STU-003', name: 'Charlie Chaplin', accent: AppColors.error),
      GradebookStudent(id: 'STU-004', name: 'Diana Prince', accent: AppColors.primary),
    ],
  );
}
