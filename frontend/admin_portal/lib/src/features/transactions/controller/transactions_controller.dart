import 'package:get/get.dart';

import '../../../data/admin_api_service.dart';
import '../../../data/models/admin_metrics.dart';

/// Drives the "View All" transactions screen: a range filter (this month /
/// this year / all time), the bucketed chart series, and the full listing.
class TransactionsController extends GetxController {
  TransactionsController({AdminApiService? api})
      : _api = api ?? AdminApiService();

  final AdminApiService _api;

  /// Active range: 'month' | 'year' | 'all'.
  final range = 'month'.obs;
  final loading = true.obs;
  final error = RxnString();
  final report = Rxn<TransactionsReport>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _api.fetchTransactions(range: range.value);
    if (res.success && res.data != null) {
      report.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load transactions.';
    }
    loading.value = false;
  }

  /// Switch range and reload (no-op if already selected).
  Future<void> selectRange(String value) async {
    if (value == range.value) return;
    range.value = value;
    await load();
  }
}
