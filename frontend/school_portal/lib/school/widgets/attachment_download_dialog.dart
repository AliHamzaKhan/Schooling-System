import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showAttachmentDownload(
  BuildContext context,
  String recordId, {
  String kind = 'submissions',
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => AttachmentDownloadDialog(
      resolve: () =>
          AttachmentAccessService(Get.find<ApiService>()).downloadUri(
            schoolId: Get.find<AuthService>().schoolId ?? '',
            kind: kind,
            recordId: recordId,
          ),
      launch: (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
    ),
  );
}

/// Prepare first, then launch on a fresh user gesture (web popup-safe).
class AttachmentDownloadDialog extends StatefulWidget {
  final Future<Uri> Function() resolve;
  final Future<bool> Function(Uri) launch;
  const AttachmentDownloadDialog({
    super.key,
    required this.resolve,
    required this.launch,
  });

  @override
  State<AttachmentDownloadDialog> createState() =>
      _AttachmentDownloadDialogState();
}

class _AttachmentDownloadDialogState extends State<AttachmentDownloadDialog> {
  Uri? _uri;
  DateTime? _readyAt;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final requestedAt = DateTime.now();
    setState(() {
      _busy = true;
      _error = null;
      _uri = null;
    });
    try {
      final uri = await widget.resolve();
      if (!mounted) return;
      setState(() {
        _uri = uri;
        _readyAt = requestedAt;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Attachment unavailable. Check your connection and access, then retry.';
        _busy = false;
      });
    }
  }

  Future<void> _download() async {
    if (_uri == null || DateTime.now().difference(_readyAt!).inSeconds >= 50) {
      await _prepare();
      return; // The next click supplies the browser's launch gesture.
    }
    setState(() => _busy = true);
    try {
      final opened = await widget.launch(_uri!);
      if (!opened) throw StateError('Launch failed');
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not open the download. Please retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Download attachment'),
    content: _busy
        ? const Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Flexible(child: Text('Preparing secure download…')),
            ],
          )
        : Text(_error ?? 'Your download is ready. This link expires shortly.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _busy ? null : (_error != null ? _prepare : _download),
        child: Text(_error != null ? 'Retry' : 'Download'),
      ),
    ],
  );
}
