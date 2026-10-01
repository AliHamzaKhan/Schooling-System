import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/filter_chips.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../controller/notification_controller.dart';
import '../models/notification_item.dart';
import '../../../../../widgets/skeletons.dart';

/// Notifications Center — the alert/notification UI system. Severity-coloured
/// alert cards, an All/Unread filter, and mark-all-read. Used both as a tab
/// and as a drill-in route (with a back button via [AppScaffold]).
class NotificationView extends GetView<NotificationController> {
  /// When true the screen wraps itself in [AppScaffold] (drill-in usage). As a
  /// tab it is embedded directly, so the shell provides the scaffold.
  final bool standalone;
  const NotificationView({super.key, this.standalone = false});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        PortalTopBar(
          title: 'Notifications',
          showAvatar: !standalone,
          actions: [
            Obx(() => controller.unreadCount == 0
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: controller.markAllRead,
                    child: Text('Mark all read',
                        style: AppTypography.labelMd
                            .copyWith(color: AppColors.primary)),
                  )),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackSm,
              AppSpacing.containerPaddingMobile,
              0),
          child: Obx(() => FilterChips(
                options: ['All', 'Unread (${controller.unreadCount})'],
                selectedIndex: controller.filterIndex.value,
                onSelected: controller.setFilter,
              )),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonPage(withHeader: false, body: SkeletonThreadList());
            }
            final items = controller.visible;
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AppIcons.notificationsOffOutlined,
                        size: 40, color: AppColors.outline),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text('You\'re all caught up',
                        style: AppTypography.titleMd),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  0,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.stackSm),
              itemBuilder: (context, i) => _AlertCard(
                item: items[i],
                onTap: () => controller.markRead(items[i].id),
              ),
            );
          }),
        ),
      ],
    );

    if (standalone) return AppScaffold(body: content);
    return content;
  }
}

class _AlertCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;
  const _AlertCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = item.level.color;
    return AccessibleTap(
      onTap: onTap,
      child: GlassSurface(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        fill: !item.read ? color.withValues(alpha: 0.06) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(item.level.icon, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.title,
                            style: AppTypography.titleMd.copyWith(
                                fontWeight: FontWeight.w800)),
                      ),
                      if (!item.read)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(item.body, style: AppTypography.bodyMd),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (item.childName != null) ...[
                        Text(item.childName!,
                            style: AppTypography.labelMd.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                        Text('  ·  ',
                            style: AppTypography.labelMd.copyWith(
                                color: AppColors.onSurfaceVariant)),
                      ],
                      Text(item.timeAgo,
                          style: AppTypography.labelMd.copyWith(
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
