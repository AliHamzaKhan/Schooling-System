import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../ui/tokens/app_colors.dart';
import '../../ui/tokens/app_radius.dart';
import '../../ui/tokens/app_typography.dart';
import '../call_controller.dart';
import '../call_models.dart';
import 'call_controls.dart';
import 'participant_tile.dart';

/// A complete, drop-in live-consultation screen.
///
/// Renders the primary remote feed full-bleed, the local camera as a draggable
/// picture-in-picture tile, a status banner (connecting / waiting / timer), and
/// the [CallControls] bar. Bind it to a started [CallController]:
///
/// ```dart
/// VideoCallScreen(
///   controller: callController,
///   title: 'Consultation with Dr. Reed',
///   onHangUp: () => Get.back(),
/// )
/// ```
class VideoCallScreen extends StatelessWidget {
  final CallController controller;
  final String title;
  final VoidCallback? onHangUp;

  const VideoCallScreen({
    super.key,
    required this.controller,
    this.title = 'Live consultation',
    this.onHangUp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Primary stage: first remote participant, else a status view ──
          Positioned.fill(child: Obx(_buildStage)),

          // ── Local PiP tile (top-right, draggable) ──
          Obx(() {
            final local = controller.participants
                .firstWhereOrNull((p) => p.isLocal);
            if (local == null) return const SizedBox.shrink();
            return _DraggablePip(
              child: ParticipantTile(
                participant: local,
                engine: controller.engine,
                radius: AppRadius.md,
              ),
            );
          }),

          // ── Top status bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _StatusBar(controller: controller, title: title),
          ),

          // ── Bottom controls ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CallControls(controller: controller, onHangUp: onHangUp),
          ),
        ],
      ),
    );
  }

  Widget _buildStage() {
    final remote = controller.remoteParticipants;
    if (remote.isNotEmpty) {
      return ParticipantTile(
        participant: remote.first,
        engine: controller.engine,
        radius: 0,
      );
    }
    return _WaitingView(controller: controller);
  }
}

class _StatusBar extends StatelessWidget {
  final CallController controller;
  final String title;
  const _StatusBar({required this.controller, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.titleMd.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 2),
            Obx(() => Text(
                  _statusLabel(controller),
                  style: AppTypography.bodySm
                      .copyWith(color: Colors.white.withValues(alpha: 0.8)),
                )),
          ],
        ),
      ),
    );
  }

  String _statusLabel(CallController c) => switch (c.status.value) {
        CallStatus.connecting => 'Connecting…',
        CallStatus.waiting => 'Waiting for the other participant…',
        CallStatus.connected => c.formattedDuration,
        CallStatus.reconnecting => 'Reconnecting…',
        CallStatus.ended => 'Call ended',
        CallStatus.failed => c.error.value ?? 'Call failed',
        CallStatus.idle => '',
      };
}

class _WaitingView extends StatelessWidget {
  final CallController controller;
  const _WaitingView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.inverseSurface,
      child: Center(
        child: Obx(() {
          final failed = controller.status.value == CallStatus.failed;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                failed ? Icons.error_outline : Icons.videocam,
                size: 56,
                color: failed ? AppColors.error : Colors.white70,
              ),
              const SizedBox(height: 16),
              Text(
                failed
                    ? (controller.error.value ?? 'Unable to connect')
                    : 'Waiting for the other participant to join',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: Colors.white70),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// A small draggable picture-in-picture container for the local preview.
class _DraggablePip extends StatefulWidget {
  final Widget child;
  const _DraggablePip({required this.child});

  @override
  State<_DraggablePip> createState() => _DraggablePipState();
}

class _DraggablePipState extends State<_DraggablePip> {
  Offset _offset = const Offset(16, 64);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const w = 110.0, h = 160.0;
    return Positioned(
      right: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onPanUpdate: (d) => setState(() {
          final nx = (_offset.dx - d.delta.dx).clamp(8.0, size.width - w - 8);
          final ny = (_offset.dy + d.delta.dy).clamp(48.0, size.height - h - 120);
          _offset = Offset(nx, ny);
        }),
        child: SizedBox(width: w, height: h, child: widget.child),
      ),
    );
  }
}
