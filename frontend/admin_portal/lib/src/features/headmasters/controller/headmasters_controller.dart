import 'dart:async';

import 'package:get/get.dart';

import '../../schools/models/school.dart';
import '../models/headmaster.dart';
import '../models/headmasters_repository.dart';

/// Drives Headmaster Management: search, status filter, and client pagination.
class HeadmastersController extends GetxController {
  final HeadmastersRepository _repo;
  HeadmastersController({HeadmastersRepository? repo})
      : _repo = repo ?? HeadmastersRepository();

  static const filters = ['All Status', 'Active', 'Pending Review'];

  final loading = true.obs;
  final error = RxnString();
  final _allResults = <Headmaster>[].obs;
  final query = ''.obs;
  final filterIndex = 0.obs;
  final page = 1.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  HeadmasterStatus? get _statusFilter => switch (filterIndex.value) {
        1 => HeadmasterStatus.active,
        2 => HeadmasterStatus.pendingSetup,
        _ => null,
      };

  int get totalPages =>
      (_allResults.length / HeadmastersRepository.pageSize).ceil().clamp(1, 999);

  /// The current page's slice.
  List<Headmaster> get pageItems {
    final start = (page.value - 1) * HeadmastersRepository.pageSize;
    return _allResults.skip(start).take(HeadmastersRepository.pageSize).toList();
  }

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

  void goToPage(int p) => page.value = p.clamp(1, totalPages);
  void prevPage() => goToPage(page.value - 1);
  void nextPage() => goToPage(page.value + 1);

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.fetch(query: query.value, status: _statusFilter);
    if (res.success && res.data != null) {
      _allResults.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load headmasters.';
    }
    loading.value = false;
  }

  // ── Create headmaster ───────────────────────────────────────
  final schools = <School>[].obs;
  final loadingSchools = false.obs;
  final submitting = false.obs;
  final submitError = RxnString();

  /// Lazily loads the school list for the create-headmaster picker.
  Future<void> loadSchools() async {
    if (schools.isNotEmpty || loadingSchools.value) return;
    loadingSchools.value = true;
    final res = await _repo.loadSchools();
    if (res.success && res.data != null) schools.assignAll(res.data!);
    loadingSchools.value = false;
  }

  /// Creates a headmaster for [schoolId]; returns true on success and refreshes
  /// the list. Errors surface via [submitError].
  Future<bool> createHeadmaster({
    required String schoolId,
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    submitError.value = null;
    submitting.value = true;
    final res = await _repo.create(schoolId, {
      'full_name': fullName,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    submitting.value = false;
    if (res.success) {
      await fetch();
      return true;
    }
    submitError.value = res.error ?? 'Could not create headmaster.';
    return false;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
