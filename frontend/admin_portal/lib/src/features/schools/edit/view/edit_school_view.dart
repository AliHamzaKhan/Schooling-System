import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../components/general_info_tab.dart';
import '../components/subscription_details_tab.dart';
import '../controller/edit_school_controller.dart';

/// Edit School Profile — header with Discard/Save, a two-tab switcher, and the
/// active tab's form.
class EditSchoolView extends GetView<EditSchoolController> {
  const EditSchoolView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.stackSm, AppSpacing.stackSm, AppSpacing.containerPaddingMobile, 0),
            child: GestureDetector(
              onTap: () => Get.back<void>(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('Back to Schools List',
                      style: AppTypography.labelMd.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile, AppSpacing.stackSm, AppSpacing.containerPaddingMobile, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit School Profile', style: AppTypography.headlineLg),
                const SizedBox(height: 2),
                Text('${controller.school.name} • ID: ${controller.school.id}',
                    style: AppTypography.bodyMd),
                const SizedBox(height: AppSpacing.stackMd),
                Row(
                  children: [
                    Expanded(
                      child: GhostButton(
                          label: 'Discard Changes', expanded: true, onPressed: controller.discard),
                    ),
                    const SizedBox(width: AppSpacing.stackMd),
                    Expanded(
                      child: Obx(() => PrimaryButton(
                            label: 'Save School',
                            expanded: true,
                            trailingIcon: null,
                            isLoading: controller.saving.value,
                            onPressed: controller.save,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Obx(() => _Tabs(
                      current: controller.tab.value,
                      onChanged: controller.selectTab,
                    )),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Expanded(
            child: Obx(() => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerPaddingMobile, 0, AppSpacing.containerPaddingMobile, AppSpacing.stackXl),
                  child: controller.tab.value == 0
                      ? GeneralInfoTab(controller: controller)
                      : const SubscriptionDetailsTab(),
                )),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  const _Tabs({required this.current, required this.onChanged});

  static const _labels = ['General Info', 'Subscription Details'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == current ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    _labels[i],
                    style: AppTypography.labelMd.copyWith(
                      color: i == current ? AppColors.onPrimary : AppColors.onSurfaceVariant,
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
