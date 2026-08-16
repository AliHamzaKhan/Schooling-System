import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/admin_routes.dart';
import '../../../data/models/admin_metrics.dart';
import '../../../ui/admin_theme.dart';
import '../../../ui/admin_widgets/admin_surface.dart';
import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../../../ui/admin_widgets/revenue_trend_card.dart';
import '../../../ui/admin_widgets/section_header.dart';
import '../components/payment_stat_card.dart';
import '../controller/payments_controller.dart';
import '../models/payments_data.dart';

/// Financial Overview — billing KPIs, the revenue trend, and the most recent
/// transactions, plus a shortcut into the plan editor.
class PaymentsView extends GetView<PaymentsController> {
  const PaymentsView({super.key});

  static String _money(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  static String _amount(double v) =>
      '\$${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';

  /// Month-over-month change from the last two revenue buckets, or null when
  /// there isn't a full prior month to compare against.
  static String? _monthDelta(BillingReport d) {
    if (d.months.length < 2) return null;
    final prev = d.months[d.months.length - 2].total;
    final curr = d.months.last.total;
    if (prev <= 0) return null;
    final pct = ((curr - prev) / prev) * 100;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(0)}% from last';
  }

  List<PaymentStat> _stats(BillingReport d) {
    final delta = _monthDelta(d);
    return [
      PaymentStat(
        label: 'Total Revenue',
        value: _money(d.totalRevenue),
        icon: Icons.account_balance_outlined,
        color: AdminPalette.ink,
      ),
      PaymentStat(
        label: 'This Month',
        value: _money(d.thisMonthRevenue),
        icon: Icons.calendar_month_outlined,
        color: AdminPalette.ink,
        caption: delta,
        captionColor:
            delta != null && delta.startsWith('-')
                ? AdminPalette.danger
                : AdminPalette.positive,
      ),
      PaymentStat(
        label: 'Payments',
        value: '${d.paymentCount}',
        icon: Icons.receipt_long_outlined,
        color: AdminPalette.ink,
      ),
      PaymentStat(
        label: 'Pending',
        value: _money(d.pendingAmount),
        icon: Icons.pending_actions_outlined,
        color: AdminPalette.ink,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AdminScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminTopBar(title: 'Billing', showAvatar: true),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(
                    child: CircularProgressIndicator(color: AdminPalette.ink));
              }
              final data = controller.data.value;
              if (data == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(controller.error.value ?? 'No data',
                        textAlign: TextAlign.center, style: AdminType.body),
                  ),
                );
              }
              final stats = _stats(data);
              return RefreshIndicator(
                onRefresh: controller.load,
                color: AdminPalette.ink,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                      kAdminGutter, 4, kAdminGutter, 36),
                  children: [
                    const AdminPageHeader(
                      title: 'Financial Overview',
                      subtitle:
                          'Review your recent billing metrics and revenue trends.',
                    ),

                    // ── KPI grid (2 columns) ───────────────────────
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.42,
                      children: [
                        for (final s in stats) PaymentStatCard(stat: s),
                      ],
                    ),
                    const SizedBox(height: 20),

                    RevenueTrendCard(title: 'Revenue Trend', months: data.months),
                    const SizedBox(height: 20),

                    // ── Recent transactions ────────────────────────
                    SectionHeader(
                      title: 'Recent Transactions',
                      large: true,
                      actionLabel: data.recent.isEmpty ? null : 'View All',
                      onAction: () => Get.toNamed(AdminRoutes.revenue),
                    ),
                    const SizedBox(height: 14),
                    if (data.recent.isEmpty)
                      AdminCard(
                        padding: const EdgeInsets.all(20),
                        child: Text('No transactions yet.',
                            style: AdminType.body),
                      )
                    else
                      for (final p in data.recent) ...[
                        _TransactionCard(payment: p),
                        const SizedBox(height: 10),
                      ],

                    const SizedBox(height: 14),
                    AdminNavTile(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Manage Subscription Plans',
                      subtitle: 'Review and edit pricing tiers.',
                      onTap: () => Get.toNamed(AdminRoutes.subscriptions),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final PaymentRow payment;
  const _TransactionCard({required this.payment});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          const AdminIconTile(icon: Icons.school_outlined, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.schoolName ?? 'School',
                    style: AdminType.rowTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  '${_fmtDate(payment.paidAt)} • ${payment.planName ?? 'Plan'}',
                  style: AdminType.meta
                      .copyWith(fontSize: 12, color: AdminPalette.faint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '+${PaymentsView._amount(payment.amount)}',
            style: AdminType.rowTitle.copyWith(
                color: AdminPalette.positive, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
