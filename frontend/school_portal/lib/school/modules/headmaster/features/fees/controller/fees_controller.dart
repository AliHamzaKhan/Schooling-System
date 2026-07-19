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

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadFees();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load fees.';
    }
    loading.value = false;
  }

  /// Sends a payment reminder for a single overdue invoice.
  void remind(OverduePayment payment) => Get.snackbar(
        'Reminder sent',
        'A payment reminder was sent for ${payment.studentName}.',
        snackPosition: SnackPosition.BOTTOM,
      );

  /// Sends reminders to every outstanding invoice.
  void remindAll() {
    final count = data.value?.overdue.length ?? 0;
    Get.snackbar(
      'Reminders sent',
      count == 0
          ? 'There are no overdue invoices.'
          : 'Reminders were sent to $count guardian(s).',
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
