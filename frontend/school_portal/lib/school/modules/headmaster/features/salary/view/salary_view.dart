import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../controller/salary_controller.dart';
import '../models/salary_models.dart';
import '../utils/money.dart';
import '../../../../../widgets/skeletons.dart';

/// Teacher Salaries — set/edit base salary per teacher, generate monthly
/// payslips, and mark them paid.
class SalaryView extends GetView<SalaryController> {
  const SalaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Teacher Salaries'),
        backgroundColor: AppColors.surface,
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonRosterList());
        }
        if (controller.error.value != null) {
          return Center(
            child: Text(controller.error.value!, style: AppTypography.bodyLg),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackLg,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackXl,
          ),
          children: [
            Text('Teachers', style: AppTypography.labelCaps),
            const SizedBox(height: AppSpacing.stackSm),
            if (controller.staff.isEmpty)
              Text('No teachers yet.', style: AppTypography.bodyLg)
            else
              for (final s in controller.staff) ...[
                _StaffCard(staff: s, controller: controller),
                const SizedBox(height: AppSpacing.stackMd),
              ],
            const SizedBox(height: AppSpacing.stackLg),
            Text('Payslips', style: AppTypography.labelCaps),
            const SizedBox(height: AppSpacing.stackSm),
            if (controller.payslips.isEmpty)
              Text('No payslips generated yet.', style: AppTypography.bodyLg)
            else
              for (final p in controller.payslips) ...[
                _PayslipCard(payslip: p, controller: controller),
                const SizedBox(height: AppSpacing.stackSm),
              ],
          ],
        );
      }),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final SalaryStaff staff;
  final SalaryController controller;
  const _StaffCard({required this.staff, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staff.name, style: AppTypography.bodyLg),
                    Text(
                      staff.hasSalary
                          ? '${staff.designation ?? "Teacher"} · ${money(staff.baseSalary ?? 0)}/mo'
                          : 'No salary set',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  label: staff.hasSalary ? 'Edit salary' : 'Set salary',
                  onPressed: () => controller.setSalaryFlow(staff),
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: PrimaryButton(
                  label: 'Payslip',
                  onPressed: () => controller.generatePayslipFlow(staff),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayslipCard extends StatelessWidget {
  final PayslipRow payslip;
  final SalaryController controller;
  const _PayslipCard({required this.payslip, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isPaid = payslip.status.toLowerCase() == 'paid';
    final monthName =
        SalaryController.monthNames[(payslip.month - 1).clamp(0, 11)];
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.button),
      onTap: () => controller.showPayslipDetail(payslip),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$monthName ${payslip.year} · ${money(payslip.net)} net',
                    style: AppTypography.bodyMd,
                  ),
                  Text(
                    'Gross ${money(payslip.gross)} · ${payslip.status}',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isPaid)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(
                    AppIcons.checkCircle,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  TextButton(
                    onPressed: () =>
                        controller.requestPayrollCorrectionFlow(payslip),
                    child: const Text('Correction'),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => controller.markPaid(payslip),
                    child: const Text('Mark paid'),
                  ),
                  TextButton(
                    onPressed: () =>
                        controller.requestPayrollCorrectionFlow(payslip),
                    child: const Text('Correction'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
