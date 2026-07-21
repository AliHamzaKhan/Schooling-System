import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../../classes/models/my_class.dart';
import '../models/section_performance.dart';

/// Drives the Performance tab: one tab per section the teacher takes, each
/// showing that section's students ranked best-first.
///
/// Rosters are fetched lazily per section and cached, so switching between
/// tabs after the first visit is instant and doesn't re-hit the API.
class ClassPerformanceController extends GetxController {
  final TeacherRepository _repo;
  ClassPerformanceController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  /// Loading the tab list itself (the teacher's sections).
  final loadingSections = true.obs;
  final sectionsError = RxnString();
  final sections = <MyClass>[].obs;

  /// Section id currently shown.
  final selectedSectionId = RxnString();

  /// Per-section roster cache and in-flight/error state, keyed by section id.
  final rosters = <String, SectionPerformance>{}.obs;
  final loadingRoster = <String>{}.obs;
  final rosterErrors = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadSections();
  }

  SectionPerformance? get current {
    final id = selectedSectionId.value;
    return id == null ? null : rosters[id];
  }

  bool get isCurrentLoading {
    final id = selectedSectionId.value;
    return id != null && loadingRoster.contains(id);
  }

  String? get currentError {
    final id = selectedSectionId.value;
    return id == null ? null : rosterErrors[id];
  }

  Future<void> loadSections() async {
    loadingSections.value = true;
    sectionsError.value = null;
    final res = await _repo.loadMyTimetable();
    if (res.success) {
      final mine = MyClass.fromSlots(res.data ?? const []);
      sections.assignAll(mine);
      if (mine.isNotEmpty) {
        selectedSectionId.value = mine.first.sectionId;
        await loadRoster(mine.first.sectionId);
      }
    } else {
      sectionsError.value = res.error ?? 'Could not load your classes.';
    }
    loadingSections.value = false;
  }

  /// Selects a tab, fetching its roster the first time it's opened.
  Future<void> selectSection(String sectionId) async {
    if (selectedSectionId.value == sectionId) return;
    selectedSectionId.value = sectionId;
    if (!rosters.containsKey(sectionId)) await loadRoster(sectionId);
  }

  Future<void> loadRoster(String sectionId, {bool force = false}) async {
    if (loadingRoster.contains(sectionId)) return;
    if (!force && rosters.containsKey(sectionId)) return;
    loadingRoster.add(sectionId);
    rosterErrors.remove(sectionId);
    final res = await _repo.loadSectionPerformance(sectionId);
    if (res.success && res.data != null) {
      rosters[sectionId] = res.data!;
    } else {
      rosterErrors[sectionId] = res.error ?? 'Could not load this roster.';
    }
    loadingRoster.remove(sectionId);
  }

  /// Pull-to-refresh always re-fetches, bypassing the cache.
  Future<void> refreshCurrent() async {
    final id = selectedSectionId.value;
    if (id != null) await loadRoster(id, force: true);
  }
}
