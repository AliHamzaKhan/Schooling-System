import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../session_navigation.dart';

class SessionRestoreView extends StatefulWidget {
  const SessionRestoreView({super.key});
  @override
  State<SessionRestoreView> createState() => _SessionRestoreViewState();
}
class _SessionRestoreViewState extends State<SessionRestoreView> {
  final _auth = Get.find<AuthService>();
  late final String? _target = Get.parameters['returnTo'];
  bool _busy = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }
  Future<void> _restore() async {
    setState(() => _busy = true);
    await _auth.bootstrap();
    if (!mounted) return;
    setState(() => _busy = false);
    if (_auth.restoreError.value != null) return;
    Get.offAllNamed(_auth.isLoggedIn.value
      ? SessionNavigation.destination(_auth.roleCodes, _target)
      : SessionNavigation.loginFor(_target));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_busy) const CircularProgressIndicator()
          else ...[
            Text(_auth.restoreError.value ?? 'Your session could not be restored.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _restore, child: const Text('Retry')),
            TextButton(onPressed: () async {
              await _auth.logout();
              if (mounted) Get.offAllNamed(SessionNavigation.loginFor(_target));
            }, child: const Text('Sign in again')),
          ],
        ]),
      ),
    ))),
  );
}
