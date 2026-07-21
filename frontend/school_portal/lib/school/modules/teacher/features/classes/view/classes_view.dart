import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../components/class_card.dart';
import '../controller/classes_controller.dart';
import '../models/my_class.dart';
import '../../../../../widgets/skeletons.dart';

/// My Classes — the sections this teacher actually takes, one per row.
class ClassesView extends GetView<TeacherClassesController> {
  /// Opens the detail screen for a section.
  final ValueChanged<MyClass>? onOpenClass;

  const ClassesView({super.key, this.onOpenClass});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalTopBar(title: 'Teacher Portal'),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonPage(body: SkeletonCardList(count: 5, height: 104, gap: AppSpacing.stackSm));
            }
            final items = controller.classes;
            return RefreshIndicator(
              onRefresh: controller.load,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.containerPaddingMobile,
                        0,
                        AppSpacing.containerPaddingMobile,
                        AppSpacing.stackLg),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Classes',
                              style:
                                  AppTypography.displayLg.copyWith(fontSize: 32)),
                          const SizedBox(height: AppSpacing.stackSm),
                          Text(
                            items.isEmpty
                                ? 'Sections you teach will appear here.'
                                : '${items.length} section${items.length == 1 ? '' : 's'} on your timetable.',
                            style: AppTypography.bodyLg,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (controller.error.value != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _Message(
                        icon: Icons.cloud_off_rounded,
                        text: controller.error.value!,
                        onRetry: controller.load,
                      ),
                    )
                  else if (items.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _Message(
                        icon: Icons.class_outlined,
                        text: 'No sections are timetabled to you yet.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.containerPaddingMobile,
                          0,
                          AppSpacing.containerPaddingMobile,
                          AppSpacing.stackXl),
                      // One card per row, each sized by its own content — a
                      // fixed-height grid clipped long subject lists.
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.stackSm),
                        itemBuilder: (context, i) => ClassCard(
                          item: items[i],
                          onTap: () => onOpenClass?.call(items[i]),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;
  const _Message({required this.icon, required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.stackXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: AppColors.outline),
          const SizedBox(height: AppSpacing.stackMd),
          Text(text, style: AppTypography.bodyLg, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.stackMd),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ],
      ),
    );
  }
}
