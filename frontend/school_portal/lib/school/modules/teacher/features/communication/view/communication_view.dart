import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/filter_chips.dart';
import '../../../../../widgets/portal_search_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../components/message_thread_row.dart';
import '../controller/communication_controller.dart';

/// Communication Center — manage conversations with parents, students, and
/// staff. Header + New Announcement CTA + search + party filter chips + list.
class CommunicationView extends GetView<CommunicationController> {
  const CommunicationView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortalTopBar(title: 'Teacher Portal', onBell: () => Get.back<void>()),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  Text('Communication\nCenter',
                      style: AppTypography.headlineLg.copyWith(color: AppColors.primary)),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text('Manage conversations with parents, students, and staff.',
                      style: AppTypography.bodyLg),
                  const SizedBox(height: AppSpacing.stackMd),
                  PrimaryButton(
                    label: 'New Announcement',
                    leadingIcon: Icons.campaign_outlined,
                    trailingIcon: null,
                    onPressed: () {},
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  PortalSearchField(
                    hint: 'Search messages…',
                    onChanged: controller.onSearch,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  FilterChips(
                    options: CommunicationController.filters,
                    selectedIndex: controller.filterIndex.value,
                    onSelected: controller.selectFilter,
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  for (var i = 0; i < controller.threads.length; i++) ...[
                    MessageThreadRow(
                        thread: controller.threads[i], onTap: () {}),
                    if (i != controller.threads.length - 1)
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
