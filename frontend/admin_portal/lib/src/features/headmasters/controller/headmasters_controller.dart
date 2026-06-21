import 'dart:async';

import 'package:get/get.dart';

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

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
