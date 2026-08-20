import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared/shared.dart';

import '../modules/headmaster/data/headmaster_repository.dart';

/// Tappable avatar tile that lets the user capture a photo from the camera or
/// pick one from the gallery, uploads it to the backend, and exposes the
/// resulting URL via [urlController]. Uploads happen inline; while an upload
/// is in flight the picker shows a spinner.
///
/// Consumers just read `urlController.text` at submit time — no callback
/// plumbing needed.
class AvatarPickerField extends StatefulWidget {
  final TextEditingController urlController;
  final String label;

  const AvatarPickerField({
    super.key,
    required this.urlController,
    this.label = 'Profile picture',
  });

  @override
  State<AvatarPickerField> createState() => _AvatarPickerFieldState();
}

class _AvatarPickerFieldState extends State<AvatarPickerField> {
  final _picker = ImagePicker();
  final _repo = Get.find<HeadmasterRepository>();
  bool _uploading = false;
  String? _error;
  Uint8List? _preview; // Local preview shown before upload confirms.

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _error = null;
    });
    try {
      final xfile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      setState(() {
        _preview = bytes;
        _uploading = true;
      });
      final res = await _repo.uploadAvatar(
        filePath: kIsWeb ? null : xfile.path,
        bytes: kIsWeb ? bytes : null,
        filename: xfile.name,
        contentType: xfile.mimeType ?? 'image/jpeg',
      );
      if (!mounted) return;
      if (res.success && res.data != null) {
        widget.urlController.text = res.data!;
        setState(() => _uploading = false);
      } else {
        setState(() {
          _uploading = false;
          _preview = null;
          _error = res.error ?? 'Could not upload photo';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _preview = null;
        _error = 'Could not pick photo: $e';
      });
    }
  }

  Future<void> _openPickerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(AppIcons.cameraAltOutlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(AppIcons.photoLibraryOutlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pick(ImageSource.gallery);
              },
            ),
            if (widget.urlController.text.isNotEmpty || _preview != null)
              ListTile(
                leading: const Icon(AppIcons.deleteOutline,
                    color: AppColors.error),
                title: const Text('Remove photo',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _preview = null;
                    widget.urlController.text = '';
                    _error = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _avatarImage() {
    if (_preview != null) return MemoryImage(_preview!);
    final url = widget.urlController.text.trim();
    if (url.isEmpty) return null;
    if (url.startsWith('http')) return NetworkImage(url);
    // Local absolute path (e.g. dev storage) — attempt file image.
    if (!kIsWeb) return FileImage(File(url));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final image = _avatarImage();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label.toUpperCase(),
            style: AppTypography.labelCaps
                .copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _uploading ? null : _openPickerSheet,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      backgroundImage: image,
                      child: image == null
                          ? const Icon(AppIcons.personOutlineRounded,
                              size: 32, color: AppColors.primary)
                          : null,
                    ),
                    if (_uploading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _uploading
                            ? 'Uploading…'
                            : (image == null
                                ? 'Tap to add photo'
                                : 'Tap to change photo'),
                        style: AppTypography.bodyLg,
                      ),
                      const SizedBox(height: 2),
                      Text('Camera or gallery',
                          style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                const Icon(AppIcons.cameraAltOutlined,
                    color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!,
              style: AppTypography.bodyMd.copyWith(color: AppColors.error)),
        ],
      ],
    );
  }
}
