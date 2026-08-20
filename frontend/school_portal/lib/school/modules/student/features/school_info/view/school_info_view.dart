import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/skeletons.dart';
import '../controller/school_info_controller.dart';
import '../models/school_info_models.dart';

/// "My School" — the public school profile: about us, achievements, the school
/// uniform, and contact details. Content is authored by the headmaster.
class SchoolInfoView extends GetView<SchoolInfoController> {
  const SchoolInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('My School')),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 4, height: 120));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        final info = controller.info.value;
        if (info == null) {
          return Center(
              child: Text('No school information yet.',
                  style: AppTypography.bodyLg));
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackLg,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackXxl),
            children: [
              Text(info.name, style: AppTypography.headlineLg),
              const SizedBox(height: AppSpacing.stackLg),

              if ((info.about ?? '').isNotEmpty) ...[
                _Section(
                  icon: AppIcons.infoOutlineRounded,
                  title: 'About Us',
                  child: Text(info.about!,
                      style: AppTypography.bodyLg.copyWith(height: 1.5)),
                ),
                const SizedBox(height: AppSpacing.stackMd),
              ],

              if (info.achievements.isNotEmpty) ...[
                _Section(
                  icon: AppIcons.emojiEventsOutlined,
                  title: 'Achievements',
                  child: Column(
                    children: [
                      for (var i = 0; i < info.achievements.length; i++) ...[
                        _AchievementRow(item: info.achievements[i]),
                        if (i != info.achievements.length - 1)
                          const Divider(height: AppSpacing.stackLg),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
              ],

              _Section(
                icon: AppIcons.checkroomRounded,
                title: 'School Uniform',
                child: _Uniform(url: info.uniformImageUrl),
              ),
              const SizedBox(height: AppSpacing.stackMd),

              _Section(
                icon: AppIcons.contactPageOutlined,
                title: 'Contact Us',
                child: Column(
                  children: [
                    if ((info.address ?? '').isNotEmpty)
                      _ContactRow(icon: AppIcons.locationOnOutlined, value: info.address!),
                    if ((info.contactPhone ?? '').isNotEmpty)
                      _ContactRow(icon: AppIcons.callOutlined, value: info.contactPhone!),
                    if ((info.contactEmail ?? '').isNotEmpty)
                      _ContactRow(icon: AppIcons.mailOutlineRounded, value: info.contactEmail!),
                    if ((info.address ?? '').isEmpty &&
                        (info.contactPhone ?? '').isEmpty &&
                        (info.contactEmail ?? '').isEmpty)
                      Text('No contact details provided.',
                          style: AppTypography.bodyMd
                              .copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Section({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(title, style: AppTypography.titleMd
                  .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          child,
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final SchoolAchievement item;
  const _AchievementRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(AppIcons.militaryTechOutlined,
            size: 20, color: Color(0xFFE8A317)),
        const SizedBox(width: AppSpacing.stackMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.title,
                        style: AppTypography.bodyLg
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                  if ((item.year ?? '').isNotEmpty)
                    Text(item.year!,
                        style: AppTypography.labelMd
                            .copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
              if ((item.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(item.description!, style: AppTypography.bodyMd),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Uniform extends StatelessWidget {
  final String? url;
  const _Uniform({required this.url});

  void _viewFull(BuildContext context, String resolved) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 4,
              child: Center(child: Image.network(resolved)),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(AppIcons.closeRounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if ((url ?? '').isEmpty) {
      return Row(
        children: [
          const Icon(AppIcons.imageNotSupportedOutlined,
              size: 18, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text('The school uniform image has not been uploaded yet.',
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
        ],
      );
    }
    final resolved = EnvConfig.mediaUrl(url!);
    return GestureDetector(
      onTap: () => _viewFull(context, resolved),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Image.network(
          resolved,
          width: double.infinity,
          height: 240,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator())),
          errorBuilder: (_, _, _) => Container(
            height: 160,
            alignment: Alignment.center,
            color: AppColors.surfaceContainerLow,
            child: Text('Could not load the uniform image.',
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _ContactRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(child: SelectableText(value, style: AppTypography.bodyLg)),
        ],
      ),
    );
  }
}
