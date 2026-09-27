import 'package:get/get.dart';

import '../../../../../widgets/filter_sheet.dart';
import '../../../data/student_repository.dart';
import '../models/assignment.dart';

class StudentAssignmentsController extends GetxController {
  final StudentRepository _repo;
  StudentAssignmentsController({StudentRepository? repo})
    : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final data = Rxn<AssignmentsData>();
  final error = RxnString();

  // Client-side filters applied over the active assignments list.
  final subjectFilter = <String>{}.obs;
  final statusFilter = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    data.value = null;
    final res = await _repo.loadAssignments();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load assignments.';
    }
    loading.value = false;
  }

  /// Distinct subjects present in the loaded assignments (sorted), for filtering.
  List<String> get subjectOptions =>
      ((data.value?.assignments ?? const [])
          .map((a) => a.subject)
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort());

  int get activeFilterCount => subjectFilter.length + statusFilter.length;

  /// Assignments after applying subject/status filters.
  List<StudentAssignment> get visibleAssignments =>
      (data.value?.assignments ?? const <StudentAssignment>[]).where((a) {
        final okSubject =
            subjectFilter.isEmpty || subjectFilter.contains(a.subject);
        final okStatus =
            statusFilter.isEmpty || statusFilter.contains(a.status.label);
        return okSubject && okStatus;
      }).toList();

  /// Opens the filter sheet and applies the chosen subject/status selections.
  Future<void> openFilter() async {
    final result = await showFilterSheet(
      title: 'Filter Assignments',
      sections: [
        if (subjectOptions.isNotEmpty)
          FilterSection(
            key: 'subject',
            title: 'Subject',
            options: subjectOptions,
            initial: subjectFilter,
          ),
        FilterSection(
          key: 'status',
          title: 'Status',
          options: [for (final s in StudentAssignmentStatus.values) s.label],
          initial: statusFilter,
        ),
      ],
    );
    if (result != null) {
      subjectFilter.assignAll(result['subject'] ?? const {});
      statusFilter.assignAll(result['status'] ?? const {});
    }
  }
}
