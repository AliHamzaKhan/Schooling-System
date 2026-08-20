import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../components/notification_card.dart';
import '../controller/notifications_controller.dart';
import '../../../../../widgets/skeletons.dart';

/// Notifications Center — title + new-alerts count, then a card per
/// notification (assignment / exam result / school announcement).
class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          PortalTopBar(
            title: 'Meri Taleem',
            onBell: () => Get.back<void>(),
            actions: [
              IconButton(
                onPressed: () => Get.back<void>(),
                icon: const Icon(AppIcons.arrowBackRounded, color: AppColors.primary),
              ),
            ],
          ),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const SkeletonPage(withHeader: false, body: SkeletonThreadList());
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  Text('Notifications Center',
                      style: AppTypography.displayLg.copyWith(fontSize: 32)),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text('You have ${controller.newCount} new alerts to check.',
                      style: AppTypography.bodyLg),
                  const SizedBox(height: AppSpacing.stackLg),
                  for (var i = 0; i < controller.items.length; i++) ...[
                    NotificationCard(item: controller.items[i]),
                    const SizedBox(height: AppSpacing.stackMd),
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
