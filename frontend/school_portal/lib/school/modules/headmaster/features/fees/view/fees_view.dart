import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../components/outstanding_card.dart';
import '../components/overdue_row.dart';
import '../components/total_collected_card.dart';
import '../controller/fees_controller.dart';
import '../models/fees_data.dart';
import '../../../../../widgets/skeletons.dart';

/// Fee Management — collection KPIs, outstanding balances, and overdue list.
class FeesView extends GetView<FeesController> {
  const FeesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalTopBar(showAvatar: true),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonPage(
                body: Column(
                  children: [
                    SkeletonStatGrid(count: 2),
                    SizedBox(height: AppSpacing.stackLg),
                    SkeletonCardList(count: 4),
                  ],
                ),
              );
            }
            final data = controller.data.value;
            if (data == null) {
              return AppStateView.error(
                title: 'Could not load this page',
                message:
                    controller.error.value ??
                    'The latest information is unavailable.',
                actionLabel: 'Retry',
                onAction: () => controller.load(),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                0,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackXl,
              ),
              children: [
                Text('Fee Management', style: AppTypography.headlineLg),
                const SizedBox(height: AppSpacing.stackLg),
                PrimaryButton(
                  label: 'Record Payment',
                  leadingIcon: AppIcons.add,
                  trailingIcon: null,
                  onPressed: controller.recordPaymentFlow,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                GhostButton(
                  label: 'All Students · Fees',
                  leadingIcon: AppIcons.groupsRounded,
                  trailingIcon: AppIcons.chevronRightRounded,
                  expanded: true,
                  onPressed: () => Get.toNamed(HeadmasterRoutes.feesRoster),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                GhostButton(
                  label: 'Review Financial Adjustments',
                  leadingIcon: AppIcons.receiptLongRounded,
                  trailingIcon: AppIcons.chevronRightRounded,
                  expanded: true,
                  onPressed: () =>
                      Get.toNamed(HeadmasterRoutes.financialAdjustments),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                TotalCollectedCard(data: data),
                const SizedBox(height: AppSpacing.stackLg),
                OutstandingCard(data: data, onRemindAll: controller.remindAll),
                const SizedBox(height: AppSpacing.stackLg),
                if (data.aging.isNotEmpty) ...[
                  AgingHeader(
                    asOf: data.agingAsOfDate ?? controller.agingAsOf.value,
                    onSelectDate: controller.setAgingAsOf,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  _AgingSummary(buckets: data.aging),
                  const SizedBox(height: AppSpacing.stackLg),
                ],
                if (data.reconciliationIssues != null) ...[
                  _ReconciliationStatus(issues: data.reconciliationIssues!),
                  const SizedBox(height: AppSpacing.stackLg),
                ],
                SectionHeader(
                  title: 'Overdue Payments',
                  actionLabel: 'View All',
                  onAction: () => Get.toNamed(HeadmasterRoutes.overduePayments),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                for (var i = 0; i < data.overdue.length; i++) ...[
                  OverdueRow(
                    payment: data.overdue[i],
                    onSend: () => controller.remind(data.overdue[i]),
                  ),
                  if (i != data.overdue.length - 1)
                    const SizedBox(height: AppSpacing.stackMd),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }
}

/// Responsive, read-only date selector for the fee-aging report.
class AgingHeader extends StatelessWidget {
  final DateTime? asOf;
  final ValueChanged<DateTime> onSelectDate;

  const AgingHeader({
    super.key,
    required this.asOf,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final selected = asOf ?? DateTime.now();
    final localizations = MaterialLocalizations.of(context);
    final label = localizations.formatMediumDate(selected);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 400;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Outstanding aging', style: AppTypography.titleLg),
            const SizedBox(height: 2),
            Text(
              'Open balances by invoice due date',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        );
        final picker = Semantics(
          button: true,
          label: 'Select aging report date. Current date: $label',
          child: OutlinedButton.icon(
            icon: const Icon(AppIcons.calendarTodayOutlined, size: 18),
            label: Text('As of $label', overflow: TextOverflow.ellipsis),
            onPressed: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: selected,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                helpText: 'Select aging report date',
              );
              if (selectedDate != null) onSelectDate(selectedDate);
            },
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              details,
              const SizedBox(height: AppSpacing.stackSm),
              SizedBox(width: double.infinity, child: picker),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: details),
            picker,
          ],
        );
      },
    );
  }
}

class _ReconciliationStatus extends StatelessWidget {
  final int issues;

  const _ReconciliationStatus({required this.issues});

  @override
  Widget build(BuildContext context) {
    final clear = issues == 0;
    final color = clear ? AppColors.tertiary : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Icon(
            clear
                ? AppIcons.checkCircleOutlineRounded
                : AppIcons.warningAmberRounded,
            color: color,
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Text(
              clear
                  ? 'Payment ledger matches all invoice caches.'
                  : '$issues invoice${issues == 1 ? '' : 's'} need ledger review.',
              style: AppTypography.bodyMd.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgingSummary extends StatelessWidget {
  final List<FeeAgingBucket> buckets;

  const _AgingSummary({required this.buckets});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          for (var index = 0; index < buckets.length; index++) ...[
            _AgingRow(bucket: buckets[index]),
            if (index < buckets.length - 1)
              Divider(height: 1, color: AppColors.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _AgingRow extends StatelessWidget {
  final FeeAgingBucket bucket;

  const _AgingRow({required this.bucket});

  @override
  Widget build(BuildContext context) {
    final amount = bucket.outstandingTotal
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.stackMd,
        vertical: AppSpacing.stackSm,
      ),
      child: Row(
        children: [
          Expanded(child: Text(bucket.label, style: AppTypography.bodyMd)),
          Text(
            '${bucket.invoiceCount} invoice${bucket.invoiceCount == 1 ? '' : 's'}',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Text(amount, style: AppTypography.bodyLg),
        ],
      ),
    );
  }
}
