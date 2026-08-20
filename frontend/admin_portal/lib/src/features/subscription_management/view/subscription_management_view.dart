import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/admin_confirm_dialog.dart';
import '../../../ui/admin_widgets/filter_chips.dart';
import '../../../ui/admin_widgets/status_pill.dart';
import '../../subscriptions/models/subscription_models.dart';
import '../controller/subscription_management_controller.dart';
import '../../../ui/admin_theme.dart';
import '../../../ui/admin_widgets/admin_page_header.dart';
import '../../../ui/admin_widgets/admin_surface.dart';

/// Subscription Management — every school's subscription instance, filtered by
/// the All / Active / Pending / History tabs. Opened from the dashboard's
/// "Active Subscriptions" KPI card.
class SubscriptionManagementView
    extends GetView<SubscriptionManagementController> {
  const SubscriptionManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      safeArea: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminScreenHeader(title: 'Subscriptions'),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackMd,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackSm,
              ),
              child: Obx(() => FilterChips(
                    options: SubscriptionManagementController.tabs,
                    selectedIndex: controller.tabIndex.value,
                    onSelected: controller.selectTab,
                  )),
            ),
            Expanded(
              child: Obx(() {
                if (controller.loading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.error.value != null) {
                  return Center(
                      child: Text(controller.error.value!,
                          style: AdminType.body));
                }
                if (controller.subscriptions.isEmpty) {
                  return const _EmptyState();
                }
                return RefreshIndicator(
                  onRefresh: controller.fetch,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerPaddingMobile,
                      AppSpacing.stackMd,
                      AppSpacing.containerPaddingMobile,
                      AppSpacing.stackXl,
                    ),
                    itemCount: controller.subscriptions.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.stackMd),
                    itemBuilder: (context, i) => _SubscriptionCard(
                      sub: controller.subscriptions[i],
                    ),
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

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _money(double v) =>
    v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

/// Confirms then renews the subscription for another billing period.
Future<void> _confirmRenew(SchoolSubscriptionModel sub) async {
  final ok = await showAdminConfirm(
    icon: AppIcons.autorenewRounded,
    title: 'Renew subscription?',
    message:
        'This extends ${sub.schoolName ?? 'the school'}\'s subscription for another '
        '${sub.billingPeriod.label.toLowerCase()} term and records a payment of '
        '${_money(sub.netAmount)}.',
    confirmLabel: 'Renew',
    details: [
      AdminConfirmDetail(label: 'School', value: sub.schoolName ?? '—'),
      AdminConfirmDetail(label: 'Plan', value: sub.planName ?? '—'),
      AdminConfirmDetail(label: 'Amount', value: _money(sub.netAmount)),
    ],
  );
  if (!ok) return;
  await Get.find<SubscriptionManagementController>().renew(sub);
}

/// Confirms then cancels the subscription (destructive).
Future<void> _confirmCancel(SchoolSubscriptionModel sub) async {
  final ok = await showAdminConfirm(
    icon: AppIcons.closeRounded,
    title: 'Cancel subscription?',
    message:
        '${sub.schoolName ?? 'This school'}\'s subscription will be cancelled and the '
        'school may lose access to its features. This cannot be undone — you would '
        'need to assign a new subscription to restore access.',
    confirmLabel: 'Cancel subscription',
    cancelLabel: 'Keep it',
    destructive: true,
    details: [
      AdminConfirmDetail(label: 'School', value: sub.schoolName ?? '—'),
      AdminConfirmDetail(label: 'Plan', value: sub.planName ?? '—'),
    ],
  );
  if (!ok) return;
  await Get.find<SubscriptionManagementController>().cancel(sub);
}

class _SubscriptionCard extends StatelessWidget {
  final SchoolSubscriptionModel sub;
  const _SubscriptionCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final canManage = sub.status == SubscriptionStatus.active ||
        sub.status == SubscriptionStatus.expired;
    return AdminCard(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(sub.schoolName ?? 'School',
                    style: AdminType.rowTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              StatusPill(label: sub.status.label, color: sub.status.color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${sub.planName ?? 'Plan'} · ${sub.billingPeriod.label}',
            style: AdminType.body
                .copyWith(color: AdminPalette.muted),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              Icon(AppIcons.eventRounded,
                  size: 16, color: AdminPalette.muted),
              const SizedBox(width: 6),
              Text('${_fmtDate(sub.startDate)} → ${_fmtDate(sub.endDate)}',
                  style: AdminType.meta
                      .copyWith(color: AdminPalette.muted)),
              const Spacer(),
              Text(_money(sub.netAmount), style: AdminType.rowTitle),
            ],
          ),
          if (canManage) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Row(
              children: [
                Expanded(
                  child: GhostButton(
                    label: 'Renew',
                    trailingIcon: AppIcons.autorenewRounded,
                    onPressed: () => _confirmRenew(sub),
                  ),
                ),
                if (sub.status == SubscriptionStatus.active) ...[
                  const SizedBox(width: AppSpacing.stackSm),
                  Expanded(
                    child: GhostButton(
                      label: 'Cancel',
                      trailingIcon: AppIcons.closeRounded,
                      onPressed: () => _confirmCancel(sub),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 80),
        Icon(AppIcons.inboxRounded, size: 48, color: AdminPalette.faint),
        SizedBox(height: AppSpacing.stackMd),
        Center(child: Text('No subscriptions here yet.')),
      ],
    );
  }
}
