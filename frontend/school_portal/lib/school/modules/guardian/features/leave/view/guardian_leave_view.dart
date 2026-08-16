import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/leave_review.dart';
import '../../../../../widgets/portal_form_field.dart';
import '../../../../../widgets/skeletons.dart';
import '../controller/guardian_leave_controller.dart';

/// Guardian: submit a leave application for a child and track its status.
class GuardianLeaveView extends GetView<GuardianLeaveController> {
  const GuardianLeaveView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Leave Application')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Apply'),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 3, height: 130));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackMd,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackXxl),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.stackSm),
                    Expanded(
                      child: Text(
                        "Applications go to your child's class teacher and the headmaster.",
                        style: AppTypography.bodySm,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              if (controller.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.stackXl),
                  child: Center(
                    child: Text('No leave applications yet.\nTap Apply to submit one.',
                        textAlign: TextAlign.center, style: AppTypography.bodyLg),
                  ),
                )
              else
                for (final l in controller.items) ...[
                  LeaveReviewCard(item: l),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
            ],
          ),
        );
      }),
    );
  }

  void _openForm(BuildContext context) {
    if (controller.children.isEmpty) {
      Get.snackbar('No children', 'No linked children to apply for.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    controller.resetForm();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _SubmitSheet(controller: controller),
    );
  }
}

class _SubmitSheet extends StatefulWidget {
  final GuardianLeaveController controller;
  const _SubmitSheet({required this.controller});

  @override
  State<_SubmitSheet> createState() => _SubmitSheetState();
}

class _SubmitSheetState extends State<_SubmitSheet> with ScreenTextControllers {
  GuardianLeaveController get controller => widget.controller;

  // Owned by this sheet — created with it, disposed with it.
  late final _reasonCtrl = boundController(controller.reason);

  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final now = DateTime.now();
    final initial =
        (isStart ? controller.startDate.value : controller.endDate.value) ??
            controller.startDate.value ??
            now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    if (isStart) {
      controller.startDate.value = picked;
      final end = controller.endDate.value;
      if (end != null && end.isBefore(picked)) controller.endDate.value = picked;
    } else {
      controller.endDate.value = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.containerPaddingMobile,
        right: AppSpacing.containerPaddingMobile,
        top: AppSpacing.stackSm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.stackLg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Leave Application', style: AppTypography.titleLg),
            const SizedBox(height: AppSpacing.stackLg),

            Text('Child',
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.stackSm),
            Obx(() => Wrap(
                  spacing: AppSpacing.stackSm,
                  runSpacing: AppSpacing.stackSm,
                  children: [
                    for (final c in controller.children)
                      ChoiceChip(
                        label: Text(c.name),
                        selected: controller.childId.value == c.id,
                        onSelected: (_) => controller.childId.value = c.id,
                      ),
                  ],
                )),
            const SizedBox(height: AppSpacing.stackLg),

            Text('Type',
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.stackSm),
            Obx(() => Wrap(
                  spacing: AppSpacing.stackSm,
                  children: [
                    for (final t in GuardianLeaveController.leaveTypes)
                      ChoiceChip(
                        label: Text(t[0].toUpperCase() + t.substring(1)),
                        selected: controller.leaveType.value == t,
                        onSelected: (_) => controller.leaveType.value = t,
                      ),
                  ],
                )),
            const SizedBox(height: AppSpacing.stackLg),

            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'From',
                    read: () => controller.startDate.value,
                    onTap: () => _pickDate(context, isStart: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: _DateField(
                    label: 'To',
                    read: () => controller.endDate.value,
                    onTap: () => _pickDate(context, isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackLg),

            PortalFormField(
              label: 'Reason (optional)',
              hint: 'Briefly explain the reason for leave…',
              controller: _reasonCtrl,
              maxLines: 3,
            ),

            Obx(() {
              final err = controller.formError.value;
              if (err == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.stackMd),
                child: Text(err,
                    style:
                        AppTypography.bodyMd.copyWith(color: AppColors.error)),
              );
            }),
            const SizedBox(height: AppSpacing.stackLg),

            Obx(() => PrimaryButton(
                  label: 'Submit Application',
                  leadingIcon: Icons.send_rounded,
                  expanded: true,
                  isLoading: controller.submitting.value,
                  onPressed: () async {
                    final ok = await controller.submit();
                    if (ok && context.mounted) {
                      Navigator.of(context).pop();
                      Get.snackbar('Submitted',
                          'The leave application was sent for approval.',
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? Function() read;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.read, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelMd
                .copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.stackSm),
        Obx(() {
          final d = read();
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    d == null ? 'Select' : GuardianLeaveController.fmt(d),
                    style: AppTypography.bodyMd.copyWith(
                        color: d == null
                            ? AppColors.onSurfaceVariant
                            : AppColors.onSurface),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
