import 'dart:async';

import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../models/guardian.dart';

class GuardiansController extends GetxController {
  final HeadmasterRepository _repo;
  GuardiansController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final results = <Guardian>[].obs;
  final query = ''.obs;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  /// Total guardian count regardless of filters (shown in the "All Guardians"
  /// chip).
  int get total => 142;

  void onSearch(String v) {
    query.value = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), fetch);
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadGuardians(query: query.value);
    if (res.success && res.data != null) {
      results.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load guardians.';
    }
    loading.value = false;
  }

  void invite(String id) {
    Get.snackbar('Invite sent', 'Portal invite emailed to guardian $id.',
        snackPosition: SnackPosition.BOTTOM);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
