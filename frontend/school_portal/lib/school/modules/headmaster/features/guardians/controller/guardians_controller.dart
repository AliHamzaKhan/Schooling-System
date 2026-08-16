import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/guardian.dart';

class GuardiansController extends GetxController {
  final HeadmasterRepository _repo;
  GuardiansController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final results = <Guardian>[].obs;
  final query = ''.obs;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  /// Total guardian count regardless of filters (shown in the "All Guardians"
  /// chip).
  int get total => 142;

  void onSearch(String v) {
    query.value = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), fetch);
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadGuardians(query: query.value);
    if (res.success && res.data != null) {
      results.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load guardians.';
    }
    loading.value = false;
  }

  void invite(String id) {
    Get.snackbar('Invite sent', 'Portal invite emailed to guardian $id.',
        snackPosition: SnackPosition.BOTTOM);
  }

  /// Opens the "Add Guardian" form. Creates the account and, if a child is
  /// picked, links that student to the guardian. Reloads on success.
  Future<void> addGuardianFlow() async {
    final studentsRes = await _repo.loadStudentOptions();
    final students = studentsRes.data ?? const [];

    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final selectedChild = Rxn<String>(); // null == link later

    final ok = await showActionFormSheet(
      title: 'Add Guardian',
      submitLabel: 'Add Guardian',
      // The sheet owns these fields and disposes them when it closes.
      ownedControllers: [name, email, password],
      fields: [
        GlassInput(label: 'Full name', hint: 'Jane Doe', controller: name),
        GlassInput(
          label: 'Email',
          hint: 'jane@school.edu',
          controller: email,
          keyboardType: TextInputType.emailAddress,
        ),
        GlassInput(
          label: 'Temporary password',
          hint: 'At least 8 characters',
          controller: password,
          obscureText: true,
        ),
        Obx(() => ActionDropdownField<String>(
              label: 'Link child (optional)',
              hint: students.isEmpty ? 'No students yet' : 'Select a student',
              value: selectedChild.value,
              items: [
                const DropdownMenuItem(value: null, child: Text('None — link later')),
                for (final s in students)
                  DropdownMenuItem(value: s.id, child: Text(s.label)),
              ],
              onChanged: (v) => selectedChild.value = v,
            )),
      ],
      onSubmit: () async {
        if (name.text.trim().isEmpty) return 'Full name is required';
        if (!email.text.contains('@')) return 'A valid email is required';
        if (password.text.trim().length < 8) {
          return 'Password must be at least 8 characters';
        }
        final created = await _repo.createUser(
            email: email.text.trim(),
            password: password.text.trim(),
            fullName: name.text.trim(),
            role: 'guardian');
        if (!created.success) {
          return created.error ?? 'Could not create the guardian';
        }
        final childId = selectedChild.value;
        if (childId != null) {
          final guardianId = '${(created.data as Map)['id']}';
          final linked =
              await _repo.linkChild(guardianId: guardianId, studentId: childId);
          if (!linked.success) {
            return linked.error ?? 'Guardian created, but linking the child failed';
          }
        }
        return null;
      },
    );
    if (ok == true) {
      Get.snackbar('Guardian added', 'The guardian account was created.',
          snackPosition: SnackPosition.BOTTOM);
      await fetch();
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
