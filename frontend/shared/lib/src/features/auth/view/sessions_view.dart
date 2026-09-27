import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';

/// Uses only the lifecycle metadata exposed by the self-service session API.
class SessionsView extends StatefulWidget {
  const SessionsView({
    super.key,
    required this.auth,
    required this.onSignedOut,
  });

  final AuthService auth;
  final VoidCallback onSignedOut;

  @override
  State<SessionsView> createState() => _SessionsViewState();
}

class _SessionsViewState extends State<SessionsView> {
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _sessions = [];
    });
    try {
      final result = await widget.auth.listSessions();
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result.success) {
          _sessions = result.data ?? [];
        } else {
          _error = 'Sessions could not be loaded. Please try again.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Sessions could not be loaded. Please try again.';
        });
      }
    }
  }

  Future<void> _revoke([Map<String, dynamic>? session]) async {
    if (_busy || _loading) return;
    // Lock before confirmation, including rapid taps on different rows.
    setState(() => _busy = true);
    try {
      final all = session == null;
      final current = session?['is_current'] == true;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(all ? 'Sign out everywhere?' : 'Revoke session?'),
          content: Text(
            all || current
                ? 'This includes your current session. You will need to sign in again.'
                : 'This session will no longer be able to access your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _error = null);
      final result = all
          ? await widget.auth.logoutAll()
          : await widget.auth.revokeSession(
              session['id'] as String,
              isCurrent: current,
            );
      if (!mounted) return;
      if (!result.success) {
        setState(
          () => _error =
              'Revocation was not confirmed. Refresh sessions before trying again.',
        );
      } else if (all || current) {
        widget.onSignedOut();
      } else {
        await _load();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Revocation was not confirmed. Refresh sessions before trying again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Unavailable';
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(date)} ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Active sessions')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Review your signed-in sessions. Times use this device’s timezone. Device names and locations are not collected here.',
              ),
              const SizedBox(height: 16),
              if (_loading) const Center(child: CircularProgressIndicator()),
              if (_error != null) ...[
                Semantics(liveRegion: true, child: Text(_error!)),
                const SizedBox(height: 8),
              ],
              if (!_loading)
                OutlinedButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('Refresh sessions'),
                ),
              if (!_loading && _error == null && _sessions.isEmpty)
                const Text('No active sessions were returned.'),
              for (var i = 0; i < _sessions.length; i++)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _sessions[i]['is_current'] == true
                              ? 'Current session'
                              : 'Other session ${i + 1}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text('Signed in: ${_date(_sessions[i]['created_at'])}'),
                        Text(
                          'Last refreshed: ${_date(_sessions[i]['last_used_at'])}',
                        ),
                        Text('Expires: ${_date(_sessions[i]['expires_at'])}'),
                        TextButton(
                          onPressed: _busy || _loading
                              ? null
                              : () => _revoke(_sessions[i]),
                          child: const Text('Revoke session'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy || _loading ? null : () => _revoke(),
                child: Text(_busy ? 'Please wait…' : 'Sign out everywhere'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
