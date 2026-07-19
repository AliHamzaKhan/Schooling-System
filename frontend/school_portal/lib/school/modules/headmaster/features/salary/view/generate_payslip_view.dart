import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/headmaster_repository.dart';
import '../controller/salary_controller.dart';
import '../models/salary_models.dart';
import '../utils/money.dart';

/// Arguments for [GeneratePayslipView] — the teacher whose payslip we build.
class GeneratePayslipArgs {
  final SalaryStaff staff;
  const GeneratePayslipArgs(this.staff);
}

/// Full-page Generate Payslip flow. Picking a month pulls that month's
/// attendance (present / absent / late / leave) so the headmaster can see
/// exactly what they're paying for, and optionally deduct for absences at
/// base_salary ÷ 30 per absent day.
class GeneratePayslipView extends StatefulWidget {
  const GeneratePayslipView({super.key});

  @override
  State<GeneratePayslipView> createState() => _GeneratePayslipViewState();
}

class _GeneratePayslipViewState extends State<GeneratePayslipView> {
  final _repo = Get.find<HeadmasterRepository>();
  late final SalaryStaff _staff;

  final _month = DateTime.now().month.obs;
  final _year = DateTime.now().year.obs;
  final _deductAbsences = false.obs;

  final _allowances = TextEditingController(text: '0');
  final _deductions = TextEditingController(text: '0');

  final _summary = Rxn<MonthlyAttendanceSummary>();
  final _summaryLoading = false.obs;
  final _submitting = false.obs;
  final _error = RxnString();

  @override
  void initState() {
    super.initState();
    _staff = (Get.arguments as GeneratePayslipArgs).staff;
    _loadSummary();
  }

  @override
  void dispose() {
    _allowances.dispose();
    _deductions.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    _summaryLoading.value = true;
    final res = await _repo.loadTeacherMonthlyAttendance(
      teacherId: _staff.userId,
      month: _month.value,
      year: _year.value,
    );
    if (res.success && res.data != null) {
      _summary.value = res.data;
    } else {
      _summary.value = null;
    }
    _summaryLoading.value = false;
  }

  /// Live preview of the payslip totals as the form changes.
  ({double gross, double absence, double manual, double net}) get _preview {
    final base = _staff.baseSalary ?? 0;
    final allow = double.tryParse(_allowances.text.trim()) ?? 0;
    final manual = double.tryParse(_deductions.text.trim()) ?? 0;
    final absence = _deductAbsences.value
        ? (_summary.value?.projectedAbsenceDeduction ?? 0)
        : 0.0;
    final gross = base + allow;
    return (
      gross: gross,
      absence: absence,
      manual: manual,
      net: gross - manual - absence,
    );
  }

