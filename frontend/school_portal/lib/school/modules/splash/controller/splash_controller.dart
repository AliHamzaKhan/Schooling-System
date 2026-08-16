import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../config/role_home.dart';

/// What the splash resolved the cold start to.
enum SplashOutcome {
  /// Still deciding.
  pending,

  /// The stored session could not be verified because the server was
  /// unreachable. The token is still valid as far as we know, so the user is
  /// offered a retry rather than being signed out.
  unreachable,
}

/// Decides where a cold start lands, while the splash holds the screen.
///
/// The work is a session restore (`/auth/me`), which resolves to one of three
/// outcomes:
///
/// * **no token, or the token was rejected (401)** → the shared login. A 401 is
///   handled inside [AuthService.bootstrap], which clears the session.
/// * **token accepted** → the module shell for the user's role.
/// * **server unreachable** → stay here and offer a retry. This case is the
///   reason the splash resolves the route instead of `main()` computing it: a
///   restored-but-unverified session has no role codes, and routing on empty
///   roles would drop whoever it is onto the wrong module shell.
class SplashController extends GetxController {
  final AuthService _auth;

  /// How long the splash stays up at minimum. Session restore is usually faster
  /// than this on a warm connection, and without a floor the splash would flash
  /// for a few frames and read as a glitch.
  static const _minimumOnScreen = Duration(milliseconds: 1400);

  SplashController({AuthService? auth})
      : _auth = auth ?? Get.find<AuthService>();

  final outcome = SplashOutcome.pending.obs;

  @override
  void onReady() {
    super.onReady();
    // onReady, not onInit: the first frame is on screen by then, so the
    // navigation that ends the splash never races the route being built.
    resolve();
  }

  /// Runs the restore and navigates. Safe to call again from the retry button.
  Future<void> resolve() async {
    outcome.value = SplashOutcome.pending;

    // Run the restore and the minimum dwell concurrently: the splash is up for
    // whichever takes longer, never for their sum.
    final started = DateTime.now();
    await _auth.bootstrap();
    final remaining = _minimumOnScreen - DateTime.now().difference(started);
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);

    if (!_auth.isLoggedIn.value) {
      Get.offAllNamed(AuthRoutes.login);
      return;
    }

    final home = homeRouteForRoles(_auth.roleCodes);
    if (home == null) {
      // Logged in with no usable role. Either the profile fetch never landed
      // (server down — roles are empty) or the account carries a role this app
      // has no shell for. Neither is a reason to sign the user out.
      outcome.value = SplashOutcome.unreachable;
      return;
    }
    Get.offAllNamed(home);
  }

  /// Abandons the stored session and starts over at login. The escape hatch for
  /// a user stuck on the unreachable state.
  Future<void> signInAgain() async {
    await _auth.logout();
    Get.offAllNamed(AuthRoutes.login);
  }
}
