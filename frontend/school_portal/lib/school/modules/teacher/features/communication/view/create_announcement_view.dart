import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../controller/create_announcement_controller.dart';
import '../../../../../widgets/skeletons.dart';

/// New Announcement — compose a message and broadcast it to a section, all
/// guardians, or all students over the chosen channel.
class CreateAnnouncementView extends StatefulWidget {
  const CreateAnnouncementView({super.key});

  @override
  State<CreateAnnouncementView> createState() => _CreateAnnouncementViewState();
}

class _CreateAnnouncementViewState extends State<CreateAnnouncementView>
    with ScreenTextControllers {
  final controller = Get.find<CreateAnnouncementController>();

  // Owned by this screen — one controller per field, disposed here.
  late final _titleCtrl = boundController(controller.title);
  late final _bodyCtrl = boundController(controller.body);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('New Announcement')),
      body: Obx(() {
        if (controller.loadingSections.value) {
          return const SkeletonPage(withHeader: false, body: SkeletonForm(fields: 4));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackMd,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackXl),
          children: [
            GlassInput(
              label: 'Title (optional)',
              hint: 'e.g. Field trip on Friday',
              controller: _titleCtrl,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            GlassInput(
              label: 'Message',
              hint: 'What do you want to tell them?',
              controller: _bodyCtrl,
            ),
            const SizedBox(height: AppSpacing.stackLg),

            Text('Send to', style: AppTypography.titleMd),
            const SizedBox(height: AppSpacing.stackSm),
            Obx(() => Column(
                  children: [
                    for (final a in AnnouncementAudience.values)
                      RadioListTile<AnnouncementAudience>(
                        value: a,
                        // ignore: deprecated_member_use — groupValue/onChanged
                        // remain the supported API on this Flutter channel.
                        groupValue: controller.audience.value,
                        onChanged: (v) =>
                            v == null ? null : controller.selectAudience(v),
                        title: Text(a.label, style: AppTypography.bodyLg),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                  ],
                )),

            // Section picker only matters when targeting one section.
            Obx(() {
              if (controller.audience.value != AnnouncementAudience.section) {
                return const SizedBox.shrink();
              }
              if (controller.sections.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.stackSm),
                  child: Text(
                    'You have no sections on your timetable to send to.',
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.error),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.stackSm),
                child: ActionDropdownField<String>(
                  label: 'Section',
                  hint: 'Choose a section',
                  value: controller.sectionId.value,
                  items: [
                    for (final s in controller.sections)
                      DropdownMenuItem(
                          value: s.sectionId, child: Text(s.title)),
                  ],
                  onChanged: controller.selectSection,
                ),
              );
            }),
            const SizedBox(height: AppSpacing.stackLg),

            Text('Channel', style: AppTypography.titleMd),
            const SizedBox(height: AppSpacing.stackSm),
            Obx(() => Wrap(
                  spacing: AppSpacing.stackSm,
                  runSpacing: AppSpacing.stackSm,
                  children: [
                    for (final c in AnnouncementChannel.values)
                      _ChannelChip(
                        channel: c,
                        selected: controller.channel.value == c,
                        onTap: () => controller.selectChannel(c),
                      ),
                  ],
                )),
            const SizedBox(height: AppSpacing.stackLg),

            Obx(() {
              final err = controller.error.value;
              if (err == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                child: Row(
                  children: [
                    const Icon(AppIcons.errorOutlineRounded,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(err,
                          style: AppTypography.bodyMd
                              .copyWith(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            }),

            Obx(() => PrimaryButton(
                  label: controller.submitting.value
                      ? 'Sending…'
                      : 'Send Announcement',
                  leadingIcon: AppIcons.campaignOutlined,
                  trailingIcon: null,
                  expanded: true,
                  onPressed: controller.submitting.value
                      ? null
                      : () async {
                          final ok = await controller.submit();
                          if (!ok) return;
                          Get.back<bool>(result: true);
                          Get.snackbar(
                            'Announcement sent',
                            'Your message is on its way.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                )),
          ],
        );
      }),
    );
  }
}

class _ChannelChip extends StatelessWidget {
  final AnnouncementChannel channel;
  final bool selected;
  final VoidCallback onTap;

  const _ChannelChip({
    required this.channel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.stackMd, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(channel.icon,
                size: 15,
                color: selected ? AppColors.onPrimary : AppColors.primary),
            const SizedBox(width: 5),
            Text(channel.label,
                style: AppTypography.labelMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}
