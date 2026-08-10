import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../app/admin_routes.dart';
import '../../../../ui/admin_widgets/status_pill.dart';
import '../../../subscriptions/models/subscription_models.dart';
import '../../components/subscription_sheet.dart';
import '../../controller/schools_controller.dart';
import '../../models/payment_mode.dart';
import '../../models/school.dart';
import '../controller/school_detail_controller.dart';
import '../models/school_detail_models.dart';

/// School Detail — profile, active-user stats, current subscription (plan +
/// expiry), the recorded payment mode, and the payment/transaction ledger.
class SchoolDetailView extends GetView<SchoolDetailController> {
  const SchoolDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.error.value != null) {
                return _ErrorState(
                    message: controller.error.value!, onRetry: controller.load);
              }
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerPaddingMobile,
                      0,
                      AppSpacing.containerPaddingMobile,
                      AppSpacing.stackXl),
                  children: [
                    _ProfileCard(school: controller.school),
                    const SizedBox(height: AppSpacing.stackLg),
                    _StatsGrid(stats: controller.stats.value),
                    const SizedBox(height: AppSpacing.stackLg),
                    _SubscriptionCard(controller: controller),
                    const SizedBox(height: AppSpacing.stackLg),
                    _PaymentModeCard(school: controller.school),
                    const SizedBox(height: AppSpacing.stackLg),
                    _TransactionsCard(payments: controller.payments),
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

class _Header extends GetView<SchoolDetailController> {
  Future<void> _openSubscription() =>
      showSubscriptionSheet(controller.school, onChanged: controller.load);

  Future<void> _openEdit() async {
    final saved = await Get.toNamed<dynamic>(
      AdminRoutes.createSchool,
      arguments: controller.school,
    );
    if (saved == true) await controller.load();
  }

  Future<void> _toggleStatus() async {
    final s = controller.school;
    final schools = Get.isRegistered<SchoolsController>()
        ? Get.find<SchoolsController>()
        : null;
    if (s.status == SchoolStatus.active) {
      final ok = await schools?.deleteSchool(s.id) ?? false;
      if (ok) {
        Get.snackbar('Deactivated', '${s.name} was suspended.',
            snackPosition: SnackPosition.BOTTOM);
        Get.back<void>(); // list changed; return to it
      }
    } else {
      final ok = await schools?.activateSchool(s.id) ?? false;
      if (ok) {
        Get.snackbar('Activated', '${s.name} is now active.',
            snackPosition: SnackPosition.BOTTOM);
        Get.back<void>();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = controller.school;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.stackSm, AppSpacing.stackSm,
          AppSpacing.containerPaddingMobile, AppSpacing.stackSm),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back<void>(),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          ),
          Expanded(
            child: Text(s.name,
                style: AppTypography.headlineLg.copyWith(color: AppColors.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.onSurfaceVariant),
            onSelected: (v) {
              if (v == 'edit') _openEdit();
              if (v == 'subscription') _openSubscription();
              if (v == 'status') _toggleStatus();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit profile')),
              ),
              const PopupMenuItem(
                value: 'subscription',
                child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.card_membership_outlined),
                    title: Text('Change subscription')),
              ),
              PopupMenuItem(
                value: 'status',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                      s.status == SchoolStatus.active
                          ? Icons.block_rounded
                          : Icons.check_circle_outline_rounded,
                      color: s.status == SchoolStatus.active
                          ? AppColors.error
                          : AppColors.primary),
                  title: Text(
                      s.status == SchoolStatus.active ? 'Deactivate' : 'Activate',
                      style: TextStyle(
                          color: s.status == SchoolStatus.active
                              ? AppColors.error
                              : AppColors.primary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final School school;
  const _ProfileCard({required this.school});

  @override
  Widget build(BuildContext context) {
    final uniform = _hexColor(school.uniformColor);
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Logo(school: school),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(school.name, style: AppTypography.titleLg),
                    if (school.code.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(school.code, style: AppTypography.bodyMd),
                    ],
                  ],
                ),
              ),
              StatusPill(
                  label: school.status.label,
                  color: school.status.color,
                  icon: Icons.circle),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          if ((school.contactEmail ?? '').isNotEmpty)
            _InfoRow(icon: Icons.email_outlined, text: school.contactEmail!),
          if ((school.contactPhone ?? '').isNotEmpty)
            _InfoRow(icon: Icons.phone_outlined, text: school.contactPhone!),
          if ((school.address ?? '').isNotEmpty)
            _InfoRow(icon: Icons.location_on_outlined, text: school.address!),
          if (uniform != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.stackSm),
              child: Row(
                children: [
                  const Icon(Icons.checkroom_outlined,
                      size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.stackSm),
                  Text('Uniform', style: AppTypography.bodyMd),
                  const SizedBox(width: AppSpacing.stackSm),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: uniform,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.outlineVariant),
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

class _StatsGrid extends StatelessWidget {
  final SchoolStats? stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final tiles = <Widget>[
      _StatTile(
          icon: Icons.school_outlined,
          label: 'Students',
          value: s?.students,
          color: AppColors.primary),
      _StatTile(
          icon: Icons.co_present_outlined,
          label: 'Teachers',
          value: s?.teachers,
          color: AppColors.tertiary),
      _StatTile(
          icon: Icons.family_restroom_outlined,
          label: 'Guardians',
          value: s?.guardians,
          color: const Color(0xFFE8A317)),
      _StatTile(
          icon: Icons.groups_outlined,
          label: 'Total users',
          value: s?.totalUsers,
          color: AppColors.aiAccent),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.stackMd,
      crossAxisSpacing: AppSpacing.stackMd,
      childAspectRatio: 2.4,
      children: tiles,
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? value;
  final Color color;
  const _StatTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value?.toString() ?? '—',
                    style: AppTypography.titleLg.copyWith(fontWeight: FontWeight.w700)),
                Text(label, style: AppTypography.bodyMd, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SchoolDetailController controller;
  const _SubscriptionCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final sub = controller.subscription.value;
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_membership_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.stackSm),
              Text('Subscription',
                  style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () => showSubscriptionSheet(controller.school,
                    onChanged: controller.load),
                child: const Text('Change'),
              ),
            ],
          ),
          if (sub == null)
            Text('No subscription assigned.',
                style: AppTypography.bodyLg.copyWith(color: AppColors.onSurfaceVariant))
          else ...[
            _KV(k: 'Plan', v: sub.planName ?? '—'),
            _KV(k: 'Billing', v: sub.billingPeriod.label),
            _KV(
              k: 'Status',
              vWidget: StatusPill(
                  label: sub.status.label, color: sub.status.color, icon: Icons.circle),
            ),
            _KV(k: 'Started', v: _fmtDate(sub.startDate)),
            _KV(
              k: 'Expires',
              v: '${_fmtDate(sub.endDate)}  ·  ${_expiryLabel(controller.daysRemaining)}',
            ),
            _KV(k: 'Amount', v: _money(sub.netAmount)),
          ],
        ],
      ),
    );
  }
}

