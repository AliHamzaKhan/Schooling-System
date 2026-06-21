import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../components/feature_module_card.dart';
import '../controller/feature_access_controller.dart';

/// Feature Access Control Panel — platform-wide feature flags grouped by
/// module, each with an enable/disable switch. A summary card shows how many
/// of the available features are currently on.
class FeatureAccessView extends GetView<FeatureAccessController> {
  const FeatureAccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminTopBar(
            title: 'Feature Access',
            showAvatar: false,
            actions: [
              IconButton(
                onPressed: () => Get.back<void>(),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.onSurface),
              ),
            ],
          ),
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
                  Text('Feature Control', style: AppTypography.headlineLg),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text(
                      'Enable or disable platform capabilities. Changes apply '
                      'across all schools immediately.',
                      style: AppTypography.bodyLg),
                  const SizedBox(height: AppSpacing.stackLg),
                  _SummaryCard(
                    enabled: controller.enabledCount,
                    total: controller.totalCount,
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  for (var i = 0; i < controller.modules.length; i++) ...[
                    FeatureModuleCard(
                      module: controller.modules[i],
                      onToggle: (key, v) => controller.toggle(i, key, v),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
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

class _SummaryCard extends StatelessWidget {
  final int enabled;
  final int total;
  const _SummaryCard({required this.enabled, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : enabled / total;
    return GlassSurface(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active features', style: AppTypography.bodyLg),
                const SizedBox(height: 4),
                Text('$enabled of $total',
                    style: AppTypography.displayLg.copyWith(fontSize: 32)),
                const SizedBox(height: AppSpacing.stackSm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Icon(Icons.toggle_on_outlined,
              size: 44, color: AppColors.primary.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}
