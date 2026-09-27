import 'dart:async';

import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/message_thread.dart';

class CommunicationController extends GetxController {
  final TeacherRepository _repo;
  CommunicationController({TeacherRepository? repo})
    : _repo = repo ?? Get.find<TeacherRepository>();

  static const filters = ['All', 'Parents', 'Students', 'Staff'];

  /// Threads revealed per page as the user scrolls.
  static const pageSize = 20;

  /// True only until the first result arrives. Filter and search changes set
  /// [listLoading] instead, so the header and search field stay mounted and
  /// the screen never flashes back to a full-page spinner.
  final loading = true.obs;

  /// The list area alone is busy — drives the shimmer.
  final listLoading = false.obs;
  final loadingMore = false.obs;
  final error = RxnString();

  final threads = <MessageThread>[].obs;
  final query = ''.obs;
  final filterIndex = 0.obs;

  /// How many of [threads] are currently rendered.
  final visibleCount = pageSize.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  ThreadParty? get _partyFilter => switch (filterIndex.value) {
    1 => ThreadParty.parent,
    2 => ThreadParty.student,
    3 => ThreadParty.staff,
    _ => null,
  };

  String get filterLabel => filters[filterIndex.value];

  /// 0 when showing everything, so the filter button only badges when a
  /// narrowing filter is actually applied.
  int get activeFilterCount => filterIndex.value == 0 ? 0 : 1;

  List<MessageThread> get visible =>
      threads.take(visibleCount.value).toList(growable: false);

  bool get hasMore => visibleCount.value < threads.length;

  void onSearch(String v) {
    query.value = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), fetch);
  }

  void selectFilter(int i) {
    if (filterIndex.value == i) return;
    filterIndex.value = i;
    fetch();
  }

  Future<void> loadMore() async {
    if (loadingMore.value || !hasMore) return;
    loadingMore.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    visibleCount.value = (visibleCount.value + pageSize).clamp(
      0,
      threads.length,
    );
    loadingMore.value = false;
  }

  Future<void> fetch() async {
    // First load owns the whole screen; every later fetch only busies the list.
    if (threads.isEmpty && loading.value) {
      loading.value = true;
    } else {
      listLoading.value = true;
    }
    error.value = null;
    threads.clear();
    visibleCount.value = pageSize;
    final res = await _repo.loadMessages(
      query: query.value,
      party: _partyFilter,
    );
    if (res.success && res.data != null) {
      threads.assignAll(res.data!);
      // A new result set starts from page one again.
      visibleCount.value = pageSize;
    } else {
      error.value = res.error ?? 'Could not load conversations.';
    }
    loading.value = false;
    listLoading.value = false;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
