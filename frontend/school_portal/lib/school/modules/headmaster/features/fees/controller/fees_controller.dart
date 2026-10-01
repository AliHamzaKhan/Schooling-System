import 'package:get/get.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../data/headmaster_repository.dart';
import '../models/fees_data.dart';

/// Drives the Fee Management dashboard.
class FeesController extends GetxController {
  final HeadmasterRepository _repo;
  FeesController({HeadmasterRepository? repo})
    : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<FeesData>();
  final agingAsOf = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load({DateTime? asOf}) async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadFees(agingAsOf: asOf ?? agingAsOf.value);
    if (res.success && res.data != null) {
      data.value = res.data;
      agingAsOf.value = res.data!.agingAsOfDate ?? asOf ?? agingAsOf.value;
    } else {
      error.value = res.error ?? 'Could not load fees.';
    }
    loading.value = false;
  }

  /// Reload the read-only aging report at a selected calendar date.
  Future<void> setAgingAsOf(DateTime value) =>
      load(asOf: DateTime(value.year, value.month, value.day));

  /// Notifies the guardians of one overdue student (in-app/push broadcast).
  Future<void> remind(OverduePayment payment) async {
    final studentId = payment.studentId;
    if (studentId == null) {
      Get.snackbar(
        'Reminder not sent',
        'This invoice has no student record.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final res = await _repo.createBroadcast(
      title: 'Fee reminder',
      body:
          'A fee of ${payment.amountLabel} for ${payment.studentName} is '
          'overdue. Please contact the school office.',
      audienceType: 'student_guardians',
      audienceRef: studentId,
    );
    Get.snackbar(
      res.success ? 'Reminder sent' : 'Reminder not sent',
      res.success
          ? 'The guardians of ${payment.studentName} were notified.'
          : (res.error ?? 'Please try again.'),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Notifies the guardians of every student with outstanding fees.
  Future<void> remindAll() async {
    final res = await _repo.sendFeeReminders();
    Get.snackbar(
      res.success ? 'Reminders sent' : 'Reminders not sent',
      res.success
          ? (res.data == 0
                ? 'No student has outstanding fees.'
                : 'Guardians of ${res.data} student(s) were notified.')
          : (res.error ?? 'Please try again.'),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Open the dedicated Record Payment page (student search + mark-paid);
  /// refreshes the finance dashboard when the screen closes.
  Future<void> recordPaymentFlow() async {
    await Get.toNamed(HeadmasterRoutes.recordPayment);
    await load();
  }
}
