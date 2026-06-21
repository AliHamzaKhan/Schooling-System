import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../../../../../widgets/status_pill.dart';
import '../../../shared/widgets/child_switcher.dart';
import '../controller/fee_controller.dart';
import '../models/fee_data.dart';

/// Fee Status — drill-in screen. Outstanding-balance hero, paid-to-date, and a
/// report-style invoice ledger with paid / due / overdue pills.
class FeeView extends GetView<FeeController> {
  const FeeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          const PortalTopBar(title: 'Fee Status', showAvatar: false),
          const ChildSwitcher(),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final d = controller.data.value;
              if (d == null) return const SizedBox.shrink();
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackSm,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  _BalanceHero(data: d),
                  const SizedBox(height: AppSpacing.stackLg),
                  const SectionHeader(title: 'Invoices'),
                  const SizedBox(height: AppSpacing.stackMd),
                  for (final inv in d.invoices) ...[
                    _InvoiceRow(invoice: inv, currency: d.currency),
                    const SizedBox(height: AppSpacing.stackSm),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  final FeeData data;
  const _BalanceHero({required this.data});

  @override
  Widget build(BuildContext context) {
    final cleared = data.outstanding <= 0;
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(cleared ? 'No dues' : 'Outstanding',
                    style: AppTypography.bodyLg),
              ),
              StatusPill(
                label: cleared ? 'All paid' : 'Action needed',
                color: cleared ? AppColors.tertiary : AppColors.error,
                icon: cleared
                    ? Icons.verified_outlined
                    : Icons.error_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${data.currency}${data.outstanding.toStringAsFixed(0)}',
            style: AppTypography.displayLg.copyWith(
                fontSize: 44,
                color: cleared ? AppColors.tertiary : AppColors.error),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              Expanded(
                child: Text('Paid this year',
                    style: AppTypography.bodyMd),
              ),
              Text(
                  '${data.currency}${data.paidThisYear.toStringAsFixed(0)}',
                  style: AppTypography.titleMd
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          if (data.nextDueDate != null && !cleared) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text('Next due', style: AppTypography.bodyMd)),
                Text(data.nextDueDate!,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ],
          if (!cleared) ...[
            const SizedBox(height: AppSpacing.stackMd),
            PrimaryButton(
              label: 'Pay now',
              onPressed: () => Get.snackbar('Payment',
                  'Payment flow is not wired in this build.',
                  snackPosition: SnackPosition.BOTTOM),
            ),
          ],
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final FeeInvoice invoice;
  final String currency;
  const _InvoiceRow({required this.invoice, required this.currency});

  ({String label, Color color}) get _style => switch (invoice.status) {
        InvoiceStatus.paid => (label: 'Paid', color: AppColors.tertiary),
        InvoiceStatus.due => (label: 'Due', color: Color(0xFFE8A317)),
        InvoiceStatus.overdue => (label: 'Overdue', color: AppColors.error),
      };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.title,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                Text('${invoice.period} · Due ${invoice.dueDate}',
                    style: AppTypography.bodyMd),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$currency${invoice.amount.toStringAsFixed(0)}',
                  style: AppTypography.titleMd
                      .copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              StatusPill(label: s.label, color: s.color),
            ],
          ),
        ],
      ),
    );
  }
}
