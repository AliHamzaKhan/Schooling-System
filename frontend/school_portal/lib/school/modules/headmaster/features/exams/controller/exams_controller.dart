import 'package:get/get.dart';

import '../../../../../widgets/filter_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/exams_data.dart';

/// Drives Exams & Results: data load + search query state.
class HeadmasterExamsController extends GetxController {
  final HeadmasterRepository _repo;
  HeadmasterExamsController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<ExamsData>();
  final searchQuery = ''.obs;

  // Client-side filters applied over the exam schedule.
  final statusFilter = <String>{}.obs;
  final gradeFilter = <String>{}.obs;

  // True while a "Publish All" batch is in flight.
  final publishing = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void onSearch(String value) => searchQuery.value = value;

  /// Distinct grades present in the schedule (sorted), for the filter sheet.
  List<String> get gradeOptions => ((data.value?.schedule ?? const [])
          .map((e) => e.grade)
          .where((g) => g.isNotEmpty)
          .toSet()
          .toList()
        ..sort());

  int get activeFilterCount => statusFilter.length + gradeFilter.length;

  /// Exam schedule after applying status/grade filters.
  List<ExamScheduleItem> get visibleSchedule =>
      (data.value?.schedule ?? const <ExamScheduleItem>[]).where((e) {
        final okStatus =
            statusFilter.isEmpty || statusFilter.contains(e.status.label);
        final okGrade = gradeFilter.isEmpty || gradeFilter.contains(e.grade);
        return okStatus && okGrade;
      }).toList();

  /// Opens the filter sheet for the exam schedule and applies the selection.
  Future<void> openScheduleFilter() async {
    final result = await showFilterSheet(
      title: 'Filter Schedule',
      sections: [
        FilterSection(
          key: 'status',
          title: 'Status',
          options: [for (final s in ExamStatus.values) s.label],
          initial: statusFilter,
        ),
        if (gradeOptions.isNotEmpty)
          FilterSection(
            key: 'grade',
            title: 'Grade',
            options: gradeOptions,
            initial: gradeFilter,
          ),
      ],
    );
    if (result != null) {
      statusFilter.assignAll(result['status'] ?? const {});
      gradeFilter.assignAll(result['grade'] ?? const {});
    }
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadExams();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load exams.';
    }
    loading.value = false;
  }

  /// Publishes computed results for every completed exam in the schedule, then
  /// reloads. Exams that aren't yet completed have nothing to publish.
  Future<void> publishAll() async {
    final current = data.value;
    if (current == null) return;
    final completed = current.schedule
        .where((e) => e.status == ExamStatus.completed)
        .toList();
    if (completed.isEmpty) {
      Get.snackbar('Nothing to publish',
          'There are no completed exams awaiting results.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    publishing.value = true;
    var ok = 0;
    for (final exam in completed) {
      final res = await _repo.publishExamResults(exam.id);
      if (res.success) ok++;
    }
    publishing.value = false;
    Get.snackbar('Results published',
        'Published results for $ok of ${completed.length} exam(s).',
        snackPosition: SnackPosition.BOTTOM);
    await load();
  }
}
