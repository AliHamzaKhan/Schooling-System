import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared/shared.dart';

import '../../../data/headmaster_repository.dart';
import '../controller/settings_controller.dart';

/// Headmaster School Settings — edit name, logo, uniform colour and the monthly
/// fee due day. Branding values persist in the school `settings` blob.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with ScreenTextControllers {
  final controller = Get.find<SettingsController>();

  // One controller per editable field, owned by this screen. The profile loads
  // asynchronously, so these stay bound to the controller's values.
  late final _nameCtrl = boundController(controller.name);
  late final _feeDueDayCtrl = boundController(controller.feeDueDay);
  late final _salaryDayCtrl = boundController(controller.salaryDay);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('School Settings'),
        backgroundColor: AppColors.surface,
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const AppStateView.loading(
            title: 'Loading school settings',
            message:
                'Getting the latest identity, branding, and billing preferences.',
          );
        }
        if (controller.error.value != null) {
          return AppStateView.error(
            title: 'Could not load school settings',
            message: controller.error.value!,
            actionLabel: 'Try again',
            onAction: controller.load,
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackLg,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackXl,
          ),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Identity', style: AppTypography.labelCaps),
                  const SizedBox(height: AppSpacing.stackMd),
                  AppTextField(
                    label: 'School name',
                    hintText: 'e.g. Test High School',
                    controller: _nameCtrl,
                    required: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  _LogoPickerField(controller: controller),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackXl),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Branding', style: AppTypography.labelCaps),
                  const SizedBox(height: AppSpacing.stackMd),
                  _UniformColorPicker(controller: controller),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackXl),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fees', style: AppTypography.labelCaps),
                  const SizedBox(height: AppSpacing.stackMd),
                  AppTextField(
                    label: 'Monthly fee due day',
                    hintText: 'e.g. 5',
                    helperText:
                        'Enter a day from 1 to 31. Invoices generated each month will be due on this day.',
                    controller: _feeDueDayCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  AppTextField(
                    label: 'Salary payout day',
                    hintText: 'e.g. 1',
                    helperText:
                        'Enter a day from 1 to 31. Outstanding-fee reminders are sent 5 days before this day.',
                    controller: _salaryDayCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackXl),
            Obx(
              () => PrimaryButton(
                label: 'Save Settings',
                isLoading: controller.saving.value,
                expanded: true,
                onPressed: controller.saving.value ? null : controller.save,
              ),
            ),
          ],
        );
      }),
    );
  }
}

Color? _parseHex(String raw) {
  var s = raw.trim().replaceAll('#', '');
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return null;
  final v = int.tryParse(s, radix: 16);
  return v == null ? null : Color(v);
}

