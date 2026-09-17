import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/classes_data.dart';

/// Drives the Class Directory: filter dropdown placeholder + data load.
class HeadmasterClassesController extends GetxController {
  final HeadmasterRepository _repo;
  HeadmasterClassesController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

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
    final res = await _repo.loadClasses();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load classes.';
    }
    loading.value = false;
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
      onSubmit: () async {
        final trimmed = name.text.trim();
        if (trimmed.isEmpty) return 'Class name is required';
        final existing = data.value?.grades ?? const [];
        final dupe = existing.any(
            (g) => g.className.toLowerCase() == trimmed.toLowerCase());
        if (dupe) return 'A class named "$trimmed" already exists';
        final res = await _repo.createClass(
          name: trimmed,
          level: int.tryParse(level.text.trim()),
          roomNo: room.text.trim().isEmpty ? null : room.text.trim(),
        );
        return res.success ? null : (res.error ?? 'Could not create class');
      },
    );
    if (ok == true) {
      Get.snackbar('Class created', 'The class was added.',
          snackPosition: SnackPosition.BOTTOM);
      await load();
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
      onSubmit: () async {
        if (name.text.trim().isEmpty) return 'Section name is required';
        final res = await _repo.createSection(
          classId: classId,
          name: name.text.trim(),
          roomNo: room.text.trim().isEmpty ? null : room.text.trim(),
        );
        return res.success ? null : (res.error ?? 'Could not add section');
      },
    );
    if (ok == true) {
      Get.snackbar('Section added', 'The section was created.',
          snackPosition: SnackPosition.BOTTOM);
      await load();
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
              leading: const Icon(AppIcons.deleteOutline, color: AppColors.error),
              title: const Text('Delete class',
                  style: TextStyle(color: AppColors.error)),
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
        final res =
            await _repo.updateClass(classId: classId, name: name.text.trim());
        return res.success ? null : (res.error ?? 'Could not rename class');
      },
    );
    if (ok == true) {
      Get.snackbar('Class renamed', 'The class name was updated.',
          snackPosition: SnackPosition.BOTTOM);
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
      Get.snackbar('Class deleted', '"$className" was removed.',
          snackPosition: SnackPosition.BOTTOM);
      await load();
    } else {
      Get.snackbar('Could not delete', res.error ?? 'Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
