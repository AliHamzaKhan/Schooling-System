import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../config/image_constant.dart';
import '../../../constants/app_strings.dart';
import '../controller/splash_controller.dart';

/// The first screen of a cold start: the app icon and wordmark over the brand
/// slate, held while [SplashController] restores the session and decides where
/// to land.
///
/// Written in Dart rather than configured as a native launch screen, so it can
/// do what a static native splash cannot: animate, and — when the server is
/// unreachable — turn into a readable error with a retry instead of hanging on
/// a frozen logo.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.containerPaddingMobile),
            child: Column(
              children: [
                const Spacer(),
                const _Wordmark(),
                const Spacer(),
                // A floor, not a fixed height: it stops the mark jumping when
                // the spinner is replaced by the taller error block, while
                // still letting that block take the room it needs (long text,
                // large system font) by borrowing from the Spacers.
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 168),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Obx(() =>
                        controller.outcome.value == SplashOutcome.unreachable
                            ? const _Unreachable()
                            : const _Working()),
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

/// App icon + product name, faded and scaled in on first frame.
class _Wordmark extends StatefulWidget {
  const _Wordmark();

  @override
  State<_Wordmark> createState() => _WordmarkState();
}

class _WordmarkState extends State<_Wordmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<double> _scale =
      Tween(begin: 0.88, end: 1.0).animate(CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutBack,
  ));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                ImageConstant.appIcon,
                width: 116,
                height: 116,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text(
              AppStrings.appName,
              style: AppTypography.displayLg.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              AppStrings.splashTagline,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onPrimary.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Restore in progress.
class _Working extends StatelessWidget {
  const _Working();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation(
              AppColors.onPrimary.withValues(alpha: 0.85),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.stackXl),
      ],
    );
  }
}

/// The server could not be reached, so the stored session stayed unverified.
/// Retry is the primary action — the session is probably fine and the user
/// should not have to re-enter a password because a server blipped.
class _Unreachable extends StatelessWidget {
  const _Unreachable();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SplashController>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.cloudOffRounded,
            size: 28, color: AppColors.onPrimary.withValues(alpha: 0.85)),
        const SizedBox(height: AppSpacing.stackMd),
        Text(
          AppStrings.splashUnreachable,
          textAlign: TextAlign.center,
          style: AppTypography.bodyLg.copyWith(
            color: AppColors.onPrimary.withValues(alpha: 0.88),
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: controller.resolve,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onPrimary,
                side: BorderSide(
                    color: AppColors.onPrimary.withValues(alpha: 0.55)),
              ),
              child: const Text('Retry'),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            TextButton(
              onPressed: controller.signInAgain,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.onPrimary.withValues(alpha: 0.75),
              ),
              child: const Text('Sign in again'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackLg),
      ],
    );
  }
}
