import 'package:flutter/material.dart';

import '../../ui/tokens/app_colors.dart';
import '../../ui/tokens/app_radius.dart';
import '../../ui/tokens/app_typography.dart';
import '../call_models.dart';
import '../video_call_engine.dart';

/// Renders a single participant's video feed (or an avatar placeholder when
/// their camera is off), with a name label and a muted-mic indicator overlaid.
///
/// Pass the [engine] so the tile can pull the right native video surface —
/// the local preview for [CallParticipant.isLocal], or the remote view keyed
/// by [CallParticipant.uid].
class ParticipantTile extends StatelessWidget {
  final CallParticipant participant;
  final VideoCallEngine engine;
  final double radius;

  const ParticipantTile({
    super.key,
    required this.participant,
    required this.engine,
    this.radius = AppRadius.card,
  });

  @override
  Widget build(BuildContext context) {
    final showVideo = participant.videoEnabled;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showVideo)
            participant.isLocal
                ? engine.localPreview()
                : engine.remoteView(participant.uid)
          else
            _AvatarPlaceholder(name: participant.name),

          // Name + mic indicator chip.
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    participant.audioEnabled ? Icons.mic : Icons.mic_off,
                    size: 14,
                    color: participant.audioEnabled
                        ? Colors.white
                        : AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    participant.name.isEmpty
                        ? (participant.isLocal ? 'You' : 'Participant')
                        : participant.name,
                    style: AppTypography.bodySm.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  final String name;
  const _AvatarPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return ColoredBox(
      color: AppColors.surfaceContainerHighest,
      child: Center(
        child: CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.primaryContainer,
          child: Text(
            initial,
            style: AppTypography.headlineLg.copyWith(color: AppColors.onPrimary),
          ),
        ),
      ),
    );
  }
}
