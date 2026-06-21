import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../models/timetable_data.dart';

class TimetableController extends GetxController {
  final HeadmasterRepository _repo;
  TimetableController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  static const classOptions = ['All Classes', 'Class 8A', 'Class 8B', 'Class 9A'];
  static const teacherOptions = [
    'All Teachers', 'Mr. Anderson', 'Ms. Davis', 'Dr. Smith', 'Mr. Jones',
  ];

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<TimetableData>();
  final classFilter = 'All Classes'.obs;
  final teacherFilter = 'All Teachers'.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void selectClass(String? v) {
    if (v == null || v == classFilter.value) return;
    classFilter.value = v;
  }

  void selectTeacher(String? v) {
    if (v == null || v == teacherFilter.value) return;
    teacherFilter.value = v;
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadTimetable();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load timetable.';
    }
    loading.value = false;
  }
}
