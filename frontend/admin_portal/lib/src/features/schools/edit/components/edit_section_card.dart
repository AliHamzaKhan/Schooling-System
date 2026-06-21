import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Glass card with an accent left rail and a section title — the building block
/// for the Edit School form sections (Basic Details, Contact & Location, …).
class EditSectionCard extends StatelessWidget {
  final String title;
  final Color accent;
  final List<Widget> children;

  const EditSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.accent = AppColors.primary,
  });

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
                color: accent,
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
                    Text(title, style: AppTypography.headlineLg.copyWith(fontSize: 22)),
                    const SizedBox(height: AppSpacing.stackMd),
                    ...children,
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
