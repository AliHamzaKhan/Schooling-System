import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:school_portal/school/modules/guardian/data/guardian_repository.dart';
import 'package:school_portal/school/modules/guardian/shared/controller/child_scoped_controller.dart';
import 'package:school_portal/school/modules/guardian/shared/controller/guardian_session_controller.dart';
import 'package:school_portal/school/modules/guardian/shared/models/child.dart';
import 'package:shared/shared.dart';

class _UnusedGuardianRepository extends GuardianRepository {}

class _FailingChildrenRepository extends GuardianRepository {
  @override
  Future<ApiResponse<List<Child>>> loadChildren() async =>
      ApiResponse.fail('Linked children could not be refreshed.');
}

class _FailingChildController extends ChildScopedController<String> {
  _FailingChildController({required super.session});

  @override
  Future<String?> fetch(String childId) async => null;
}

void main() {
  setUpAll(() {
    Get.testMode = true;
    Get.put<ApiService>(ApiService(store: DataStoreService()));
  });

  test(
    'child-scoped failure clears stale child data and exposes retry state',
    () async {
      final session = GuardianSessionController(
        repo: _UnusedGuardianRepository(),
      );
      session.selectedId.value = 'child-1';
      final controller = _FailingChildController(session: session);
      controller.data.value = 'stale data';

      await controller.reload();

      expect(controller.loading.value, isFalse);
      expect(controller.data.value, isNull);
      expect(
        controller.error.value,
        'Could not load this child’s latest information.',
      );
    },
  );

  test('guardian refresh failure clears a previously selected child', () async {
    final session = GuardianSessionController(
      repo: _FailingChildrenRepository(),
    );
    session.children.assignAll(const [
      Child(
        id: 'child-1',
        name: 'Ayesha Khan',
        grade: 'Grade 6',
        attendancePercent: 90,
        gpa: 3.5,
        pendingHomework: 0,
        feesDue: false,
      ),
    ]);
    session.selectedId.value = 'child-1';

    await session.load();

    expect(session.loading.value, isFalse);
    expect(session.children, isEmpty);
    expect(session.selectedId.value, isNull);
    expect(session.error.value, 'Linked children could not be refreshed.');
  });
}
