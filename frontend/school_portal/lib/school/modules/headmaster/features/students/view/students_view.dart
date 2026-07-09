import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../widgets/entity_detail_sheet.dart';
import '../../../../../widgets/portal_search_field.dart';
import '../components/student_card.dart';
import '../controller/students_controller.dart';
import '../models/student.dart';

/// Student Roster — search + grade/section dropdowns, status legend, paginated
/// student cards.
class StudentsView extends GetView<StudentsController> {
  const StudentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(),
          Expanded(child: _list(context)),
        ],
      ),
    );
  }

  void _showStudent(BuildContext context, Student s) {
    showEntityDetailSheet(
      context,
      title: s.name,
      subtitle: 'Roll ${s.roll}',
      initials: s.initials,
      accent: s.status.color,
      statusLabel: s.status.label,
      statusColor: s.status.color,
      fields: [
        DetailField(Icons.confirmation_number_outlined, 'Roll', s.roll),
        DetailField(Icons.school_outlined, 'Grade', s.grade),
        DetailField(Icons.class_outlined, 'Section', s.section),
      ],
    );
  }

  Widget _list(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final items = controller.pageItems;
      return ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            0,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackXl),
        children: [
          _Filters(controller: controller),
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
                // Card tap → the 360° student report; the menu keeps the
                // quick-view sheet.
                onTap: () => Get.toNamed(HeadmasterRoutes.studentReport,
                    arguments: s.id),
                onMenu: () => _showStudent(context, s),
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
                  child: Icon(Icons.person, color: AppColors.onPrimary, size: 20),
                ),
              ),
              const Spacer(),
              const Icon(Icons.notifications_none_rounded, color: AppColors.onSurface),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Student Roster',
              style: AppTypography.headlineLg.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.stackSm),
          Text('Manage and monitor student profiles across the island.',
              style: AppTypography.bodyLg),
          const SizedBox(height: AppSpacing.stackMd),
          PrimaryButton(
            label: 'Enroll Student',
            leadingIcon: Icons.person_add_alt_1_rounded,
            trailingIcon: null,
            expanded: true,
            onPressed: () => Get.find<StudentsController>().enrollStudentFlow(),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final StudentsController controller;
  const _Filters({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search Students', style: AppTypography.titleMd),
          const SizedBox(height: AppSpacing.stackSm),
          PortalSearchField(
            hint: 'Search by name or roll number…',
            onChanged: controller.onSearch,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              Expanded(
                child: _Dropdown(
                  label: 'Grade',
                  value: controller.grade.value,
                  items: StudentsController.grades,
                  onChanged: controller.selectGrade,
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: _Dropdown(
                  label: 'Section',
                  value: controller.section.value,
                  items: StudentsController.sections,
                  onChanged: controller.selectSection,
                ),
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
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodyMd),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.onSurfaceVariant),
          style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
          ),
          items: [
            for (final it in items)
              DropdownMenuItem<String>(value: it, child: Text(it)),
          ],
          onChanged: onChanged,
        ),
      ],
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
          icon: const Icon(Icons.chevron_left_rounded),
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
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
