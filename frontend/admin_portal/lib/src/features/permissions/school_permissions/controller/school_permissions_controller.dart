import 'package:get/get.dart';

import '../../../schools/models/school.dart';
import '../../../schools/models/schools_repository.dart';

/// Drives the "Select School to Configure" list — loads the real schools whose
/// module permissions can be edited, with client-side search.
class SchoolPermissionsController extends GetxController {
  final SchoolsRepository _repo;
  SchoolPermissionsController({SchoolsRepository? repo})
      : _repo = repo ?? SchoolsRepository();

  final loading = true.obs;
  final error = RxnString();
  final query = ''.obs;

  final _all = <School>[];
  final results = <School>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    // The list endpoint pages at 8, so walk page-by-page until every school is
    // gathered — configuration must be reachable for all of them.
    final all = <School>[];
    var page = 1;
    while (true) {
      final res = await _repo.fetch(page: page);
      if (!res.success || res.data == null) {
        error.value = res.error ?? 'Could not load schools.';
        break;
      }
      all.addAll(res.data!.schools);
      if (page >= res.data!.totalPages) break;
      page++;
    }
    _all
      ..clear()
      ..addAll(all);
    _applyFilter();
    loading.value = false;
  }

  void onSearch(String value) {
    query.value = value;
    _applyFilter();
  }

  void _applyFilter() {
    final q = query.value.toLowerCase();
    results.assignAll(
      _all.where((s) =>
          q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.code.toLowerCase().contains(q) ||
          s.id.toLowerCase().contains(q)),
    );
  }
}
