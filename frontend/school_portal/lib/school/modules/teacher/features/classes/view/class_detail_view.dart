import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/teacher_routes.dart';
import '../models/my_class.dart';

/// Single-section detail reached by tapping a class card. Shows the section
/// identity, the subjects taught to it, roster size, and the per-class actions
/// laid out as a 2-column grid.
class ClassDetailView extends StatelessWidget {
  const ClassDetailView({super.key});

  MyClass get _class {
    final arg = Get.arguments;
    return arg is MyClass ? arg : _fallback;
  }

  static const _fallback = MyClass(
    sectionId: '',
    className: 'Class',
    sectionName: '',
    studentCount: 0,
    subjects: [],
    periodsPerWeek: 0,
  );

  @override
  Widget build(BuildContext context) {
    final c = _class;
    final accent = c.isClassTeacher ? AppColors.primary : AppColors.tertiary;
    return AppScaffold(
      appBar: AppBar(title: const Text('Class Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackMd,
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackXl,
        ),
        children: [
          Text(c.title, style: AppTypography.displayLg.copyWith(fontSize: 30)),
          if (c.isClassTeacher) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Row(
              children: [
                Icon(AppIcons.starRounded, size: 16, color: accent),
                const SizedBox(width: 4),
                Text(
                  "You're the class teacher",
                  style: AppTypography.bodyMd.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          if (c.subjects.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Wrap(
              spacing: AppSpacing.stackSm,
              runSpacing: AppSpacing.stackSm,
              children: [
                for (final s in c.subjects)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.stackSm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Text(s, style: AppTypography.labelMd),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.stackLg),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: AppIcons.peopleAltOutlined,
                  value: '${c.studentCount}',
                  label: 'Students',
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: _Stat(
                  icon: AppIcons.scheduleRounded,
                  value: '${c.periodsPerWeek}',
                  label: 'Periods / week',
                ),
              ),
            ],
          ),
          if (c.room != null) ...[
            const SizedBox(height: AppSpacing.stackMd),
            _Stat(
              icon: AppIcons.locationOnOutlined,
              value: c.room!,
              label: 'Room',
            ),
          ],
          const SizedBox(height: AppSpacing.stackLg),
          Text('Actions', style: AppTypography.titleLg),
          const SizedBox(height: AppSpacing.stackMd),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.stackMd,
            crossAxisSpacing: AppSpacing.stackMd,
            childAspectRatio: 1.35,
            children: [
              _ActionTile(
                icon: AppIcons.peopleAltOutlined,
                label: 'View Students',
                color: AppColors.primary,
                onTap: () => Get.toNamed(
                  '${TeacherRoutes.sectionStudents}?section_id=${Uri.encodeComponent(c.sectionId)}&title=${Uri.encodeComponent(c.title)}',
                ),
              ),
              _ActionTile(
                icon: AppIcons.gradingOutlined,
                label: 'Open Gradebook',
                color: AppColors.tertiary,
                onTap: () => Get.toNamed(TeacherRoutes.gradebook),
              ),
              _ActionTile(
                icon: AppIcons.campaignOutlined,
                label: 'Message Class',
                color: AppColors.aiAccent,
                onTap: () => Get.toNamed(TeacherRoutes.chat),
              ),
              _ActionTile(
                icon: AppIcons.eventNoteRounded,
                label: 'Schedule',
                color: AppColors.secondary,
                onTap: () => Get.toNamed(TeacherRoutes.calendar),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLg.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(label, style: AppTypography.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
