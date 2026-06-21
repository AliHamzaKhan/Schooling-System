import 'dart:async';

import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/message_thread.dart';

class CommunicationController extends GetxController {
  final TeacherRepository _repo;
  CommunicationController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  static const filters = ['All', 'Parents', 'Students', 'Staff'];

  final loading = true.obs;
  final threads = <MessageThread>[].obs;
  final query = ''.obs;
  final filterIndex = 0.obs;
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

  Future<void> fetch() async {
    loading.value = true;
    final res = await _repo.loadMessages(query: query.value, party: _partyFilter);
    if (res.success && res.data != null) threads.assignAll(res.data!);
    loading.value = false;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
