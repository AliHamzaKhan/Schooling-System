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
    // The accent rail is drawn as a left border so it stretches to the card's
    // height without IntrinsicHeight — IntrinsicHeight cannot measure the
    // TextFields these cards contain and throws a layout assertion
    // ("RenderBox was not laid out").
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accent, width: 5)),
        ),
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
    );
  }
}
