import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../anim/app_motion.dart';
import '../tokens/app_colors.dart';

/// Standard full-screen scaffold for top-level / embedded screens.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool safeArea;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: safeArea ? SafeArea(child: body) : body,
    );
  }
}

/// Presents **detail screens as an overlay** on top of the current screen —
/// like an `endDrawer` / side sheet.
///
/// It does NOT navigate to a new page; it pushes a [PopupRoute] (via
/// [Get.generalDialog]) so the previous screen stays mounted and visible behind
/// a scrim:
/// - **Web (wide)**: the panel occupies a partial width on the right; the rest
///   of the screen is dimmed and tappable to close.
/// - **Mobile / narrow**: the panel covers the full width (still an overlay,
///   so the page underneath is preserved).
///
/// The panel slides in from the right and the scrim fades in; closing reverses
/// both. Tap the scrim, the back button, or call [Get.back] to dismiss.
///
/// [binding] registers the screen's controller (lazily, so it reads the dialog
/// [arguments] correctly). [onDispose] runs after close — pass
/// `() => Get.delete<XController>()` for screens whose state must be fresh on
/// every open (e.g. when arguments differ).
class AppPanelScaffold {
  AppPanelScaffold._();

  /// Min screen width (on web) at which the panel becomes partial-width.
  static const double webBreakpoint = 840;

  static Future<T?> open<T>(
    Widget page, {
    Bindings? binding,
    dynamic arguments,
    VoidCallback? onDispose,
    double widthFraction = 0.5,
    double minWidth = 420,
    double maxWidth = 720,
  }) async {
    binding?.dependencies();

    final width = Get.width;
    final wide = kIsWeb && width >= webBreakpoint;
    final panelWidth = wide ? (width * widthFraction).clamp(minWidth, maxWidth) : width;

    final result = await Get.generalDialog<T>(
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: AppMotion.route,
      routeSettings: RouteSettings(arguments: arguments),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: panelWidth.toDouble(),
            height: double.infinity,
            child: Material(
              color: AppColors.background,
              elevation: 16,
              child: page,
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.standard,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(curved),
          child: child,
        );
      },
    );

    onDispose?.call();
    return result;
  }
}
