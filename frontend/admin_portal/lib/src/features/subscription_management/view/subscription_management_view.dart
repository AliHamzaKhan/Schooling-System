import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/filter_chips.dart';
import '../../../ui/admin_widgets/status_pill.dart';
import '../../subscriptions/models/subscription_models.dart';
import '../controller/subscription_management_controller.dart';

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
            _Header(),
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
                          style: AppTypography.bodyLg));
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
    '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

class _SubscriptionCard extends StatelessWidget {
  final SchoolSubscriptionModel sub;
  const _SubscriptionCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final canManage = sub.status == SubscriptionStatus.active ||
        sub.status == SubscriptionStatus.expired;
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(sub.schoolName ?? 'School',
                    style: AppTypography.titleMd,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              StatusPill(label: sub.status.label, color: sub.status.color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${sub.planName ?? 'Plan'} · ${sub.billingPeriod.label}',
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              Icon(Icons.event_rounded,
                  size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('${_fmtDate(sub.startDate)} → ${_fmtDate(sub.endDate)}',
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant)),
              const Spacer(),
              Text(_money(sub.netAmount), style: AppTypography.titleMd),
            ],
          ),
          if (canManage) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Row(
              children: [
                Expanded(
                  child: GhostButton(
                    label: 'Renew',
                    trailingIcon: Icons.autorenew_rounded,
                    onPressed: () => Get.find<SubscriptionManagementController>()
                        .renew(sub),
                  ),
                ),
                if (sub.status == SubscriptionStatus.active) ...[
                  const SizedBox(width: AppSpacing.stackSm),
                  Expanded(
                    child: GhostButton(
                      label: 'Cancel',
                      trailingIcon: Icons.close_rounded,
                      onPressed: () =>
                          Get.find<SubscriptionManagementController>()
                              .cancel(sub),
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

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackSm,
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackLg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCEAD6), Color(0xFFF3DCE6), Color(0xFFD9CDEF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back<void>(),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.arrow_back_rounded,
                      color: AppColors.onPrimary, size: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Text('EduMaster Admin',
                  style: AppTypography.titleLg.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Subscriptions',
              style: AppTypography.displayLg
                  .copyWith(color: AppColors.primary, fontSize: 34)),
          const SizedBox(height: AppSpacing.stackSm),
          Text('Every school\'s subscription, by status.',
              style:
                  AppTypography.bodyLg.copyWith(color: AppColors.onSurface)),
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
        Icon(Icons.inbox_rounded, size: 48, color: AppColors.outline),
        SizedBox(height: AppSpacing.stackMd),
        Center(child: Text('No subscriptions here yet.')),
      ],
    );
  }
}
