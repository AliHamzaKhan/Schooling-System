import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/headmaster_api_service.dart' show PickerOption;
import '../../../data/headmaster_repository.dart';
import '../../exams/models/exam_category.dart';
import '../models/promotion_models.dart';

/// Drives the student promotion flow: pick a published exam, review the
/// promote/retain suggestion per student, override failed students to Bypass
/// (promote anyway) or Re-exam, choose the next section for promoted students,
/// then apply the batch.
class PromotionController extends GetxController {
  final HeadmasterRepository _repo;
  PromotionController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final applying = false.obs;

  final exams = <ExamListItem>[].obs;
  final sections = <PickerOption>[].obs;
  final selectedExamId = RxnString();

  final previewLoading = false.obs;
  final previewError = RxnString();
  final rows = <PromotionPreviewRow>[].obs;

  // Per-student choices, keyed by student id.
  final outcomes = <String, PromotionOutcome>{}.obs;
  final targets = <String, String?>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final results = await Future.wait([
      _repo.loadExamList(),
      _repo.loadSectionOptions(),
    ]);
    final examRes = results[0] as ApiResponse<List<ExamListItem>>;
    final secRes = results[1] as ApiResponse<List<PickerOption>>;
    if (examRes.success && examRes.data != null) {
      exams.assignAll(examRes.data!);
    } else {
      error.value = examRes.error ?? 'Could not load exams.';
    }
    if (secRes.success && secRes.data != null) {
      sections.assignAll(secRes.data!);
    }
    loading.value = false;
  }

  Future<void> selectExam(String? examId) async {
    selectedExamId.value = examId;
    rows.clear();
    outcomes.clear();
    targets.clear();
    previewError.value = null;
    if (examId == null) return;
    previewLoading.value = true;
    final res = await _repo.loadPromotionPreview(examId);
    previewLoading.value = false;
    if (res.success && res.data != null) {
      rows.assignAll(res.data!);
      for (final r in res.data!) {
        outcomes[r.studentId] = r.suggestedOutcome;
        targets[r.studentId] = null;
      }
    } else {
      previewError.value = res.error ?? 'Could not load the promotion preview.';
    }
  }

  void setOutcome(String studentId, PromotionOutcome outcome) {
    outcomes[studentId] = outcome;
    if (outcome != PromotionOutcome.promoted) targets[studentId] = null;
    outcomes.refresh();
  }

  void setTarget(String studentId, String? sectionId) {
    targets[studentId] = sectionId;
    targets.refresh();
  }

  int get promotedCount =>
      outcomes.values.where((o) => o == PromotionOutcome.promoted).length;

  Future<void> apply() async {
    final examId = selectedExamId.value;
    if (examId == null || rows.isEmpty) return;

    // Every promoted student needs a destination section.
    final missing = rows.where((r) =>
        outcomes[r.studentId] == PromotionOutcome.promoted &&
        (targets[r.studentId] == null));
    if (missing.isNotEmpty) {
      Get.snackbar('Pick a class',
          'Choose the next class & section for every student you promote.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final items = <Map<String, dynamic>>[
      for (final r in rows)
        {
          'student_id': r.studentId,
          'outcome': outcomes[r.studentId]!.wire,
          if (outcomes[r.studentId] == PromotionOutcome.promoted)
            'to_section_id': targets[r.studentId],
        },
    ];

    applying.value = true;
    final res = await _repo.applyPromotions(examId: examId, items: items);
    applying.value = false;
    if (res.success) {
      Get.snackbar('Promotions applied',
          'Processed ${rows.length} student(s).',
          snackPosition: SnackPosition.BOTTOM);
      await selectExam(examId); // refresh from server
    } else {
      Get.snackbar('Could not apply', res.error ?? 'Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
