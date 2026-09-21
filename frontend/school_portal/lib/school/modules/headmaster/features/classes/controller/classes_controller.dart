import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/classes_data.dart';

typedef ClassesLoader = Future<ApiResponse<ClassDirectoryData>> Function();

/// Drives the Class Directory: filter dropdown placeholder + data load.
class HeadmasterClassesController extends GetxController {
  final HeadmasterRepository _repo;
  final ClassesLoader _loader;
  HeadmasterClassesController({
    HeadmasterRepository? repo,
    ClassesLoader? loader,
  }) : _repo = repo ?? Get.find<HeadmasterRepository>(),
       _loader =
           loader ?? (repo ?? Get.find<HeadmasterRepository>()).loadClasses;

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<ClassDirectoryData>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    data.value = null;
    final res = await _loader();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load classes.';
    }
    loading.value = false;
  }

  /// Validates and creates a class, then refreshes the directory on success.
  /// Returns `null` when the class was created, or a human-readable message
  /// for an empty name, a duplicate, or a backend failure. Kept free of any UI
  /// (sheet/snackbar) so the full mutation journey is directly harnessable.
  Future<String?> submitNewClass({
    required String name,
    String? level,
    String? roomNo,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Class name is required';
    final existing = data.value?.grades ?? const [];
    final dupe = existing.any(
      (g) => g.className.toLowerCase() == trimmed.toLowerCase(),
    );
    if (dupe) return 'A class named "$trimmed" already exists';
    final trimmedRoom = roomNo?.trim() ?? '';
    final res = await _repo.createClass(
      name: trimmed,
      level: int.tryParse(level?.trim() ?? ''),
      roomNo: trimmedRoom.isEmpty ? null : trimmedRoom,
    );
    if (!res.success) return res.error ?? 'Could not create class';
    await load();
    return null;
  }

  /// Validates and adds a section to [classId], then refreshes on success.
  /// Returns `null` on success or a message otherwise. UI-free, like
  /// [submitNewClass].
  Future<String?> submitNewSection({
    required String classId,
    required String name,
    String? roomNo,
  }) async {
    if (name.trim().isEmpty) return 'Section name is required';
    final trimmedRoom = roomNo?.trim() ?? '';
    final res = await _repo.createSection(
      classId: classId,
      name: name.trim(),
      roomNo: trimmedRoom.isEmpty ? null : trimmedRoom,
    );
    if (!res.success) return res.error ?? 'Could not add section';
    await load();
    return null;
  }

  /// Opens the "New Class" form; on success reloads the directory.
  Future<void> createClassFlow() async {
    final name = TextEditingController();
    final level = TextEditingController();
    final room = TextEditingController();
    final ok = await showActionFormSheet(
      title: 'New Class',
      submitLabel: 'Create Class',
      // The sheet owns these three fields and disposes them when it closes.
      ownedControllers: [name, level, room],
      fields: [
        GlassInput(label: 'Class name', hint: 'e.g. Grade 5', controller: name),
        GlassInput(
          label: 'Level (optional)',
          hint: 'e.g. 5',
          controller: level,
          keyboardType: TextInputType.number,
        ),
        GlassInput(
          label: 'Room no (optional)',
          hint: 'e.g. B-12',
          controller: room,
        ),
      ],
      onSubmit: () =>
          submitNewClass(name: name.text, level: level.text, roomNo: room.text),
    );
    if (ok == true) {
      Get.snackbar(
        'Class created',
        'The class was added.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Opens the "Add Section" form for a class; reloads on success.
  Future<void> addSectionFlow(String classId, String className) async {
    final name = TextEditingController();
    final room = TextEditingController();
    final ok = await showActionFormSheet(
      title: 'Add Section to $className',
      submitLabel: 'Add Section',
      ownedControllers: [name, room],
      fields: [
        GlassInput(label: 'Section name', hint: 'e.g. A', controller: name),
        GlassInput(
          label: 'Room no (optional)',
          hint: 'Defaults to the class room',
          controller: room,
        ),
      ],
      onSubmit: () =>
          submitNewSection(classId: classId, name: name.text, roomNo: room.text),
    );
    if (ok == true) {
      Get.snackbar(
        'Section added',
        'The section was created.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// The grade card's menu: Rename or Delete the class.
  Future<void> classMenuFlow(String classId, String className) async {
    await Get.bottomSheet<void>(
      SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(AppIcons.editOutlined),
              title: const Text('Rename class'),
              onTap: () {
                Get.back<void>();
                _renameClassFlow(classId, className);
              },
            ),
            ListTile(
              leading: const Icon(
                AppIcons.deleteOutline,
                color: AppColors.error,
              ),
              title: const Text(
                'Delete class',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Get.back<void>();
                _deleteClassFlow(classId, className);
              },
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.surface,
    );
  }

  Future<void> _renameClassFlow(String classId, String className) async {
    final name = TextEditingController(text: className);
    final ok = await showActionFormSheet(
      title: 'Rename Class',
      submitLabel: 'Save',
      ownedControllers: [name],
      fields: [
        GlassInput(label: 'Class name', hint: 'e.g. Grade 5', controller: name),
      ],
      onSubmit: () async {
        if (name.text.trim().isEmpty) return 'Class name is required';
        final res = await _repo.updateClass(
          classId: classId,
          name: name.text.trim(),
        );
        return res.success ? null : (res.error ?? 'Could not rename class');
      },
    );
    if (ok == true) {
      Get.snackbar(
        'Class renamed',
        'The class name was updated.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await load();
    }
  }

  Future<void> _deleteClassFlow(String classId, String className) async {
    final confirm = await showAppConfirm(
      icon: AppIcons.deleteOutlineRounded,
      title: 'Delete class?',
      message:
          'This removes "$className" and its sections. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirm) return;
    final res = await _repo.deleteClass(classId);
    if (res.success) {
      Get.snackbar(
        'Class deleted',
        '"$className" was removed.',
        snackPosition: SnackPosition.BOTTOM,
      );
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
