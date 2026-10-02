import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// A campus overview banner shown at the top of every role's home page: a wide
/// image with the school/campus name laid over it.
///
/// The image is headmaster-managed. When the backend supplies a campus image
/// URL ([imageUrl]) it is used; otherwise the bundled [assetFallback] is shown
/// (drop the campus photo at `assets/images/campus.jpg`). A dark gradient scrim
/// keeps the name legible over any photo.
class CampusHeroBanner extends StatelessWidget {
  /// School / campus name laid over the image.
  final String name;

  /// Optional network URL for a headmaster-uploaded campus photo. Takes
  /// precedence over [assetFallback] when non-empty.
  final String? imageUrl;

  /// Bundled fallback image used until a campus photo is uploaded.
  final String assetFallback;

  /// Small line above the name (e.g. "Campus"). Hidden when empty.
  final String eyebrow;

  final double height;

  const CampusHeroBanner({
    super.key,
    required this.name,
    this.imageUrl,
    this.assetFallback = 'assets/images/campus.jpg',
    this.eyebrow = 'Campus',
    this.height = 168,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final ImageProvider image =
        url.isNotEmpty ? schoolImage(url) : AssetImage(assetFallback);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The campus photo. A neutral fill shows if the asset is missing.
            Image(
              image: image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: AppColors.primary),
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const ColoredBox(color: AppColors.primary),
            ),
            // Bottom-up scrim so the name stays readable over any image.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x59000000),
                    Color(0xCC0F1530),
                  ],
                  stops: [0.35, 0.7, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow.isNotEmpty)
                    Text(
                      eyebrow.toUpperCase(),
                      style: AppTypography.labelCaps.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 1.2,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineLgMobile.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      shadows: const [
                        Shadow(color: Color(0x99000000), blurRadius: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
