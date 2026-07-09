import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/salary_models.dart';

/// Drives the Teacher Salaries screen: lists teachers + their salary profiles,
/// sets/edits salaries, generates payslips, and marks payslips paid.
class SalaryController extends GetxController {
  final HeadmasterRepository _repo;
  SalaryController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final staff = <SalaryStaff>[].obs;
  final payslips = <PayslipRow>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final staffRes = await _repo.loadSalaryStaff();
    if (staffRes.success && staffRes.data != null) {
      staff.assignAll(staffRes.data!);
    } else {
      error.value = staffRes.error ?? 'Could not load staff.';
    }
    final payRes = await _repo.loadPayslips();
    if (payRes.success && payRes.data != null) {
      payslips.assignAll(payRes.data!);
    }
    loading.value = false;
  }

  /// Set or edit a teacher's salary (creates or updates their staff profile).
  Future<void> setSalaryFlow(SalaryStaff s) async {
    final designation =
        TextEditingController(text: s.designation ?? 'Teacher');
    final salary =
        TextEditingController(text: s.baseSalary?.toStringAsFixed(0) ?? '');
    final ok = await showActionFormSheet(
      title: s.hasSalary ? 'Edit Salary — ${s.name}' : 'Set Salary — ${s.name}',
      submitLabel: 'Save',
      fields: [
        GlassInput(
            label: 'Designation',
            hint: 'e.g. Senior Teacher',
            controller: designation),
        GlassInput(
            label: 'Base salary (monthly)',
            hint: 'e.g. 60000',
            controller: salary,
            keyboardType: TextInputType.number),
      ],
      onSubmit: () async {
        final value = double.tryParse(salary.text.trim());
        if (designation.text.trim().isEmpty) return 'Designation is required';
        if (value == null || value < 0) return 'Enter a valid salary';
        final res = s.hasSalary
            ? await _repo.updateStaffProfile(
                profileId: s.profileId!,
                designation: designation.text.trim(),
                baseSalary: value)
            : await _repo.createStaffProfile(
                userId: s.userId,
                designation: designation.text.trim(),
                baseSalary: value);
        return res.success ? null : (res.error ?? 'Could not save salary');
      },
    );
    if (ok == true) {
      Get.snackbar('Salary saved', 'The salary was updated.',
          snackPosition: SnackPosition.BOTTOM);
      await load();
    }
  }

  /// Generate a payslip for a teacher who has a salary profile.
  Future<void> generatePayslipFlow(SalaryStaff s) async {
    if (!s.hasSalary) {
      Get.snackbar('Set salary first', 'Add a base salary before generating a payslip.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final now = DateTime.now();
    final month = TextEditingController(text: '${now.month}');
    final year = TextEditingController(text: '${now.year}');
    final allowances = TextEditingController(text: '0');
    final deductions = TextEditingController(text: '0');
    final ok = await showActionFormSheet(
      title: 'Generate Payslip — ${s.name}',
      submitLabel: 'Generate',
      fields: [
        GlassInput(
            label: 'Month (1–12)',
            hint: '${now.month}',
            controller: month,
            keyboardType: TextInputType.number),
        GlassInput(
            label: 'Year',
            hint: '${now.year}',
            controller: year,
            keyboardType: TextInputType.number),
        GlassInput(
            label: 'Allowances',
            hint: '0',
            controller: allowances,
            keyboardType: TextInputType.number),
        GlassInput(
            label: 'Deductions',
            hint: '0',
            controller: deductions,
            keyboardType: TextInputType.number),
      ],
      onSubmit: () async {
        final m = int.tryParse(month.text.trim());
        final y = int.tryParse(year.text.trim());
        if (m == null || m < 1 || m > 12) return 'Enter a month between 1 and 12';
        if (y == null || y < 2000) return 'Enter a valid year';
        final res = await _repo.generatePayslip(
          profileId: s.profileId!,
          month: m,
          year: y,
          allowances: double.tryParse(allowances.text.trim()) ?? 0,
          deductions: double.tryParse(deductions.text.trim()) ?? 0,
        );
        return res.success ? null : (res.error ?? 'Could not generate payslip');
      },
    );
    if (ok == true) {
      Get.snackbar('Payslip generated', 'The payslip was created.',
          snackPosition: SnackPosition.BOTTOM);
      await load();
    }
  }

  Future<void> markPaid(PayslipRow p) async {
    final res = await _repo.markPayslipPaid(p.id);
    if (res.success) {
      Get.snackbar('Marked paid', 'The payslip was marked as paid.',
          snackPosition: SnackPosition.BOTTOM);
      await load();
    } else {
      Get.snackbar('Could not update', res.error ?? 'Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
