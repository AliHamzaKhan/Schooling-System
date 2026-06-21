import 'dart:async';

import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../models/teacher.dart';

class TeachersController extends GetxController {
  final HeadmasterRepository _repo;
  TeachersController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final results = <Teacher>[].obs;
  final query = ''.obs;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  void onSearch(String v) {
    query.value = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), fetch);
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadTeachers(query: query.value);
    if (res.success && res.data != null) {
      results.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load teachers.';
    }
    loading.value = false;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
