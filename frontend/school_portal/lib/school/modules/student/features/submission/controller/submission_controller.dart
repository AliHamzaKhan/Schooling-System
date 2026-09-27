import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../../assignments/models/assignment.dart';

class SubmissionController extends GetxController {
  final StudentRepository _repo;
  SubmissionController({StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final assignment = Rxn<StudentAssignment>();
  /// Notes text. The `TextEditingController` behind it is owned by the submit
  /// form's State, so it is disposed with that screen.
  final notes = ''.obs;
  final filename = RxnString();
  final fileSize = Rxn<int>();
  final submitting = false.obs;
  final error = RxnString();

  /// When the assignment is already submitted the screen shows a read-only
  /// status view. The student can opt into replacing their submission (allowed
  /// by the backend until it's graded), which flips this on to reveal the form.
  final resubmit = false.obs;

  void startResubmit() {
    error.value = null;
    resubmit.value = true;
  }

  void cancelResubmit() {
    clearFile();
    resubmit.value = false;
  }

  /// Whether the submit form should be shown instead of the status view.
  bool get showForm => !(assignment.value?.isSubmitted ?? false) || resubmit.value;

  // Bytes of the picked file, uploaded to storage on submit.
  List<int>? _pickedBytes;

  @override
  void onInit() {
    super.onInit();
    // Preferred path: the assignment object is passed straight from the list, so
    // the detail is the real (live) assignment. A bare id string is still
    // accepted as a fallback.
    final arg = Get.arguments;
    if (arg is StudentAssignment) {
      assignment.value = arg;
      loading.value = false;
    } else {
      load(arg is String ? arg : (Get.parameters['assignment_id'] ?? ''));
    }
  }

  /// Opens the OS / browser file picker (PDF only) and records the chosen file.
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    filename.value = file.name;
    fileSize.value = file.size;
    _pickedBytes = file.bytes;
  }

  void clearFile() {
    filename.value = null;
    fileSize.value = null;
    _pickedBytes = null;
  }

  Future<void> submit() async {
    final id = assignment.value?.id ?? '';
    if (id.isEmpty) {
      error.value = "This assignment can't be submitted.";
      return;
    }
    submitting.value = true;
    error.value = null;

    // Upload the picked file first (if any) to get its stored URL.
    String? attachmentUrl;
    final bytes = _pickedBytes;
    final name = filename.value;
    if (bytes != null && name != null) {
      final upload = await _repo.uploadFile(bytes: bytes, filename: name);
      if (!upload.success || (upload.data ?? '').isEmpty) {
        submitting.value = false;
        error.value = upload.error ?? 'File upload failed. Please try again.';
        return;
      }
      attachmentUrl = upload.data;
    }

    final res = await _repo.submitAssignment(
      id,
      notes: notes.value.trim().isEmpty ? null : notes.value.trim(),
      attachmentUrl: attachmentUrl,
    );
    submitting.value = false;
    if (res.success) {
      Get.back<bool>(result: true);
      Get.snackbar('Turned in', 'Your assignment was submitted.',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      error.value = res.error ?? 'Could not submit. Please try again.';
    }
  }

  Future<void> load(String id) async {
    loading.value = true;
    final res = await _repo.loadAssignment(id);
    if (res.success) assignment.value = res.data;
    loading.value = false;
  }
}
