import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/teaching_class.dart';

/// Class list card: subject tag dot + label, overflow menu, big "Grade N"
/// title, description line, students count + "View Class" CTA. Accent rail.
class ClassCard extends StatelessWidget {
  final TeachingClass item;
  final VoidCallback? onView;
  final VoidCallback? onMenu;

  const ClassCard({super.key, required this.item, this.onView, this.onMenu});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: item.accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: item.accent, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(item.subject,
                              style: AppTypography.titleMd.copyWith(
                                  color: item.accent, fontWeight: FontWeight.w700)),
                        ),
                        InkWell(
                          onTap: onMenu,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.more_vert_rounded,
                                size: 20, color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(item.grade,
                        style: AppTypography.displayLg.copyWith(fontSize: 28)),
                    const SizedBox(height: 2),
                    Text(item.description, style: AppTypography.bodyLg),
                    const SizedBox(height: AppSpacing.stackMd),
                    Row(
                      children: [
                        const Icon(Icons.people_alt_outlined,
                            size: 16, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text('${item.students} Students',
                                style: AppTypography.bodyMd)),
                        PrimaryButton(
                          label: 'View Class',
                          trailingIcon: null,
                          onPressed: onView,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
