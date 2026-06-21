import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../ui/tokens/app_colors.dart';
import '../call_controller.dart';

/// The bottom control bar for a live call: mic, camera, speaker, flip, and the
/// red hang-up button. Fully reactive — bind it to a [CallController] and it
/// reflects the live mute/camera state.
class CallControls extends StatelessWidget {
  final CallController controller;

  /// Called after the controller ends the call (e.g. to pop the route).
  final VoidCallback? onHangUp;

  const CallControls({super.key, required this.controller, this.onHangUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Obx(() => _CircleButton(
                  icon: controller.isMicMuted.value
                      ? Icons.mic_off
                      : Icons.mic,
                  active: !controller.isMicMuted.value,
                  tooltip: 'Mute',
                  onTap: controller.toggleMic,
                )),
            Obx(() => _CircleButton(
                  icon: controller.isCameraOff.value
                      ? Icons.videocam_off
                      : Icons.videocam,
                  active: !controller.isCameraOff.value,
                  tooltip: 'Camera',
                  onTap: controller.toggleCamera,
                )),
            Obx(() => _CircleButton(
                  icon: controller.isSpeakerOn.value
                      ? Icons.volume_up
                      : Icons.volume_off,
                  active: controller.isSpeakerOn.value,
                  tooltip: 'Speaker',
                  onTap: controller.toggleSpeaker,
                )),
            _CircleButton(
              icon: Icons.cameraswitch,
              active: true,
              tooltip: 'Flip camera',
              onTap: controller.switchCamera,
            ),
            _CircleButton(
              icon: Icons.call_end,
              active: true,
              tooltip: 'End call',
              background: AppColors.error,
              foreground: AppColors.onError,
              onTap: () async {
                await controller.end();
                onHangUp?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;
  final Color? background;
  final Color? foreground;

  const _CircleButton({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onTap,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ??
        (active ? Colors.white.withValues(alpha: 0.18) : AppColors.surfaceContainerHighest);
    final fg = foreground ?? (active ? Colors.white : AppColors.onSurface);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: fg, size: 24),
          ),
        ),
      ),
    );
  }
}
