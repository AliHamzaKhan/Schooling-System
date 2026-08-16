import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';

/// Headmaster: edit the public school info — about, achievements, and the
/// school uniform image.
class SchoolInfoEditController extends GetxController {
  final HeadmasterRepository _repo;
  SchoolInfoEditController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final saving = false.obs;
  final uploading = false.obs;

  /// About text. Its `TextEditingController` is owned by
  /// [SchoolInfoEditView]'s State and disposed with that screen.
  final about = ''.obs;
  final achievements = <Map<String, dynamic>>[].obs;
  final uniformImageUrl = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadSchoolInfo();
    if (res.success && res.data != null) {
      final d = res.data!;
      about.value = d['about'] as String? ?? '';
      achievements.assignAll(((d['achievements'] as List?) ?? const [])
          .cast<Map<String, dynamic>>());
      uniformImageUrl.value = d['uniform_image_url'] as String?;
    } else {
      error.value = res.error ?? 'Could not load school info.';
    }
    loading.value = false;
  }

  void addAchievement(String title, String? description, String? year) {
    achievements.add({
      'title': title,
      'description': (description ?? '').isEmpty ? null : description,
      'year': (year ?? '').isEmpty ? null : year,
    });
  }

  void removeAchievement(int index) {
    if (index >= 0 && index < achievements.length) achievements.removeAt(index);
  }

  Future<void> pickUniform() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    uploading.value = true;
    error.value = null;
    final res = await _repo.uploadImage(
      folder: 'uniform',
      bytes: file.bytes,
      filename: file.name,
      contentType: 'image/${(file.extension ?? 'jpg').toLowerCase()}',
    );
    uploading.value = false;
    if (res.success && (res.data ?? '').isNotEmpty) {
      uniformImageUrl.value = res.data;
    } else {
      error.value = res.error ?? 'Image upload failed.';
    }
  }

  /// Saves all fields. Returns true on success.
  Future<bool> save() async {
    saving.value = true;
    error.value = null;
    final res = await _repo.saveSchoolInfo(
      about: about.value.trim(),
      achievements: achievements.toList(),
      uniformImageUrl: uniformImageUrl.value,
    );
    saving.value = false;
    if (!res.success) {
      error.value = res.error ?? 'Could not save changes.';
      return false;
    }
    return true;
  }
}
