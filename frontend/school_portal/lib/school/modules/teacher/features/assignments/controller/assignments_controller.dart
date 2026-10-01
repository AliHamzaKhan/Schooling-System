import 'dart:async';

import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/assignment.dart';

class TeacherAssignmentsController extends GetxController {
  final TeacherRepository _repo;
  TeacherAssignmentsController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  static const allClasses = 'All Classes';

  /// "All Classes" plus the classes that actually have assignments.
  final classOptions = <String>[allClasses].obs;

  /// Rows revealed per page as the user scrolls.
  static const pageSize = 8;

  /// Only true for the very first load. Re-fetches triggered by a filter or a
  /// search keep the list on screen — swapping the whole body for a spinner is
  /// what used to throw the scroll position back to the top.
  final loading = true.obs;
  final refreshing = false.obs;
  final loadingMore = false.obs;

  final error = RxnString();
  final data = Rxn<AssignmentsData>();
  final query = ''.obs;
  final classFilterIndex = 0.obs;

  /// How many of the matched assignments are currently rendered.
  final visibleCount = pageSize.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  /// Every assignment matching the current filter + search.
  List<Assignment> get matches => data.value?.assignments ?? const [];

  /// The slice actually rendered — grows as the user scrolls.
  List<Assignment> get visible =>
      matches.take(visibleCount.value).toList(growable: false);

  bool get hasMore => visibleCount.value < matches.length;

  void onSearch(String v) {
    query.value = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), fetch);
  }

  void selectClass(int i) {
    if (i == classFilterIndex.value) return;
    classFilterIndex.value = i;
    fetch();
  }

  bool _matchesClass(Assignment a) {
    final i = classFilterIndex.value;
    if (i <= 0 || i >= classOptions.length) return true;
    return a.className == classOptions[i];
  }

  /// Reveals the next page. Async so the footer can show a brief spinner
  /// instead of the list snapping longer with no feedback.
  Future<void> loadMore() async {
    if (loadingMore.value || !hasMore) return;
    loadingMore.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    visibleCount.value =
        (visibleCount.value + pageSize).clamp(0, matches.length);
    loadingMore.value = false;
  }

  Future<void> fetch() async {
    // Keep the previous list visible while re-fetching so scroll offset and
    // the filter row stay put.
    if (data.value == null) {
      loading.value = true;
    } else {
      refreshing.value = true;
    }
    error.value = null;
    final res = await _repo.loadAssignments();
    if (res.success && res.data != null) {
      final q = query.value.toLowerCase();
      final base = res.data!;
      final selected = classFilterIndex.value < classOptions.length
          ? classOptions[classFilterIndex.value]
          : allClasses;
      classOptions.assignAll([
        allClasses,
        ...({for (final a in base.assignments) a.className}
              ..removeWhere((c) => c.isEmpty))
            .toList()
          ..sort(),
      ]);
      classFilterIndex.value = classOptions.indexOf(selected).clamp(0, classOptions.length - 1);
      data.value = AssignmentsData(
        stats: base.stats,
        assignments: base.assignments
            .where(_matchesClass)
            .where((a) => q.isEmpty || a.title.toLowerCase().contains(q))
            .toList(),
      );
      // A new result set starts from page one again.
      visibleCount.value = pageSize;
    } else {
      error.value = res.error ?? 'Could not load assignments.';
    }
    loading.value = false;
    refreshing.value = false;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
