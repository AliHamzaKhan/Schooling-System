import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../data/headmaster_repository.dart';
import '../models/exam_category.dart';
import '../view/exam_category_form_sheet.dart';

/// Manages the school's exam categories (terms) — e.g. "Mid Term", "Final Term".
/// Exams are created under a category so results can be grouped by term.
class ExamCategoriesController extends GetxController {
  final HeadmasterRepository _repo;
  ExamCategoriesController({HeadmasterRepository? repo})
    : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final categories = <ExamCategory>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadExamCategories();
    if (res.success && res.data != null) {
      categories.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load exam categories.';
    }
    loading.value = false;
  }

  Future<void> createFlow() async {
    final ok = await showExamCategoryFormSheet(
      title: 'New Exam Category',
      submitLabel: 'Create',
      onSubmit: (name, start, end) async {
        final res = await _repo.createExamCategory(
          name,
          startDate: start,
          endDate: end,
        );
        return res.success ? null : (res.error ?? 'Could not create category');
      },
    );
    if (ok == true) await load();
  }

  Future<void> editFlow(ExamCategory category) async {
    final ok = await showExamCategoryFormSheet(
      title: 'Edit Category',
      submitLabel: 'Save',
      initialName: category.name,
      initialStart: category.startDate,
      initialEnd: category.endDate,
      onSubmit: (name, start, end) async {
        final res = await _repo.updateExamCategory(
          category.id,
          name: name,
          startDate: start,
          endDate: end,
        );
        return res.success ? null : (res.error ?? 'Could not save category');
      },
    );
    if (ok == true) await load();
  }

  Future<void> announceFlow(ExamCategory category) async {
    if (!category.canAnnounce) {
      Get.snackbar(
        'Not yet',
        'You can announce "${category.name}" once its start date arrives.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final confirm = await showAppConfirm(
      icon: AppIcons.campaignRounded,
      title: 'Announce ${category.name}?',
      message: category.announced
          ? 'This will send the announcement to the whole school again.'
          : 'This notifies every student, guardian and teacher that '
                '${category.name} examinations are scheduled.',
      confirmLabel: 'Announce',
    );
    if (!confirm) return;
    final res = await _repo.announceExamCategory(category.id);
    if (res.success) {
      Get.snackbar(
        'Announced',
        '${category.name} sent to the school.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await load();
    } else {
      Get.snackbar(
        'Could not announce',
        res.error ?? 'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> openTimetable(ExamCategory category) async {
    await Get.toNamed(
      HeadmasterRoutes.examTimetable,
      parameters: {'category_id': category.id},
    );
    await load();
  }

  Future<void> deleteFlow(ExamCategory category) async {
    final confirm = await showAppConfirm(
      icon: AppIcons.deleteOutlineRounded,
      title: 'Delete category?',
      message:
          'Delete "${category.name}"? Exams already under it keep their name '
          'but lose the category link.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirm) return;
    final res = await _repo.deleteExamCategory(category.id);
    if (res.success) {
      await load();
    } else {
      Get.snackbar(
        'Could not delete',
        res.error ?? 'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