class _PaymentModeCard extends StatelessWidget {
  final School school;
  const _PaymentModeCard({required this.school});

  @override
  Widget build(BuildContext context) {
    final b = school.billing;
    final hasAny = b.isNotEmpty && b.values.any((v) => '$v'.trim().isNotEmpty);
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_outlined,
                  size: 18, color: Color(0xFFE8A317)),
              const SizedBox(width: AppSpacing.stackSm),
              Text('Payment mode',
                  style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    Get.toNamed<dynamic>(AdminRoutes.createSchool, arguments: school),
                child: const Text('Edit'),
              ),
            ],
          ),
          if (!hasAny)
            Text('No payment arrangement recorded yet.',
                style: AppTypography.bodyLg.copyWith(color: AppColors.onSurfaceVariant))
          else ...[
            _KV(k: 'Method', v: PaymentMode.label(b['method'] as String?)),
            if (_s(b['bank_name']).isNotEmpty) _KV(k: 'Bank', v: _s(b['bank_name'])),
            if (_s(b['account_title']).isNotEmpty)
              _KV(k: 'Account title', v: _s(b['account_title'])),
            if (_s(b['account_number']).isNotEmpty)
              _KV(k: 'Account no.', v: _s(b['account_number'])),
            if (_s(b['notes']).isNotEmpty) _KV(k: 'Notes', v: _s(b['notes'])),
          ],
        ],
      ),
    );
  }

  static String _s(Object? v) => v == null ? '' : '$v'.trim();
}

class _TransactionsCard extends StatelessWidget {
  final List<SchoolPayment> payments;
  const _TransactionsCard({required this.payments});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.stackSm),
              Text('Transactions',
                  style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${payments.length}', style: AppTypography.bodyMd),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          if (payments.isEmpty)
            Text('No payments recorded yet.',
                style: AppTypography.bodyLg.copyWith(color: AppColors.onSurfaceVariant))
          else
            for (final p in payments) ...[
              _PaymentRow(payment: p),
              if (p != payments.last)
                const Divider(height: AppSpacing.stackLg, color: AppColors.outlineVariant),
            ],
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final SchoolPayment payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_money(payment.amount),
                    style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                    '${payment.planName ?? 'Subscription'} · '
                    '${_fmtDate(payment.periodStart)} – ${_fmtDate(payment.periodEnd)}',
                    style: AppTypography.bodyMd),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(
                  label: payment.status,
                  color: payment.status == 'paid'
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant),
              const SizedBox(height: 2),
              Text(_fmtDate(payment.paidAt), style: AppTypography.bodyMd),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Small shared bits ───────────────────────────────────────────

class _KV extends StatelessWidget {
  final String k;
  final String? v;
  final Widget? vWidget;
  const _KV({required this.k, this.v, this.vWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: AppTypography.bodyMd),
          ),
          Expanded(
            child: vWidget ??
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(v ?? '—',
                      style: AppTypography.bodyLg
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.stackSm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(child: Text(text, style: AppTypography.bodyLg)),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final School school;
  const _Logo({required this.school});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.button),
        image: school.logoUrl != null
            ? DecorationImage(image: NetworkImage(school.logoUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: school.logoUrl == null
          ? Text(school.initial,
              style: AppTypography.titleLg.copyWith(color: AppColors.onSurfaceVariant))
          : null,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.containerPaddingMobile),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.stackMd),
            Text(message, textAlign: TextAlign.center, style: AppTypography.bodyLg),
            const SizedBox(height: AppSpacing.stackMd),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────

Color? _hexColor(String? hex) {
  if (hex == null) return null;
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String _fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

String _expiryLabel(int? days) {
  if (days == null) return '';
  if (days < 0) return 'expired';
  if (days == 0) return 'expires today';
  return '$days days left';
}

String _money(double v) =>
    '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