String _hexOf(Color c) {
  final v =
      ((c.a * 255).round() << 24) |
      ((c.r * 255).round() << 16) |
      ((c.g * 255).round() << 8) |
      (c.b * 255).round();
  final rgb = (v & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  return '#$rgb';
}

const List<Color> _kPalette = [
  Color(0xFFF44336),
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  Color(0xFF673AB7),
  Color(0xFF3F51B5),
  Color(0xFF2196F3),
  Color(0xFF03A9F4),
  Color(0xFF00BCD4),
  Color(0xFF009688),
  Color(0xFF4CAF50),
  Color(0xFF8BC34A),
  Color(0xFFCDDC39),
  Color(0xFFFFEB3B),
  Color(0xFFFFC107),
  Color(0xFFFF9800),
  Color(0xFFFF5722),
  Color(0xFF795548),
  Color(0xFF9E9E9E),
  Color(0xFF607D8B),
  Color(0xFF1565C0),
  Color(0xFF0D47A1),
  Color(0xFF212121),
  Color(0xFFFFFFFF),
  Color(0xFF000000),
];

/// An inline uniform-colour picker: an HSV wheel-free picker built from hue /
/// saturation / brightness sliders plus quick-pick swatches — no bottom sheet.
/// Reads/writes the hex value in [SettingsController.uniformColor].
class _UniformColorPicker extends StatefulWidget {
  final SettingsController controller;
  const _UniformColorPicker({required this.controller});

  @override
  State<_UniformColorPicker> createState() => _UniformColorPickerState();
}

class _UniformColorPickerState extends State<_UniformColorPicker> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    final c =
        _parseHex(widget.controller.uniformColor.value) ??
        const Color(0xFF2196F3);
    _hsv = HSVColor.fromColor(c);
  }

  void _set(HSVColor next) {
    setState(() => _hsv = next);
    widget.controller.uniformColor.value = _hexOf(next.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    return Semantics(
      container: true,
      // Keep each slider and swatch a separate, named control.
      explicitChildNodes: true,
      label: 'Uniform colour ${_hexOf(color)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final largeText =
                  MediaQuery.textScalerOf(context).scale(14) >= 20;
              final swatch = Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
              );
              final description = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Uniform colour', style: AppTypography.bodyLg),
                  const SizedBox(height: 2),
                  Text(
                    _hexOf(color),
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              );
              if (largeText || constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [swatch, const Icon(AppIcons.paletteOutlined)],
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    description,
                  ],
                );
              }
              return Row(
                children: [
                  swatch,
                  const SizedBox(width: AppSpacing.stackMd),
                  Expanded(child: description),
                  const Icon(AppIcons.paletteOutlined),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _ColorSlider(
            label: 'Hue',
            value: _hsv.hue,
            max: 360,
            activeColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
            onChanged: (v) => _set(_hsv.withHue(v)),
          ),
          _ColorSlider(
            label: 'Saturation',
            value: _hsv.saturation,
            max: 1,
            activeColor: color,
            onChanged: (v) => _set(_hsv.withSaturation(v)),
          ),
          _ColorSlider(
            label: 'Brightness',
            value: _hsv.value,
            max: 1,
            activeColor: color,
            onChanged: (v) => _set(_hsv.withValue(v)),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Wrap(
            spacing: AppSpacing.stackSm,
            runSpacing: AppSpacing.stackSm,
            children: [
              for (final c in _kPalette)
                // Merge so the focusable ink node carries the colour's name.
                MergeSemantics(
                  child: Semantics(
                    button: true,
                    selected: _sameColor(c, color),
                    label: 'Use uniform colour ${_hexOf(c)}',
                    child: Tooltip(
                      message: _hexOf(c),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                          onTap: () => _set(HSVColor.fromColor(c)),
                          child: SizedBox.square(
                            dimension: 44,
                            child: Center(
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.button,
                                  ),
                                  border: Border.all(
                                    color: _sameColor(c, color)
                                        ? AppColors.primary
                                        : AppColors.outlineVariant,
                                    width: _sameColor(c, color) ? 3 : 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _sameColor(Color a, Color b) =>
      _hexOf(a).toUpperCase() == _hexOf(b).toUpperCase();
}

class _ColorSlider extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color activeColor;
  final ValueChanged<double> onChanged;
  const _ColorSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(14) >= 20;
        final slider = MergeSemantics(
          child: Semantics(
            label: label,
            child: Slider(
              value: value.clamp(0, max),
              max: max,
              activeColor: activeColor,
              onChanged: onChanged,
            ),
          ),
        );
        final labelWidget = Text(
          label,
          style: AppTypography.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        );
        if (largeText || constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [labelWidget, slider],
          );
        }
        return Row(
          children: [
            SizedBox(width: 78, child: labelWidget),
            Expanded(child: slider),
          ],
        );
      },
    );
  }
}

/// Tappable logo tile: pick an image file from the gallery, upload it, and store
/// the resulting URL in [SettingsController.logoUrl]. Replaces the old
/// paste-a-URL field.
class _LogoPickerField extends StatefulWidget {
  final SettingsController controller;
  const _LogoPickerField({required this.controller});

  @override
  State<_LogoPickerField> createState() => _LogoPickerFieldState();
}

class _LogoPickerFieldState extends State<_LogoPickerField> {
  final _picker = ImagePicker();
  final _repo = Get.find<HeadmasterRepository>();
  bool _uploading = false;
  String? _error;
  Uint8List? _preview;

  Future<void> _pick() async {
    setState(() => _error = null);
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
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
        contentType: xfile.mimeType ?? 'image/png',
      );
      if (!mounted) return;
      if (res.success && res.data != null) {
        widget.controller.logoUrl.value = res.data!;
        setState(() => _uploading = false);
      } else {
        setState(() {
          _uploading = false;
          _preview = null;
          _error = res.error ?? 'Could not upload logo';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _preview = null;
        _error = 'Could not pick logo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final url = widget.controller.logoUrl.value.trim();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            semanticLabel: _uploading
                ? 'School logo uploading'
                : (url.isEmpty ? 'Choose school logo' : 'Change school logo'),
            onTap: _uploading ? null : _pick,
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            child: Row(
              children: [
                _LogoThumb(preview: _preview, url: url),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('School logo', style: AppTypography.bodyLg),
                      const SizedBox(height: 2),
                      Text(
                        _uploading
                            ? 'Uploading…'
                            : (url.isEmpty
                                  ? 'Tap to choose an image'
                                  : 'Tap to change'),
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_uploading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(AppIcons.uploadRounded),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              _error!,
              style: AppTypography.bodySm.copyWith(color: AppColors.error),
            ),
          ],
        ],
      );
    });
  }
}

class _LogoThumb extends StatelessWidget {
  final Uint8List? preview;
  final String url;
  const _LogoThumb({required this.preview, required this.url});

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (preview != null) {
      child = Image.memory(preview!, fit: BoxFit.contain);
    } else if (url.isNotEmpty) {
      child = Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(AppIcons.imageNotSupportedOutlined),
      );
    } else {
      child = const Icon(AppIcons.apartmentRounded);
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
