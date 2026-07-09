import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// One labelled row inside an [showEntityDetailSheet].
class DetailField {
  final IconData icon;
  final String label;
  final String value;
  const DetailField(this.icon, this.label, this.value);
}

/// A shared, read-only "profile" bottom sheet used by the roster screens
/// (teachers / students / guardians) to back the previously-dead "View" / menu
/// card actions. Renders an avatar header, an optional status pill, a list of
/// [fields], and an optional set of related [chips] (e.g. linked students).
Future<void> showEntityDetailSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  required String initials,
  Color accent = AppColors.primary,
  String? statusLabel,
  Color? statusColor,
  List<DetailField> fields = const [],
  String? chipsLabel,
  List<String> chips = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackMd,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: accent.withValues(alpha: 0.18),
                  child: Text(initials,
                      style: AppTypography.titleLg.copyWith(color: accent)),
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTypography.headlineLg.copyWith(fontSize: 22)),
                      if (subtitle != null)
                        Text(subtitle, style: AppTypography.bodyMd),
                    ],
                  ),
                ),
                if (statusLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (statusColor ?? AppColors.primary)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(statusLabel,
                        style: AppTypography.labelMd.copyWith(
                            color: statusColor ?? AppColors.primary,
                            fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
            if (fields.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.stackLg),
              for (final f in fields) ...[
                Row(
                  children: [
                    Icon(f.icon, size: 18, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.stackSm),
                    Text('${f.label}: ',
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant)),
                    Expanded(
                      child: Text(f.value,
                          style: AppTypography.bodyLg
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackSm),
              ],
            ],
            if (chips.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.stackSm),
              if (chipsLabel != null) ...[
                Text(chipsLabel,
                    style: AppTypography.labelCaps
                        .copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 6),
              ],
              Wrap(
                spacing: AppSpacing.stackSm,
                runSpacing: AppSpacing.stackSm,
                children: [
                  for (final c in chips)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(c, style: AppTypography.labelMd),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
