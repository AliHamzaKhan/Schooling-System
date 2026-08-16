import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// A person's photo, with their initials as the fallback.
///
/// Two things every avatar in the app needs and none of them should re-solve:
///
/// * **Relative URLs.** The local storage backend returns host-relative paths
///   (`/media/avatars/…`), which `NetworkImage` cannot load on its own —
///   [EnvConfig.mediaUrl] resolves them against the API host.
/// * **A fallback that survives failure.** A photo that 404s, or a user who
///   never uploaded one, both land on initials rather than a broken-image icon
///   or an empty grey square.
class ProfileAvatar extends StatelessWidget {
  /// Absolute or host-relative photo URL. Null/empty renders initials.
  final String? url;

  /// Used for the initials fallback.
  final String name;

  final double size;

  /// Null renders a circle; pass a radius for a rounded square.
  final double? cornerRadius;

  /// Tint for the initials fallback, so a card that colour-codes its people
  /// keeps doing so. Defaults to the primary colour.
  final Color? accent;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.url,
    this.size = 48,
    this.cornerRadius,
    this.accent,
  });

  /// First letters of the first two words: "Test High Student" → "TH".
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  BorderRadius get _radius => cornerRadius == null
      ? BorderRadius.circular(size / 2)
      : BorderRadius.circular(cornerRadius!);

  Widget _initials() => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: (accent ?? AppColors.primary).withValues(alpha: 0.12),
          borderRadius: _radius,
        ),
        child: Text(
          initialsOf(name),
          style: AppTypography.titleLg.copyWith(
            color: accent ?? AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.36,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final resolved = EnvConfig.mediaUrl(url?.trim() ?? '');
    if (resolved.isEmpty) return _initials();
    return ClipRRect(
      borderRadius: _radius,
      child: Image.network(
        resolved,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _initials(),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _initials(),
      ),
    );
  }
}
