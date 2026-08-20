import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ui/tokens/app_colors.dart';
import '../ui/tokens/app_spacing.dart';
import '../ui/tokens/app_typography.dart';
import '../ui/widgets/glass_surface.dart';
import '../ui/widgets/primary_button.dart';
import 'biometric_result.dart';
import 'biometric_service.dart';
import 'package:shared/shared.dart';

/// A reusable lock screen that gates [child] behind a biometric prompt.
///
/// Drop it above any sensitive surface (the patient record, a payout screen):
/// ```dart
/// BiometricGate(
///   reason: 'Confirm it\'s you to open this consultation',
///   child: ConsultationView(),
/// )
/// ```
///
/// On devices without biometrics it falls back to [onUnsupported] if provided,
/// otherwise it renders [child] directly (nothing to gate against).
class BiometricGate extends StatefulWidget {
  final Widget child;
  final String reason;

  /// Title shown on the lock card.
  final String title;

  /// Whether to prompt automatically as soon as the gate mounts.
  final bool autoPrompt;

  /// Allow the device passcode/PIN as a fallback inside the system dialog.
  final bool allowDeviceCredential;

  /// Builder used when the platform has no biometric capability. When null the
  /// gate is transparent (renders [child]).
  final WidgetBuilder? onUnsupported;

  const BiometricGate({
    super.key,
    required this.child,
    required this.reason,
    this.title = 'Unlock to continue',
    this.autoPrompt = true,
    this.allowDeviceCredential = true,
    this.onUnsupported,
  });

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate> {
  BiometricService get _service => Get.find<BiometricService>();

  bool _unlocked = false;
  BiometricResult? _lastResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _service.refreshCapabilities();
      if (!mounted) return;
      if (!_service.canUseBiometrics.value && !_service.isDeviceSupported.value) {
        // Nothing to gate against — let the content through.
        setState(() => _unlocked = true);
        return;
      }
      if (widget.autoPrompt) _prompt();
    });
  }

  Future<void> _prompt() async {
    final result = await _service.authenticate(
      reason: widget.reason,
      biometricOnly: !widget.allowDeviceCredential,
    );
    if (!mounted) return;
    setState(() {
      _lastResult = result;
      _unlocked = result.isSuccess;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;

    if (!_service.canUseBiometrics.value &&
        !_service.isDeviceSupported.value &&
        widget.onUnsupported != null) {
      return widget.onUnsupported!(context);
    }

    final hasError =
        _lastResult != null && _lastResult != BiometricResult.success;

    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerPaddingMobile),
          child: GlassSurface(
            level: GlassLevel.l2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _service.hasFace
                      ? AppIcons.faceRetouchingNatural
                      : AppIcons.fingerprint,
                  size: 56,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Text(widget.title, style: AppTypography.titleLg),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  widget.reason,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd,
                ),
                if (hasError) ...[
                  const SizedBox(height: AppSpacing.stackSm),
                  Text(
                    _lastResult!.message,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.stackLg),
                Obx(
                  () => PrimaryButton(
                    label: 'Unlock',
                    leadingIcon: AppIcons.lockOpen,
                    trailingIcon: null,
                    expanded: true,
                    isLoading: _service.isAuthenticating.value,
                    onPressed: _prompt,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
