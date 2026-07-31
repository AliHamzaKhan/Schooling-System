import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../app/admin_routes.dart';
import '../../../data/models/admin_metrics.dart';
import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../../../ui/admin_widgets/revenue_trend_card.dart';
import '../../../ui/admin_widgets/section_header.dart';
import '../components/payment_stat_card.dart';
import '../controller/payments_controller.dart';
import '../models/payments_data.dart';

/// Payments & Billing — live revenue KPIs, a revenue trend, and recent
/// transactions, plus a shortcut into the plan editor.
class PaymentsView extends GetView<PaymentsController> {
  const PaymentsView({super.key});

  static String _money(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  List<PaymentStat> _stats(BillingReport d) => [
        PaymentStat(
          label: 'Total Revenue',
          value: _money(d.totalRevenue),
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.primary,
        ),
        PaymentStat(
          label: 'This Month',
          value: _money(d.thisMonthRevenue),
          icon: Icons.calendar_month_rounded,
          color: AppColors.tertiary,
        ),
        PaymentStat(
          label: 'Payments',
          value: '${d.paymentCount}',
          icon: Icons.receipt_long_rounded,
          color: AppColors.aiAccent,
        ),
        PaymentStat(
          label: 'Pending',
          value: _money(d.pendingAmount),
          icon: Icons.pending_actions_outlined,
          color: const Color(0xFFE8A317),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminTopBar(title: 'Billing', showAvatar: true),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = controller.data.value;
            if (data == null) {
              return Center(
                  child: Text(controller.error.value ?? 'No data',
                      style: AppTypography.bodyLg));
            }
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  Text('Revenue, settlements and recent transactions.',
                      style: AppTypography.bodyLg),
                  const SizedBox(height: AppSpacing.stackLg),
                  for (final s in _stats(data)) ...[
                    PaymentStatCard(stat: s),
                    const SizedBox(height: AppSpacing.stackMd),
                  ],
                  const SizedBox(height: AppSpacing.stackSm),
                  RevenueTrendCard(
                      title: 'Revenue Trend', months: data.months),
                  const SizedBox(height: AppSpacing.stackLg),

                  // Recent transactions.
                  GlassSurface(
                    padding: const EdgeInsets.all(AppSpacing.stackLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Recent Transactions'),
                        const SizedBox(height: AppSpacing.stackSm),
                        if (data.recent.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.stackMd),
                            child: Text('No transactions yet.',
                                style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.onSurfaceVariant)),
                          )
                        else
                          for (var i = 0; i < data.recent.length; i++) ...[
                            _TransactionRow(payment: data.recent[i]),
                            if (i != data.recent.length - 1)
                              const Divider(
                                  height: AppSpacing.stackLg,
                                  color: AppColors.outlineVariant),
                          ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  GhostButton(
                    label: 'Manage Subscription Plans',
                    expanded: true,
                    trailingIcon: Icons.chevron_right_rounded,
                    onPressed: () => Get.toNamed(AdminRoutes.subscriptions),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final PaymentRow payment;
  const _TransactionRow({required this.payment});

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: const Icon(Icons.arrow_downward_rounded,
              color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.stackMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(payment.schoolName ?? 'School',
                  style: AppTypography.titleMd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                '${payment.planName ?? 'Plan'} · ${_fmtDate(payment.paidAt)}',
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.stackSm),
        Text(PaymentsView._money(payment.amount),
            style: AppTypography.titleMd
                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