  Future<void> _submit() async {
    _error.value = null;
    final allow = double.tryParse(_allowances.text.trim());
    final manual = double.tryParse(_deductions.text.trim());
    if (allow == null || allow < 0) {
      _error.value = 'Enter valid allowances (or 0)';
      return;
    }
    if (manual == null || manual < 0) {
      _error.value = 'Enter valid deductions (or 0)';
      return;
    }
    if (_preview.net < 0) {
      _error.value = 'Deductions exceed gross salary';
      return;
    }
    _submitting.value = true;
    final res = await _repo.generatePayslip(
      profileId: _staff.profileId!,
      month: _month.value,
      year: _year.value,
      allowances: allow,
      deductions: manual,
      deductAbsences: _deductAbsences.value,
    );
    _submitting.value = false;
    if (res.success) {
      Get.back<bool>(result: true);
      Get.snackbar('Payslip generated',
          '${SalaryController.monthNames[_month.value - 1]} ${_year.value} · ${_staff.name}',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      _error.value = res.error ?? 'Could not generate payslip';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Generate Payslip'),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackLg,
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackXl,
        ),
        children: [
          _StaffHeader(staff: _staff),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Period', style: AppTypography.labelCaps),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Obx(() => _Dropdown<int>(
                      label: 'Month',
                      value: _month.value,
                      items: [
                        for (var i = 1; i <= 12; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(SalaryController.monthNames[i - 1]),
                          ),
                      ],
                      onChanged: (v) {
                        _month.value = v ?? _month.value;
                        _loadSummary();
                      },
                    )),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Expanded(
                flex: 2,
                child: Obx(() => _Dropdown<int>(
                      label: 'Year',
                      value: _year.value,
                      items: [
                        for (var y = DateTime.now().year - 2;
                            y <= DateTime.now().year + 1;
                            y++)
                          DropdownMenuItem(value: y, child: Text('$y')),
                      ],
                      onChanged: (v) {
                        _year.value = v ?? _year.value;
                        _loadSummary();
                      },
                    )),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Attendance this period', style: AppTypography.labelCaps),
          const SizedBox(height: AppSpacing.stackSm),
          Obx(() {
            if (_summaryLoading.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final s = _summary.value;
            if (s == null || s.markedDays == 0) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Text(
                  'No attendance recorded for this month. The payslip will be '
                  'generated without any absence deduction.',
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              );
            }
            return _AttendanceGrid(summary: s);
          }),
          const SizedBox(height: AppSpacing.stackMd),
          Obx(() {
            final s = _summary.value;
            final canDeduct = (s?.absentDays ?? 0) > 0;
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(
                  color: _deductAbsences.value
                      ? AppColors.error
                      : AppColors.outlineVariant,
                ),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.stackMd, vertical: 4),
                title: Text('Deduct salary for absences',
                    style: AppTypography.bodyLg),
                subtitle: Text(
                  canDeduct
                      ? '${s!.absentDays} absent × ${money(( _staff.baseSalary ?? 0) / 30)} = ${money(s.projectedAbsenceDeduction)}'
                      : 'No absences recorded for this month',
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                value: _deductAbsences.value,
                activeThumbColor: AppColors.error,
                onChanged:
                    canDeduct ? (v) => _deductAbsences.value = v : null,
              ),
            );
          }),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Adjustments', style: AppTypography.labelCaps),
          const SizedBox(height: AppSpacing.stackSm),
          GlassInput(
            label: 'Allowances',
            hint: '0',
            controller: _allowances,
            keyboardType: TextInputType.number,
            onChanged: (_) => _deductAbsences.refresh(),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          GlassInput(
            label: 'Other deductions',
            hint: '0',
            controller: _deductions,
            keyboardType: TextInputType.number,
            onChanged: (_) => _deductAbsences.refresh(),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Obx(() {
            // Depend on the toggle so the preview recomputes with the form.
            _deductAbsences.value;
            final p = _preview;
            return Container(
              padding: const EdgeInsets.all(AppSpacing.stackLg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _row('Base salary', money(_staff.baseSalary ?? 0)),
                  _row('Allowances',
                      '+ ${money(p.gross - (_staff.baseSalary ?? 0))}'),
                  const Divider(height: 20),
                  _row('Gross', money(p.gross), bold: true),
                  if (p.absence > 0)
                    _row('Absence deduction', '- ${money(p.absence)}',
                        color: AppColors.error),
                  if (p.manual > 0)
                    _row('Other deductions', '- ${money(p.manual)}',
                        color: AppColors.error),
                  const Divider(height: 20),
                  _row('Net pay', money(p.net), bold: true, big: true),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.stackLg),
          Obx(() {
            final err = _error.value;
            if (err == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
              child: Text(err,
                  style:
                      AppTypography.bodyMd.copyWith(color: AppColors.error)),
            );
          }),
          Obx(() => PrimaryButton(
                label: 'Generate Payslip',
                isLoading: _submitting.value,
                expanded: true,
                onPressed: _submitting.value ? null : _submit,
              )),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, bool big = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          Text(
            value,
            style: (big ? AppTypography.titleLg : AppTypography.bodyLg)
                .copyWith(
              color: color ?? AppColors.onSurface,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffHeader extends StatelessWidget {
  final SalaryStaff staff;
  const _StaffHeader({required this.staff});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
              style:
                  AppTypography.titleLg.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.name, style: AppTypography.titleMd),
                const SizedBox(height: 2),
                Text(
                  '${staff.designation ?? "Teacher"} · ${money(staff.baseSalary ?? 0)}/mo',
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceGrid extends StatelessWidget {
  final MonthlyAttendanceSummary summary;
  const _AttendanceGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _cell('Present', summary.presentDays, AppColors.tertiary,
            Icons.check_circle_outline),
        const SizedBox(width: 6),
        _cell('Absent', summary.absentDays, AppColors.error,
            Icons.person_off_outlined),
        const SizedBox(width: 6),
        _cell('Late', summary.lateDays, const Color(0xFFF59E0B),
            Icons.schedule_rounded),
        const SizedBox(width: 6),
        _cell('Leave', summary.leaveDays, AppColors.primary,
            Icons.event_busy_outlined),
      ],
    );
  }

  Widget _cell(String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text('$value',
                style: AppTypography.titleLg
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
            Text(label,
                style: AppTypography.labelMd.copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTypography.labelCaps
                .copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
