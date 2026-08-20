import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../widgets/portal_filter_button.dart';
import '../../../../../widgets/portal_search_field.dart';
import '../components/student_card.dart';
import '../controller/students_controller.dart';
import '../models/student.dart';
import '../../../../../widgets/skeletons.dart';

/// Student Roster — search + filter sheet, status legend, paginated student
/// cards, with enrolment on a bottom-anchored action button.
class StudentsView extends GetView<StudentsController> {
  const StudentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(),
              Expanded(child: _list(context)),
            ],
          ),
          Positioned(
            right: AppSpacing.stackLg,
            bottom: AppSpacing.stackLg,
            child: FloatingActionButton.extended(
              onPressed: controller.enrollStudentFlow,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              icon: const Icon(AppIcons.personAddAlt1Rounded),
              label: const Text('Enroll Student'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const SkeletonPage(withHeader: false, body: SkeletonRosterList());
      }
      final items = controller.pageItems;
      return ListView(
        // Bottom padding clears the floating "Enroll Student" button.
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            0,
            AppSpacing.containerPaddingMobile,
            120),
        children: [
          Row(
            children: [
              Expanded(
                child: PortalSearchField(
                  hint: 'Search by name or roll number…',
                  onChanged: controller.onSearch,
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              PortalFilterButton(
                onTap: controller.openFilter,
                count: controller.activeFilterCount,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Wrap(
            spacing: AppSpacing.stackMd,
            runSpacing: 6,
            children: [
              for (final s in StudentStatus.values) _LegendDot(status: s),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.stackXl),
              child: Center(
                child: Text('No students match your filters.',
                    style: AppTypography.bodyLg),
              ),
            )
          else
            for (final s in items) ...[
              StudentCard(
                student: s,
                // Card tap → the 360° student report, which carries the full
                // profile; the old overflow menu only duplicated the card, so
                // it was removed.
                onTap: () => Get.toNamed(HeadmasterRoutes.studentReport,
                    arguments: s.id),
              ),
              const SizedBox(height: AppSpacing.stackLg),
            ],
          _Pager(
            page: controller.page.value,
            total: controller.totalPages,
            onChanged: controller.goToPage,
          ),
        ],
      );
    });
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackMd,
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back<void>(),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(AppIcons.person, color: AppColors.onPrimary, size: 20),
                ),
              ),
              const Spacer(),
              const Icon(AppIcons.notificationsNoneRounded, color: AppColors.onSurface),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Student Roster',
              style: AppTypography.headlineLg.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.stackSm),
          Text('Manage and monitor student profiles across the island.',
              style: AppTypography.bodyLg),
          const SizedBox(height: AppSpacing.stackMd),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final StudentStatus status;
  const _LegendDot({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 9, height: 9,
            decoration: BoxDecoration(color: status.color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(status.label, style: AppTypography.bodyMd),
      ],
    );
  }
}

class _Pager extends StatelessWidget {
  final int page;
  final int total;
  final ValueChanged<int> onChanged;

  const _Pager({required this.page, required this.total, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 1 ? () => onChanged(page - 1) : null,
          icon: const Icon(AppIcons.chevronLeftRounded),
        ),
        for (var i = 1; i <= total; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: i == page ? AppColors.primary : AppColors.surfaceContainerLowest,
                shape: BoxShape.circle,
              ),
              child: Text('$i',
                  style: AppTypography.labelMd.copyWith(
                    color: i == page ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                  )),
            ),
          ),
        IconButton(
          onPressed: page < total ? () => onChanged(page + 1) : null,
          icon: const Icon(AppIcons.chevronRightRounded),
        ),
      ],
    );
  }
}
