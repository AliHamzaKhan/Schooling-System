import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_search_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../components/teacher_card.dart';
import '../controller/teachers_controller.dart';

/// Teacher Roster — search + filter teachers with quick-contact actions and an
/// "Add Teacher" FAB.
class TeachersView extends GetView<TeachersController> {
  const TeachersView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PortalTopBar(),
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
                        120),
                    children: [
                      Text('Teacher Roster',
                          style: AppTypography.displayLg
                              .copyWith(fontSize: 32, color: AppColors.primary)),
                      const SizedBox(height: AppSpacing.stackSm),
                      Text("Manage your island's educators and staff.",
                          style: AppTypography.bodyLg),
                      const SizedBox(height: AppSpacing.stackMd),
                      Row(
                        children: [
                          Expanded(
                            child: PortalSearchField(
                              hint: 'Search by name or dept…',
                              onChanged: controller.onSearch,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.stackSm),
                          _FilterButton(onTap: () {}),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      if (controller.results.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.stackXl),
                          child: Center(
                            child: Text('No teachers match your search.',
                                style: AppTypography.bodyLg),
                          ),
                        )
                      else
                        for (final t in controller.results) ...[
                          TeacherCard(
                            teacher: t,
                            onView: () {},
                            onMail: () {},
                            onChat: () {},
                          ),
                          const SizedBox(height: AppSpacing.stackLg),
                        ],
                    ],
                  );
                }),
              ),
            ],
          ),
          Positioned(
            right: AppSpacing.stackLg,
            bottom: AppSpacing.stackLg,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.outlineVariant, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Filter',
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
