import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/salary_models.dart';
import '../utils/money.dart';
import '../utils/payslip_pdf.dart';

class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabel;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              items: [
                for (final i in items)
                  DropdownMenuItem<T>(value: i, child: Text(itemLabel(i))),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

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

  /// Standard designation options — headmaster picks one when setting salary.
  static const List<String> designationOptions = [
    'Teacher',
    'Senior Teacher',
    'Head of Department',
    'Vice Principal',
    'Principal',
    'Administrator',
    'Librarian',
    'Counsellor',
  ];

  static const List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Set or edit a teacher's salary (creates or updates their staff profile).
  Future<void> setSalaryFlow(SalaryStaff s) async {
    final initial = designationOptions.contains(s.designation)
        ? s.designation!
        : 'Teacher';
    final designation = initial.obs;
    final salary = TextEditingController(
      text: s.baseSalary?.toStringAsFixed(0) ?? '',
    );
    final ok = await showActionFormSheet(
      title: s.hasSalary ? 'Edit Salary — ${s.name}' : 'Set Salary — ${s.name}',
      submitLabel: 'Save',
      // The sheet owns this field and disposes it when it closes.
      ownedControllers: [salary],
      fields: [
        Obx(
          () => _LabeledDropdown<String>(
            label: 'Designation',
            value: designation.value,
            items: designationOptions,
            onChanged: (v) => designation.value = v ?? 'Teacher',
            itemLabel: (v) => v,
          ),
        ),
        GlassInput(
          label: 'Base salary (monthly)',
          hint: 'e.g. 60000',
          controller: salary,
          keyboardType: TextInputType.number,
        ),
      ],
      onSubmit: () async {
        final value = double.tryParse(salary.text.trim());
        if (value == null || value < 0) return 'Enter a valid salary';
        final res = s.hasSalary
            ? await _repo.updateStaffProfile(
                profileId: s.profileId!,
                designation: designation.value,
                baseSalary: value,
              )
            : await _repo.createStaffProfile(
                userId: s.userId,
                designation: designation.value,
                baseSalary: value,
              );
        return res.success ? null : (res.error ?? 'Could not save salary');
      },
    );
    if (ok == true) {
      Get.snackbar(
        'Salary saved',
        'The salary was updated.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await load();
    }
  }

  /// Open the full-page Generate Payslip flow; reload on success.
  Future<void> generatePayslipFlow(SalaryStaff s) async {
    if (!s.hasSalary) {
      Get.snackbar(
        'Set salary first',
        'Add a base salary before generating a payslip.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final ok = await Get.toNamed(
      HeadmasterRoutes.generatePayslip,
      parameters: {'staff_id': s.userId},
    );
    if (ok == true) await load();
  }

  /// Show payslip breakdown, with a Share-as-PDF action.
  Future<void> showPayslipDetail(PayslipRow p) async {
    final s = staff.firstWhereOrNull((s) => s.profileId == p.staffProfileId);
    await Get.bottomSheet<void>(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payslip Details', style: AppTypography.titleLg),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                '${s?.name ?? "Teacher"} · ${monthNames[(p.month - 1).clamp(0, 11)]} ${p.year}',
                style: AppTypography.bodyLg,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              _kv('Status', p.status),
              _kv('Gross', money(p.gross)),
              if (p.absenceDeduction > 0)
                _kv(
                  'Absence deduction',
                  '- ${money(p.absenceDeduction)} (${p.absentDays}d)',
                ),
              _kv('Deductions', '- ${money(p.deductions)}'),
              _kv('Net', money(p.net)),
              _kv(
                'Attendance',
                'P ${p.presentDays} · A ${p.absentDays} · L ${p.lateDays} · Lv ${p.leaveDays}',
              ),
              if (p.paidOn != null) _kv('Paid on', p.paidOn!),
              const SizedBox(height: AppSpacing.stackLg),
              GhostButton(
                label: 'Request payroll correction',
                leadingIcon: AppIcons.editOutlined,
                onPressed: () async {
                  Get.back();
                  await requestPayrollCorrectionFlow(p);
                },
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: 'Share PDF',
                      leadingIcon: AppIcons.pictureAsPdfOutlined,
                      onPressed: () async {
                        Get.back();
                        await sharePayslipPdf(p);
                      },
                    ),
                  ),
                  if (p.status.toLowerCase() != 'paid') ...[
                    const SizedBox(width: AppSpacing.stackSm),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Mark paid',
                        onPressed: () async {
                          Get.back();
                          await markPaid(p);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Create a Headmaster review request for a payslip. The adjustment ledger
  /// records the request only; money-policy posting is deliberately separate.
  Future<void> requestPayrollCorrectionFlow(PayslipRow p) async {
    final amount = TextEditingController();
    final reason = TextEditingController();
    final monthName = monthNames[(p.month - 1).clamp(0, 11)];
    final ok = await showActionFormSheet(
      title: 'Request Payroll Correction',
      submitLabel: 'Submit for review',
      ownedControllers: [amount, reason],
      fields: [
        _PayrollCorrectionNotice(
          period: '$monthName ${p.year}',
          net: money(p.net),
        ),
        GlassInput(
          label: 'Proposed correction amount',
          hint: 'e.g. 1500.00',
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        GlassInput(
          label: 'Reason',
          hint: 'Explain what needs correction',
          controller: reason,
        ),
      ],
      onSubmit: () async {
        final proposedAmount = amount.text.trim();
        final parsedAmount = double.tryParse(proposedAmount);
        final requestReason = reason.text.trim();
        if (parsedAmount == null ||
            !parsedAmount.isFinite ||
            parsedAmount <= 0) {
          return 'Enter a positive proposed correction amount.';
        }
        if (requestReason.length < 3) {
          return 'Give a reason with at least 3 characters.';
        }
        final result = await _repo.createFinancialAdjustment(
          kind: 'payroll_correction',
          targetId: p.id,
          proposedAmount: proposedAmount,
          reason: requestReason,
        );
        return result.success
            ? null
            : (result.error ?? 'Could not submit the payroll correction.');
      },
    );
    if (ok == true) {
      Get.snackbar(
        'Correction submitted',
        'It awaits a Headmaster decision. This does not change the payslip or payroll yet.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Render the payslip as a PDF (school name + logo header) and open the
  /// platform share sheet.
  Future<void> sharePayslipPdf(PayslipRow p) async {
    final s = staff.firstWhereOrNull((st) => st.profileId == p.staffProfileId);
    if (s == null) {
      Get.snackbar(
        'Could not build PDF',
        'Staff record not found.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    // School branding for the PDF header; a failure here is non-fatal.
    final profileRes = await _repo.loadSchoolProfile();
    try {
      await PayslipPdf.share(
        payslip: p,
        staff: s,
        school: profileRes.success ? profileRes.data : null,
      );
    } catch (e) {
      Get.snackbar(
        'Could not share PDF',
        '$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  static Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            k,
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(v, style: AppTypography.bodyMd)),
      ],
    ),
  );

  Future<void> markPaid(PayslipRow p) async {
    final res = await _repo.markPayslipPaid(p.id);
    if (res.success) {
      Get.snackbar(
        'Marked paid',
        'The payslip was marked as paid.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await load();
    } else {
      Get.snackbar(
        'Could not update',
        res.error ?? 'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _PayrollCorrectionNotice extends StatelessWidget {
  final String period;
  final String net;

  const _PayrollCorrectionNotice({required this.period, required this.net});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Text(
        '$period payslip · current net $net\n\n'
        'This creates a review request only. It does not change the payslip, mark it paid, or post a payroll movement.',
        style: AppTypography.bodyMd,
      ),
    );
  }
}
