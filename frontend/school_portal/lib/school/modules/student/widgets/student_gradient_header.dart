import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// A vibrant, playful greeting header for the STUDENT pages.
///
/// Students respond to colour, so their home leads with a bright gradient card
/// (rather than the app's flat white identity card) carrying the greeting and,
/// on the right, an illustration slot — pass a Lottie animation or a vector via
/// [illustration]; when null a friendly fallback glyph is shown so the header
/// still looks finished before the asset lands.
class StudentGradientHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? avatarUrl;

  /// Right-side artwork — a `Lottie.asset(...)` or `SvgPicture.asset(...)`.
  /// Sized by the header to ~96px. Null → a fallback glyph.
  final Widget? illustration;

  const StudentGradientHeader({
    super.key,
    required this.name,
    required this.subtitle,
    this.avatarUrl,
    this.illustration,
  });

  // Playful indigo → violet → pink. Kept local to the student module so it
  // doesn't leak into the white+navy theme the other roles use.
  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4436B5), Color(0xFF6252D9), Color(0xFF8973EF)],
  );

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x335B5BF0),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR LEARNING SPACE',
                    style: AppTypography.labelCaps.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hey, ${name.trim().isEmpty ? 'there' : name.trim().split(' ').first}!',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineLg.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A little curious.\nA little better, every day.',
                    style: AppTypography.bodyLg.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMd.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.stackMd),
            SizedBox(
              width: 96,
              height: 96,
              child: illustration ?? const _FallbackArt(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown until a Lottie/vector [StudentGradientHeader.illustration] is provided:
/// a soft translucent disc with a graduation glyph, so the header never looks
/// broken or empty.
class _FallbackArt extends StatelessWidget {
  const _FallbackArt();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 1200),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.rotate(
        angle: -.12 * value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .12),
            ),
          ),
          Positioned(
            bottom: 9,
            left: 8,
            child: _book(const Color(0xFFFFB5AC), 78),
          ),
          Positioned(
            bottom: 31,
            left: 14,
            child: _book(const Color(0xFF7DE0CC), 74),
          ),
          Positioned(
            bottom: 53,
            left: 5,
            child: _book(const Color(0xFFFFDC85), 82),
          ),
          const Positioned(
            top: 0,
            right: 0,
            child: Icon(Icons.star_rounded, color: Color(0xFFFFDC85), size: 24),
          ),
        ],
      ),
    );
  }

  Widget _book(Color color, double width) => Container(
    width: width,
    height: 22,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18000000),
          offset: Offset(0, 3),
          blurRadius: 6,
        ),
      ],
    ),
    child: Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: width - 12,
        height: 12,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF4),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    ),
  );
}
