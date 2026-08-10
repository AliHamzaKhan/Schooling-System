import 'dart:async';

import 'package:get/get.dart';

import '../models/school.dart';
import '../models/schools_repository.dart';

/// Drives the School Management list: search, status filter, and pagination.
class SchoolsController extends GetxController {
  final SchoolsRepository _repo;
  SchoolsController({SchoolsRepository? repo})
      : _repo = repo ?? SchoolsRepository();

  /// Filter chip options; index 0 = "All".
  static const filters = ['All', 'Active', 'Pending'];

  final loading = true.obs;
  final error = RxnString();
  final schools = <School>[].obs;
  final query = ''.obs;
  final filterIndex = 0.obs;
  final page = 1.obs;
  final totalPages = 1.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  SchoolStatus? get _statusFilter => switch (filterIndex.value) {
        1 => SchoolStatus.active,
        2 => SchoolStatus.pending,
        _ => null,
      };

  void onSearch(String value) {
    query.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      page.value = 1;
      fetch();
    });
  }

  void selectFilter(int index) {
    if (filterIndex.value == index) return;
    filterIndex.value = index;
    page.value = 1;
    fetch();
  }

  void goToPage(int p) {
    if (p == page.value) return;
    page.value = p;
    fetch();
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.fetch(
      page: page.value,
      query: query.value,
      status: _statusFilter,
    );
    if (res.success && res.data != null) {
      schools.assignAll(res.data!.schools);
      totalPages.value = res.data!.totalPages;
    } else {
      error.value = res.error ?? 'Could not load schools.';
    }
    loading.value = false;
  }

  /// "Delete" a school = deactivate it (the backend has no hard delete; this
  /// sets status to `suspended`), then refresh.
  Future<bool> deleteSchool(String id) async {
    final res = await _repo.setStatus(id, 'suspended');
    if (res.success) {
      await fetch();
      return true;
    }
    Get.snackbar('Error', res.error ?? 'Could not delete the school.',
        snackPosition: SnackPosition.BOTTOM);
    return false;
  }

  /// Reactivates a suspended school (status → `active`), then refresh.
  Future<bool> activateSchool(String id) async {
    final res = await _repo.setStatus(id, 'active');
    if (res.success) {
      await fetch();
      return true;
    }
    Get.snackbar('Error', res.error ?? 'Could not activate the school.',
        snackPosition: SnackPosition.BOTTOM);
    return false;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
