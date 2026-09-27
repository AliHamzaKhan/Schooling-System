import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:school_portal/school/modules/teacher/data/teacher_repository.dart';
import 'package:school_portal/school/modules/teacher/features/communication/controller/communication_controller.dart';
import 'package:school_portal/school/modules/teacher/features/communication/models/message_thread.dart';
import 'package:shared/shared.dart';

class _FailingTeacherRepository extends TeacherRepository {
  @override
  Future<ApiResponse<List<MessageThread>>> loadMessages({
    String query = '',
    ThreadParty? party,
  }) async => ApiResponse.fail('Conversations could not be refreshed.');
}

void main() {
  setUpAll(() {
    Get.testMode = true;
    Get.put<ApiService>(ApiService(store: DataStoreService()));
  });

  test(
    'conversation load failure clears stale threads and exposes retry state',
    () async {
      final controller = CommunicationController(
        repo: _FailingTeacherRepository(),
      );
      controller.threads.add(
        const MessageThread(
          id: 'thread-1',
          senderName: 'Ayesha Khan',
          preview: 'Old message',
          time: '09:00',
          party: ThreadParty.parent,
        ),
      );

      await controller.fetch();

      expect(controller.loading.value, isFalse);
      expect(controller.listLoading.value, isFalse);
      expect(controller.threads, isEmpty);
      expect(controller.error.value, 'Conversations could not be refreshed.');
    },
  );
}
