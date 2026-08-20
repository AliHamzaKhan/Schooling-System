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

  // ── Create headmaster + server-side school picker ───────────
  final submitting = false.obs;
  final submitError = RxnString();

  /// Server-side school search + pagination for the create-headmaster picker.
  /// Only one page is ever held in memory, so a directory of thousands never
  /// loads whole. Typing runs the search after [_minSearchChars] characters with
  /// a [_searchDebounce] delay (or immediately via [searchSchoolsNow]).
  static const schoolPageSize = HeadmastersRepository.schoolPageSize;
  static const _minSearchChars = 3;
  static const _searchDebounce = Duration(seconds: 3);

  /// The current page of schools (server-filtered).
  final schoolResults = <School>[].obs;
  final loadingSchools = false.obs;
  final schoolQuery = ''.obs;
  final schoolPickerPage = 1.obs;

  /// True when the last page came back full, i.e. another page likely exists.
  final schoolHasMore = false.obs;
  Timer? _schoolDebounce;

  /// Loads the current [schoolPickerPage] for the active [schoolQuery] from the
  /// API. `hasMore` is inferred from a full page (the list endpoint returns rows
  /// only, no total count).
  Future<void> loadSchoolPage() async {
    loadingSchools.value = true;
    final res = await _repo.searchSchools(
      query: schoolQuery.value.trim(),
      limit: schoolPageSize,
      offset: (schoolPickerPage.value - 1) * schoolPageSize,
    );
    if (res.success && res.data != null) {
      schoolResults.assignAll(res.data!);
      schoolHasMore.value = res.data!.length == schoolPageSize;
    } else {
      schoolResults.clear();
      schoolHasMore.value = false;
    }
    loadingSchools.value = false;
  }

  /// Debounced search-as-you-type. Blank clears back to the first page of the
  /// unfiltered list immediately; 1–2 characters wait (too short to search);
  /// 3+ characters trigger the API after [_searchDebounce].
  void onSchoolSearch(String value) {
    schoolQuery.value = value;
    _schoolDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      schoolPickerPage.value = 1;
      loadSchoolPage();
      return;
    }
    if (trimmed.length < _minSearchChars) return;
    _schoolDebounce = Timer(_searchDebounce, () {
      schoolPickerPage.value = 1;
      loadSchoolPage();
    });
  }

  /// Runs the search immediately (the search button / submit affordance),
  /// bypassing the debounce. Ignored for 1–2 character queries.
  void searchSchoolsNow() {
    _schoolDebounce?.cancel();
    final trimmed = schoolQuery.value.trim();
    if (trimmed.isNotEmpty && trimmed.length < _minSearchChars) return;
    schoolPickerPage.value = 1;
    loadSchoolPage();
  }

  void schoolPickerPrev() {
    if (schoolPickerPage.value <= 1) return;
    schoolPickerPage.value -= 1;
    loadSchoolPage();
  }

  void schoolPickerNext() {
    if (!schoolHasMore.value) return;
    schoolPickerPage.value += 1;
    loadSchoolPage();
  }

  /// Resets and loads the first page (called when the create screen opens).
  void resetSchoolPicker() {
    _schoolDebounce?.cancel();
    schoolQuery.value = '';
    schoolPickerPage.value = 1;
    schoolHasMore.value = false;
    submitError.value = null;
    loadSchoolPage();
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

  /// Updates a headmaster's name/phone; returns true on success + refreshes.
  Future<bool> updateHeadmaster({
    required Headmaster headmaster,
    required String fullName,
    String? phone,
  }) async {
    if (headmaster.schoolId == null) {
      submitError.value = 'This headmaster has no school assigned.';
      return false;
    }
    submitError.value = null;
    submitting.value = true;
    final res = await _repo.update(headmaster.schoolId!, headmaster.id, {
      'full_name': fullName,
      'phone': (phone == null || phone.isEmpty) ? null : phone,
    });
    submitting.value = false;
    if (res.success) {
      await fetch();
      return true;
    }
    submitError.value = res.error ?? 'Could not update headmaster.';
    return false;
  }

  /// Soft-deletes (deactivates) a headmaster; returns true on success.
  Future<bool> deleteHeadmaster(Headmaster headmaster) async {
    if (headmaster.schoolId == null) return false;
    final res = await _repo.remove(headmaster.schoolId!, headmaster.id);
    if (res.success) {
      await fetch();
      return true;
    }
    Get.snackbar('Error', res.error ?? 'Could not remove headmaster.',
        snackPosition: SnackPosition.BOTTOM);
    return false;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _schoolDebounce?.cancel();
    super.onClose();
  }
}
