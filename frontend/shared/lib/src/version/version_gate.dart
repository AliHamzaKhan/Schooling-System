import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/http_method.dart';
import '../ui/tokens/app_colors.dart';
import '../ui/tokens/app_radius.dart';
import '../ui/tokens/app_spacing.dart';
import '../ui/tokens/app_typography.dart';

/// Result of the splash version check.
enum VersionStatus { ok, updateAvailable, forceUpdate }

VersionStatus _statusFrom(String s) => switch (s) {
      'force_update' => VersionStatus.forceUpdate,
      'update_available' => VersionStatus.updateAvailable,
      _ => VersionStatus.ok,
    };

/// The server's verdict for the running build.
class AppVersionCheck {
  final VersionStatus status;
  final String latestVersion;
  final String minVersion;
  final String updateUrl;
  final String notes;

  const AppVersionCheck({
    required this.status,
    this.latestVersion = '',
    this.minVersion = '',
    this.updateUrl = '',
    this.notes = '',
  });

  factory AppVersionCheck.fromJson(Map<String, dynamic> j) => AppVersionCheck(
        status: _statusFrom((j['status'] ?? 'ok').toString()),
        latestVersion: (j['latest_version'] ?? '').toString(),
        minVersion: (j['min_version'] ?? '').toString(),
        updateUrl: (j['update_url'] ?? '').toString(),
        notes: (j['notes'] ?? '').toString(),
      );
}

/// Calls the public `/app-version` endpoint (no auth) to check the running build.
class AppVersionApi {
  final ApiService _api;
  const AppVersionApi(this._api);

  Future<AppVersionCheck> check({
    required String platform,
    required String version,
  }) async {
    final res = await _api.request<Map<String, dynamic>>(
      method: HttpMethod.get,
      path: '/app-version',
      query: {'platform': platform, 'version': version},
      requiresAuth: false,
    );
    if (!res.success) {
      throw ApiException(res.error ?? 'Version check failed');
    }
    return AppVersionCheck.fromJson(res.rawJson ?? const {});
  }
}

/// The store platform key the backend expects.
String currentAppPlatform() {
  if (kIsWeb) return 'android';
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return 'ios';
    default:
      return 'android';
  }
}

/// Splash screen that checks the app version against the server before the user
/// proceeds:
///   - ok               → calls [onProceed]
///   - update_available → shows a dismissible "Update available" dialog, then [onProceed]
///   - force_update     → shows a blocking mandatory-update screen (no proceed)
///
/// The check fails open: any network/error simply proceeds so the app is never
/// bricked by an unreachable server.
class VersionGate extends StatefulWidget {
  final String currentVersion;
  final VoidCallback onProceed;
  final String appTitle;

  const VersionGate({
    super.key,
    required this.currentVersion,
    required this.onProceed,
    this.appTitle = 'My Health',
  });

  @override
  State<VersionGate> createState() => _VersionGateState();
}

class _VersionGateState extends State<VersionGate> {
  AppVersionCheck? _forced;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    try {
      final api = AppVersionApi(Get.find<ApiService>());
      final res = await api.check(
        platform: currentAppPlatform(),
        version: widget.currentVersion,
      );
      switch (res.status) {
        case VersionStatus.forceUpdate:
          if (mounted) setState(() => _forced = res);
          return;
        case VersionStatus.updateAvailable:
          await _showUpdateDialog(res);
          widget.onProceed();
          return;
        case VersionStatus.ok:
          widget.onProceed();
          return;
      }
    } catch (_) {
      widget.onProceed(); // fail open
    }
  }

  Future<void> _showUpdateDialog(AppVersionCheck c) => Get.dialog<void>(
        AlertDialog(
          title: const Text('Update available'),
          content: Text(
            'A new version (${c.latestVersion}) of ${widget.appTitle} is available.'
            '${c.notes.isNotEmpty ? '\n\n${c.notes}' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Continue'),
            ),
            if (c.updateUrl.isNotEmpty)
              FilledButton(
                onPressed: () {
                  Get.back();
                  Get.snackbar('Update', 'Get it at: ${c.updateUrl}',
                      snackPosition: SnackPosition.BOTTOM);
                },
                child: const Text('Update now'),
              ),
          ],
        ),
        barrierDismissible: false,
      );

  @override
  Widget build(BuildContext context) {
    if (_forced != null) {
      return MandatoryUpdateScreen(check: _forced!, appTitle: widget.appTitle);
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              ),
              child: const Icon(Icons.health_and_safety_outlined,
                  size: 38, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text(widget.appTitle,
                style: AppTypography.headlineLg
                    .copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.stackLg),
            const SizedBox(
                width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
    );
  }
}

/// Blocking screen shown when the running build is below the minimum supported
/// version. The user cannot dismiss it or get back into the app.
class MandatoryUpdateScreen extends StatelessWidget {
  final AppVersionCheck check;
  final String appTitle;
  const MandatoryUpdateScreen(
      {super.key, required this.check, this.appTitle = 'My Health'});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.containerPaddingDesktop),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.system_update_rounded,
                          size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    Text('Update required',
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineLg.copyWith(
                            color: AppColors.onSurface, fontWeight: FontWeight.w800)),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      check.notes.isNotEmpty
                          ? check.notes
                          : 'This version of $appTitle is no longer supported. '
                              'Please update to version ${check.latestVersion} to continue.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLg
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Get.snackbar(
                            'Update',
                            check.updateUrl.isNotEmpty
                                ? 'Get the latest version at: ${check.updateUrl}'
                                : 'Please update from your app store.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Update now'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (check.updateUrl.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.stackSm),
                      SelectableText(check.updateUrl,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySm
                              .copyWith(color: AppColors.primary)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
