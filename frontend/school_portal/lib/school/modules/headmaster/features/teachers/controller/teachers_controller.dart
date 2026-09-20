import 'dart:async';

import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../widgets/filter_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/teacher.dart';

typedef TeachersLoader =
    Future<ApiResponse<List<Teacher>>> Function({String query});

class TeachersController extends GetxController {
  final TeachersLoader _loader;
  TeachersController({HeadmasterRepository? repo, TeachersLoader? loader})
    : _loader =
          loader ?? (repo ?? Get.find<HeadmasterRepository>()).loadTeachers;

  final loading = true.obs;
  final error = RxnString();
  final results = <Teacher>[].obs;
  final query = ''.obs;

  // Client-side filters applied over the loaded roster.
  final deptFilter = <String>{}.obs;
  final statusFilter = <String>{}.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  /// Distinct specializations present in the loaded roster (sorted), for the
  /// filter.
  List<String> get departmentOptions =>
      (results
          .map((t) => t.department)
          .where((d) => d.isNotEmpty)
          .toSet()
          .toList()
        ..sort());

  /// Roster after applying specialization/status filters.
  List<Teacher> get visibleTeachers => results.where((t) {
    final okDept = deptFilter.isEmpty || deptFilter.contains(t.department);
    final okStatus =
        statusFilter.isEmpty || statusFilter.contains(t.status.label);
    return okDept && okStatus;
  }).toList();

  int get activeFilterCount => deptFilter.length + statusFilter.length;

  /// Opens the filter sheet and applies the chosen department/status selections.
  Future<void> openFilter() async {
    final result = await showFilterSheet(
      title: 'Filter Teachers',
      sections: [
        if (departmentOptions.isNotEmpty)
          FilterSection(
            key: 'department',
            title: 'Specialization',
            options: departmentOptions,
            initial: deptFilter,
          ),
        FilterSection(
          key: 'status',
          title: 'Status',
          options: [for (final s in TeacherStatus.values) s.label],
          initial: statusFilter,
        ),
      ],
    );
    if (result != null) {
      deptFilter.assignAll(result['department'] ?? const {});
      statusFilter.assignAll(result['status'] ?? const {});
    }
  }

  void onSearch(String v) {
    query.value = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), fetch);
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    results.clear();
    final res = await _loader(query: query.value);
    if (res.success && res.data != null) {
      results.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load teachers.';
    }
    loading.value = false;
  }

  /// Opens the full-page teacher registration flow and refreshes the roster if
  /// the create succeeded.
  Future<void> addTeacherFlow() async {
    final ok = await Get.toNamed(HeadmasterRoutes.teacherRegistration);
    if (ok == true) await fetch();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
