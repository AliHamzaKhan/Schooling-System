import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:school_portal/school/modules/teacher/data/teacher_repository.dart';
import 'package:school_portal/school/modules/teacher/features/leave/controller/leave_review_controller.dart';
import 'package:school_portal/school/widgets/leave_review.dart';
import 'package:shared/shared.dart';

class _FailingLeaveRepository extends TeacherRepository {
  @override
  Future<ApiResponse<List<LeaveReviewItem>>> loadLeaveReview() async =>
      ApiResponse.fail('Leave requests are unavailable.');
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<ApiService>(ApiService(store: DataStoreService()));
  });
  tearDown(Get.reset);

  test(
    'leave review reload clears stale requests before reporting failure',
    () async {
      final controller =
          TeacherLeaveReviewController(repo: _FailingLeaveRepository())
            ..items.add(
              const LeaveReviewItem(
                id: 'leave-1',
                startDate: '2026-09-25',
                endDate: '2026-09-25',
                status: 'pending',
              ),
            );

      await controller.load();

      expect(controller.items, isEmpty);
      expect(controller.error.value, 'Leave requests are unavailable.');
      expect(controller.loading.value, isFalse);
    },
  );
}
