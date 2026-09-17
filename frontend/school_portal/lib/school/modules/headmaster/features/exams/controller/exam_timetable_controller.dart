import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/headmaster_api_service.dart' show PickerOption;
import '../../../data/headmaster_repository.dart';
import '../../timetable/models/timetable_slot.dart' show SubjectOption;
import '../models/exam_category.dart';
import '../models/exam_paper.dart';

/// Builds the per-class exam timetable for one exam category (term).
///
/// Flow: the Headmaster picks a class; behind the scenes an [Exam] exists (or is
/// lazily created) for that (category, class); then subject papers are added,
/// each with its own date and optional time. Different classes keep independent
/// schedules under the same category.
class ExamTimetableController extends GetxController {
  final HeadmasterRepository _repo;
  ExamTimetableController({HeadmasterRepository? repo})
    : _repo = repo ?? Get.find<HeadmasterRepository>();

  late final String categoryId;
  final categoryName = 'Exam'.obs;
  DateTime? termStart;
  DateTime? termEnd;

  final loading = true.obs;
  final error = RxnString();

  final classes = <PickerOption>[].obs;
  final subjects = <SubjectOption>[].obs;
  final selectedClassId = RxnString();

  // classId -> examId for exams already created under this category.
  final _examByClass = <String, String>{};

  final papersLoading = false.obs;
  final papers = <ExamPaper>[].obs;

  // Set true whenever anything is created, so the category list can refresh.
  var changed = false;

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map?) ?? const {};
    categoryId = categoryIdFromRoute(
      parameters: Get.parameters,
      arguments: args,
    );
    if (categoryId.isEmpty) {
      error.value = 'A valid exam category is required.';
      loading.value = false;
      return;
    }
    load();
  }

  static String categoryIdFromRoute({
    required Map<String, String?> parameters,
    Object? arguments,
  }) {
    final fromUrl = parameters['category_id']?.trim() ?? '';
    if (fromUrl.isNotEmpty) return fromUrl;
    if (arguments is Map) {
      return arguments['categoryId']?.toString().trim() ?? '';
    }
    return '';
  }

  String subjectName(String id) {
    final s = subjects.firstWhereOrNull((e) => e.id == id);
    if (s == null) return 'Subject';
    return s.name.isNotEmpty ? s.name : s.code;
  }

  String? get selectedClassLabel =>
      classes.firstWhereOrNull((c) => c.id == selectedClassId.value)?.label;

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final results = await Future.wait([
      _repo.loadExamCategories(),
      _repo.loadClassOptions(),
      _repo.loadSubjectOptions(),
      _repo.loadExamList(),
    ]);
    final categoryRes = results[0] as ApiResponse<List<ExamCategory>>;
    final clsRes = results[1] as ApiResponse<List<PickerOption>>;
    final subRes = results[2] as ApiResponse<List<SubjectOption>>;
    final examRes = results[3] as ApiResponse<List<ExamListItem>>;

    final category = categoryRes.data?.firstWhereOrNull(
      (item) => item.id == categoryId,
    );
    if (!categoryRes.success || category == null) {
      error.value = categoryRes.success
          ? 'Exam category not found.'
          : (categoryRes.error ?? 'Could not load the exam category.');
      classes.clear();
      loading.value = false;
      return;
    }
    categoryName.value = category.name;
    termStart = category.startDate;
    termEnd = category.endDate;

    if (clsRes.success && clsRes.data != null) {
      classes.assignAll(clsRes.data!);
    } else {
      error.value = clsRes.error ?? 'Could not load classes.';
    }
    if (subRes.success && subRes.data != null) {
      subjects.assignAll(subRes.data!);
    }
    _examByClass.clear();
    if (examRes.success && examRes.data != null) {
      for (final e in examRes.data!) {
        if (e.categoryId == categoryId && e.classId != null) {
          _examByClass[e.classId!] = e.id;
        }
      }
    }
    loading.value = false;
  }

  Future<void> selectClass(String? classId) async {
    selectedClassId.value = classId;
    papers.clear();
    if (classId == null) return;
    final examId = _examByClass[classId];
    if (examId == null) return; // no exam yet — created on first paper add
    await _loadPapers(examId);
  }

  Future<void> _loadPapers(String examId) async {
    papersLoading.value = true;
    final res = await _repo.loadExamPapers(examId);
    papersLoading.value = false;
    if (res.success && res.data != null) {
      papers.assignAll(res.data!);
    }
  }

  /// Ensures an exam exists for the selected class, creating one if needed.
  /// Returns the exam id, or null with [error] set on failure.
  Future<String?> _ensureExam() async {
    final classId = selectedClassId.value;
    if (classId == null) return null;
    final existing = _examByClass[classId];
    if (existing != null) return existing;

    final label = selectedClassLabel ?? 'Class';
    final res = await _repo.createExam(
      classId: classId,
      name: '${categoryName.value} — $label',
      categoryId: categoryId,
      startDate: termStart,
      endDate: termEnd,
    );
    if (!res.success || res.data == null) {
      error.value = res.error ?? 'Could not create the exam for this class.';
      return null;
    }
    _examByClass[classId] = res.data!;
    changed = true;
    return res.data!;
  }

  /// Adds a subject paper to the selected class's exam. Returns null on success
  /// or an error message to show inline in the sheet.
  Future<String?> addPaper({
    required String subjectId,
    required double maxMarks,
    required double passMarks,
    DateTime? examDate,
    String? examTime,
  }) async {
    error.value = null;
    final examId = await _ensureExam();
    if (examId == null) return error.value ?? 'Pick a class first.';
    final res = await _repo.addExamPaper(
      examId: examId,
      subjectId: subjectId,
      maxMarks: maxMarks,
      passMarks: passMarks,
      examDate: examDate,
      examTime: examTime,
    );
    if (!res.success) {
      return res.error ?? 'Could not add the subject.';
    }
    changed = true;
    await _loadPapers(examId);
    return null;
  }
}
