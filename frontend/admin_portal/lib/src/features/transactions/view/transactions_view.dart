import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/admin_metrics.dart';
import '../../../ui/admin_theme.dart';
import '../../../ui/admin_widgets/admin_surface.dart';
import '../controller/transactions_controller.dart';
import 'package:shared/shared.dart';

/// Transactions — the full payment ledger opened from the "View All" link on
/// the billing overview. A range filter (This month / This year / All time)
/// drives a progress chart and, beneath it, the transaction listing.
class TransactionsView extends GetView<TransactionsController> {
  const TransactionsView({super.key});

  static String _money(double v) =>
      v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  static String _amount(double v) =>
      v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return AdminScreen(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, kAdminGutter, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Get.back<void>(),
                    icon: const Icon(AppIcons.arrowBackRounded,
                        color: AdminPalette.ink),
                  ),
                  Text('Transactions',
                      style: AdminType.cardTitle.copyWith(
                          color: AdminPalette.ink, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.loading.value && controller.report.value == null) {
                  return const Center(
                      child: CircularProgressIndicator(color: AdminPalette.ink));
                }
                if (controller.error.value != null &&
                    controller.report.value == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(controller.error.value!,
                          textAlign: TextAlign.center, style: AdminType.body),
                    ),
                  );
                }
                final data = controller.report.value;
                return RefreshIndicator(
                  onRefresh: controller.load,
                  color: AdminPalette.ink,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                    const EdgeInsets.fromLTRB(kAdminGutter, 4, kAdminGutter, 36),
                    children: [
                      _RangeFilter(
                        range: controller.range.value,
                        onSelect: controller.selectRange,
                      ),
                      const SizedBox(height: 18),
                      if (data != null) ...[
                        _ChartCard(
                          report: data,
                          moneyOf: _money,
                        ),
                        const SizedBox(height: 20),
                        Text('All Transactions',
                            style: AdminType.sectionTitle),
                        const SizedBox(height: 4),
                        Text(
                          '${data.count} payment${data.count == 1 ? '' : 's'} • ${_money(data.total)}',
                          style: AdminType.meta.copyWith(color: AdminPalette.muted),
                        ),
                        const SizedBox(height: 14),
                        if (data.transactions.isEmpty)
                          AdminCard(
                            padding: const EdgeInsets.all(20),
                            child: Text('No transactions in this range.',
                                style: AdminType.body),
                          )
                        else
                          for (final p in data.transactions) ...[
                            _TransactionCard(payment: p, amountOf: _amount),
                            const SizedBox(height: 10),
                          ],
                      ],
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented range selector: This month / This year / All time.
class _RangeFilter extends StatelessWidget {
  final String range;
  final ValueChanged<String> onSelect;
  const _RangeFilter({required this.range, required this.onSelect});

  static const _options = [
    ('month', 'This Month'),
    ('year', 'This Year'),
    ('all', 'All Time'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AdminPalette.tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final (value, label) in _options)
            Expanded(
              child: AccessibleTap(
                onTap: () => onSelect(value),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: range == value ? AdminPalette.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: AdminType.label.copyWith(
                      color: range == value ? Colors.white : AdminPalette.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Revenue progress chart: one vertical bar per bucket in the selected range.
class _ChartCard extends StatelessWidget {
  final TransactionsReport report;
  final String Function(double) moneyOf;
  const _ChartCard({required this.report, required this.moneyOf});

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Compact axis label from a bucket key: day-of-month for "YYYY-MM-DD",
  /// month name for "YYYY-MM".
  String _axisLabel(String key) {
    final parts = key.split('-');
    if (parts.length == 3) return parts[2]; // day
    if (parts.length == 2) {
      final mi = int.tryParse(parts[1]) ?? 0;
      if (mi >= 1 && mi <= 12) return _monthNames[mi - 1];
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final buckets = report.buckets;
    final maxTotal = buckets.fold<double>(0, (a, b) => b.total > a ? b.total : a);
    // Thin the axis labels when there are many buckets, so they don't collide.
    final step = buckets.length <= 12 ? 1 : (buckets.length / 8).ceil();

    return AdminCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue', style: AdminType.meta.copyWith(color: AdminPalette.muted)),
          const SizedBox(height: 2),
          Text(moneyOf(report.total),
              style: AdminType.metric.copyWith(fontSize: 30)),
          const SizedBox(height: 18),
          if (buckets.isEmpty)
            SizedBox(
              height: 120,
              child: Center(
                child: Text('No revenue in this range.',
                    style: AdminType.body.copyWith(color: AdminPalette.muted)),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < buckets.length; i++)
                    Expanded(
                      child: _Bar(
                        fraction: maxTotal <= 0 ? 0 : buckets[i].total / maxTotal,
                        label: i % step == 0 ? _axisLabel(buckets[i].label) : '',
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double fraction;
  final String label;
  const _Bar({required this.fraction, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: fraction.clamp(0.02, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AdminPalette.info, AdminPalette.ink],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 14,
            child: Text(
              label,
              style: AdminType.meta
                  .copyWith(fontSize: 10, color: AdminPalette.faint),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final PaymentRow payment;
  final String Function(double) amountOf;
  const _TransactionCard({required this.payment, required this.amountOf});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _fmtDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          const AdminIconTile(icon: AppIcons.schoolOutlined, size: 40),
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
            '+${amountOf(payment.amount)}',
            style: AdminType.rowTitle.copyWith(
                color: AdminPalette.positive, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
