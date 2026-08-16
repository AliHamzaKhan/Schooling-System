import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../models/module_models.dart';
import '../controller/school_modules_controller.dart';
import '../../../../ui/admin_theme.dart';
import '../../../../ui/admin_widgets/admin_surface.dart';

/// Per-school module editor. Lists every platform module grouped by area, each
/// with a switch. Modules the school's plan doesn't include are shown disabled
/// with a "Not in plan" hint — they must be unlocked by changing the plan.
class SchoolModulesEditorView extends GetView<SchoolModulesController> {
  const SchoolModulesEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.stackSm, AppSpacing.stackSm,
                AppSpacing.containerPaddingMobile, AppSpacing.stackSm),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Get.back<void>(),
                  icon: const Icon(Icons.arrow_back_rounded, color: AdminPalette.ink),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(controller.school.name,
                          style: AdminType.screenTitle
                              .copyWith(color: AdminPalette.ink)),
                      Text('Module permissions', style: AdminType.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.error.value != null) {
                return _ErrorState(
                    message: controller.error.value!, onRetry: controller.load);
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.containerPaddingMobile,
                    0, AppSpacing.containerPaddingMobile, AppSpacing.stackXl),
                children: [
                  _SummaryCard(
                    active: controller.activeCount,
                    total: controller.totalCount,
                    planCode: controller.planCode.value,
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  for (final group in ModuleCatalog.groups) ...[
                    _GroupCard(group: group),
                    const SizedBox(height: AppSpacing.stackLg),
                  ],
                ],
              );
            }),
          ),
          _SaveBar(),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int active;
  final int total;
  final String? planCode;
  const _SummaryCard({required this.active, required this.total, this.planCode});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : active / total;
    return AdminCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    planCode == null
                        ? 'No plan assigned'
                        : 'Plan: ${planCode!.toUpperCase()}',
                    style: AdminType.body),
                const SizedBox(height: 4),
                Text('$active of $total active',
                    style: AdminType.metric.copyWith(fontSize: 32)),
                const SizedBox(height: AppSpacing.stackSm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: AdminPalette.tint,
                    valueColor: const AlwaysStoppedAnimation(AdminPalette.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Icon(Icons.grid_view_rounded,
              size: 44, color: AdminPalette.ink.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

class _GroupCard extends GetView<SchoolModulesController> {
  final ModuleGroup group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(group.icon, size: 20, color: group.color),
              const SizedBox(width: AppSpacing.stackSm),
              Text(group.title,
                  style: AdminType.rowTitle.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          for (final meta in group.modules)
            Obx(() {
              final status = controller.statuses[meta.key];
              if (status == null) return const SizedBox.shrink();
              return _ModuleRow(
                meta: meta,
                inPlan: status.inPlan,
                enabled: status.toggleEnabled,
                onChanged: (v) => controller.toggle(meta.key, v),
              );
            }),
        ],
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  final ModuleMeta meta;
  final bool inPlan;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ModuleRow({
    required this.meta,
    required this.inPlan,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final muted = !inPlan;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(meta.icon,
              size: 22,
              color: muted ? AdminPalette.muted : AdminPalette.ink),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(meta.label,
                          style: AdminType.rowTitle.copyWith(
                              color: muted
                                  ? AdminPalette.muted
                                  : AdminPalette.ink)),
                    ),
                    if (!inPlan) ...[
                      const SizedBox(width: AppSpacing.stackSm),
                      const _NotInPlanChip(),
                    ],
                  ],
                ),
                if (meta.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(meta.subtitle, style: AdminType.body),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Switch(
            value: inPlan && enabled,
            onChanged: inPlan ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _NotInPlanChip extends StatelessWidget {
  const _NotInPlanChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AdminPalette.tint,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text('Not in plan',
          style: AdminType.label.copyWith(color: AdminPalette.muted)),
    );
  }
}

class _SaveBar extends GetView<SchoolModulesController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loading.value || controller.error.value != null) {
        return const SizedBox.shrink();
      }
      final canSave = controller.hasChanges && !controller.saving.value;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.containerPaddingMobile,
              AppSpacing.stackSm, AppSpacing.containerPaddingMobile, AppSpacing.stackMd),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: canSave ? controller.save : null,
              child: controller.saving.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(controller.hasChanges ? 'Save changes' : 'No changes'),
            ),
          ),
        ),
      );
    });
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
            const Icon(Icons.cloud_off_rounded, size: 40, color: AdminPalette.muted),
            const SizedBox(height: AppSpacing.stackMd),
            Text(message, textAlign: TextAlign.center, style: AdminType.body),
            const SizedBox(height: AppSpacing.stackMd),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
