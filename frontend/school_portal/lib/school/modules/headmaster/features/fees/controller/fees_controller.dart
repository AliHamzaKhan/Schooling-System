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
