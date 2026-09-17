import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../data/student_report_service.dart';
import '../models/student_report.dart';

/// Drives the Student Report: loads the 360-degree report and runs the
/// guardian-facing actions (request meeting, message, complaint).
///
/// Shared by the Headmaster and Teacher modules — it depends only on the
/// feature-local [StudentReportService], not on either module repository.
class StudentReportController extends GetxController {
  final StudentReportService _repo;
  final bool readOnly;
  StudentReportController({
    StudentReportService? service,
    this.readOnly = false,
  }) : _repo = service ?? StudentReportService();

  final loading = true.obs;
  final error = RxnString();
  final report = Rxn<StudentReport>();
  final actionBusy = false.obs;

  String studentId = '';
  int _loadVersion = 0;

  @override
  void onInit() {
    super.onInit();
    studentId = Get.parameters['student_id']?.trim().isNotEmpty == true
        ? Get.parameters['student_id']!.trim()
        : (Get.arguments is String ? Get.arguments as String : '');
    load();
  }

  Future<void> load() async {
    final version = ++_loadVersion;
    final requestedStudent = studentId;
    loading.value = true;
    error.value = null;
    // Never retain a previous student's private report through a denied refresh.
    report.value = null;
    if (studentId.isEmpty) {
      error.value = 'No student selected.';
      loading.value = false;
      return;
    }
    final res = await _repo.fetchReport(studentId);
    if (version != _loadVersion || requestedStudent != studentId || isClosed) {
      return;
    }
    if (res.success && res.data != null) {
      report.value = res.data;
    } else {
      error.value = res.error ?? "Could not load the student's report.";
    }
    loading.value = false;
  }

  ReportGuardian? get _guardian {
    final list = report.value?.guardians ?? const <ReportGuardian>[];
    return list.isEmpty ? null : list.first;
  }

  bool get hasGuardian => _guardian != null;

  /// Requests a parent-teacher meeting for [scheduledAt] with the student's
  /// guardian.
  Future<void> createMeeting(DateTime scheduledAt) async {
    if (readOnly || loading.value || report.value == null) return;
    final name = report.value?.studentName ?? 'student';
    actionBusy.value = true;
    final res = await _repo.requestMeeting(
      title: 'Parent-teacher meeting — $name',
      scheduledAt: scheduledAt,
      guardianId: _guardian?.id,
      studentId: studentId,
    );
    actionBusy.value = false;
    if (res.success) {
      Get.snackbar(
        'Meeting requested',
        'A meeting has been scheduled with the guardian.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Could not request meeting',
        res.error ?? 'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Compose and send a direct message to the student's guardian (persisted;
  /// shows up in the guardian's alerts).
  Future<void> messageGuardian() => _composeToGuardian(
    title: 'Message ${_guardian?.name ?? 'Guardian'}',
    hint: 'Write a note to the guardian…',
    submitLabel: 'Send',
    kind: 'message',
    successTitle: 'Message sent',
    successBody:
        'Your message to ${_guardian?.name ?? 'the guardian'} was sent.',
  );

  /// Compose and send a complaint/concern about the student to their guardian.
  Future<void> sendComplaint() => _composeToGuardian(
    title: 'Raise a Concern',
    hint: 'Describe the concern for the guardian…',
    submitLabel: 'Submit',
    kind: 'complaint',
    successTitle: 'Concern submitted',
    successBody: "The concern was sent to the student's guardian.",
  );

  Future<void> _composeToGuardian({
    required String title,
    required String hint,
    required String submitLabel,
    required String kind,
    required String successTitle,
    required String successBody,
  }) async {
    if (readOnly || loading.value || report.value == null) return;
    final guardian = _guardian;
    if (guardian == null) {
      Get.snackbar(
        'No guardian linked',
        'Link a guardian to this student first.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final body = TextEditingController();
    final ok = await showActionFormSheet(
      title: title,
      submitLabel: submitLabel,
      // The sheet owns this field and disposes it when it closes.
      ownedControllers: [body],
      fields: [GlassInput(label: 'Message', hint: hint, controller: body)],
      onSubmit: () async {
        if (body.text.trim().isEmpty) return 'Write a message first';
        final res = await _repo.sendDirectMessage(
          recipientId: guardian.id,
          studentId: studentId,
          kind: kind,
          body: body.text.trim(),
        );
        return res.success ? null : (res.error ?? 'Could not send. Try again.');
      },
    );
    if (ok == true) {
      Get.snackbar(
        successTitle,
        successBody,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
