import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_form_field.dart';
import '../../../../../widgets/skeletons.dart';
import '../controller/leave_controller.dart';
import '../models/leave_models.dart';

/// Student Leave Applications — a list of the student's own requests and their
/// review status, plus a compose form. Requests are routed to the student's
/// class teacher and the headmaster for approval.
class LeaveView extends GetView<LeaveController> {
  const LeaveView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Leave Application')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSubmitSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Apply'),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 4, height: 104));
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
              _RoutingHint(),
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
                  _LeaveCard(leave: l),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
            ],
          ),
        );
      }),
    );
  }

  void _openSubmitSheet(BuildContext context) {
    controller.resetForm();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _SubmitSheet(controller: controller),
    );
  }
}

class _RoutingHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
              'Applications go to your class teacher and the headmaster for approval.',
              style: AppTypography.bodySm,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveRequest leave;
  const _LeaveCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    final range = leave.startDate == leave.endDate
        ? leave.startDate
        : '${leave.startDate}  →  ${leave.endDate}';
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if ((leave.leaveType ?? '').isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(_titleCase(leave.leaveType!),
                      style: AppTypography.labelMd),
                ),
              const Spacer(),
              _StatusChip(status: leave.status),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              const Icon(Icons.event_rounded,
                  size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(range, style: AppTypography.bodyLg),
            ],
          ),
          if ((leave.reason ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Text(leave.reason!, style: AppTypography.bodyMd),
          ],
          if ((leave.reviewNote ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.stackSm),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text('Note: ${leave.reviewNote!}',
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant)),
            ),
          ],
        ],
      ),
    );
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _StatusChip extends StatelessWidget {
  final LeaveStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Text(status.label,
              style: AppTypography.labelMd
                  .copyWith(color: status.color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SubmitSheet extends StatelessWidget {
  final LeaveController controller;
  const _SubmitSheet({required this.controller});

  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final now = DateTime.now();
    final initial = (isStart ? controller.startDate.value : controller.endDate.value) ??
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
      // Keep end >= start.
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

            Text('Type',
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.stackSm),
            Obx(() => Wrap(
                  spacing: AppSpacing.stackSm,
                  children: [
                    for (final t in LeaveController.leaveTypes)
                      ChoiceChip(
                        label: Text(_titleCase(t)),
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
                    valueListenable: () => controller.startDate.value,
                    onTap: () => _pickDate(context, isStart: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: _DateField(
                    label: 'To',
                    valueListenable: () => controller.endDate.value,
                    onTap: () => _pickDate(context, isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackLg),

            PortalFormField(
              label: 'Reason (optional)',
              hint: 'Briefly explain the reason for leave…',
              controller: controller.reasonCtrl,
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
                          'Your leave application was sent for approval.',
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? Function() valueListenable;
  final VoidCallback onTap;
  const _DateField({
    required this.label,
    required this.valueListenable,
    required this.onTap,
  });

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
          final d = valueListenable();
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
                    d == null ? 'Select' : LeaveController.fmt(d),
                    style: AppTypography.bodyMd.copyWith(
                        color:
                            d == null ? AppColors.onSurfaceVariant : AppColors.onSurface),
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
