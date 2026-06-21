import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/announcement.dart';

/// One announcement row: scope pill + timestamp, title, body, optional author
/// chip, CTA link, or attachment chip. Status-colored left rail.
class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback? onCta;
  final VoidCallback? onAttachment;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onCta,
    this.onAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: a.scope.color,
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
                        _ScopePill(scope: a.scope),
                        const SizedBox(width: AppSpacing.stackSm),
                        Text(a.timestamp, style: AppTypography.bodySm),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(a.title, style: AppTypography.headlineLg.copyWith(fontSize: 22)),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(a.body, style: AppTypography.bodyLg),
                    if (a.author != null) ...[
                      const Divider(height: AppSpacing.stackLg, color: AppColors.outlineVariant),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFF8D6E63),
                            child: Icon(Icons.person, size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: AppSpacing.stackSm),
                          Text(a.author!,
                              style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                    if (a.ctaLabel != null) ...[
                      const SizedBox(height: AppSpacing.stackMd),
                      GestureDetector(
                        onTap: onCta,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              a.ctaLabel!,
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ],
                    if (a.attachment != null) ...[
                      const SizedBox(height: AppSpacing.stackMd),
                      _AttachmentChip(
                        filename: a.attachment!.filename,
                        onTap: onAttachment,
                      ),
                    ],
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

class _ScopePill extends StatelessWidget {
  final AnnouncementScope scope;
  const _ScopePill({required this.scope});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scope.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(scope.icon, size: 13, color: scope.color),
          const SizedBox(width: 5),
          Text(scope.label,
              style: AppTypography.labelMd.copyWith(color: scope.color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final String filename;
  final VoidCallback? onTap;
  const _AttachmentChip({required this.filename, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.attach_file_rounded, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.stackSm),
              Expanded(
                child: Text(filename,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              const Icon(Icons.download_rounded, size: 18, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
