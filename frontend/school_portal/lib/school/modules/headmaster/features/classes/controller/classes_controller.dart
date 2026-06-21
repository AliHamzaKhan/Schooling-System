import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../models/classes_data.dart';

/// Drives the Class Directory: filter dropdown placeholder + data load.
class ClassesController extends GetxController {
  final HeadmasterRepository _repo;
  ClassesController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<ClassDirectoryData>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadClasses();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load classes.';
    }
    loading.value = false;
  }
}
