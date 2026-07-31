import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/student_routes.dart';
import '../models/course_models.dart';

/// A single course: pick a reading track — the Book (chapters) or the Notes.
class CourseDetailView extends StatelessWidget {
  const CourseDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final course = Get.arguments as Course;
    return AppScaffold(
      appBar: AppBar(title: Text(course.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackLg,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackXl),
        children: [
          if ((course.subject ?? '').isNotEmpty)
            Text(course.subject!,
                style: AppTypography.labelCaps
                    .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.stackSm),
          Text(course.title, style: AppTypography.headlineLg),
          if ((course.description ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Text(course.description!, style: AppTypography.bodyLg),
          ],
          const SizedBox(height: AppSpacing.stackXl),
          _TrackTile(
            icon: Icons.auto_stories_rounded,
            title: 'Book',
            subtitle: course.bookCount == 0
                ? 'No book added yet'
                : 'Read by chapter'
                    '${course.bookCount > 1 ? ' · ${course.bookCount} books' : ''}',
            accent: AppColors.primary,
            enabled: course.bookCount > 0,
            onTap: () =>
                Get.toNamed(StudentRoutes.courseBook, arguments: course),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _TrackTile(
            icon: Icons.sticky_note_2_outlined,
            title: 'Notes',
            subtitle: course.noteCount == 0
                ? 'No notes added yet'
                : '${course.noteCount} '
                    '${course.noteCount == 1 ? 'note' : 'notes'} to read',
            accent: AppColors.tertiary,
            enabled: course.noteCount > 0,
            onTap: () =>
                Get.toNamed(StudentRoutes.courseNotes, arguments: course),
          ),
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;
  const _TrackTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GlassSurface(
        onTap: enabled ? onTap : null,
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Icon(icon, color: accent, size: 26),
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.titleLg
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            if (enabled)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
