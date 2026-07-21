import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../controller/settings_controller.dart';
import '../../../../../widgets/skeletons.dart';

/// Headmaster School Settings — edit name, logo, uniform colour and the monthly
/// fee due day. Branding values persist in the school `settings` blob.
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('School Settings'),
        backgroundColor: AppColors.surface,
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonForm(fields: 4));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackLg,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackXl),
          children: [
            Text('Identity', style: AppTypography.labelCaps),
            const SizedBox(height: AppSpacing.stackSm),
            GlassInput(
                label: 'School name',
                hint: 'e.g. Test High School',
                controller: controller.name),
            const SizedBox(height: AppSpacing.stackMd),
            GlassInput(
                label: 'Logo URL',
                hint: 'https://…/logo.png',
                controller: controller.logoUrl,
                keyboardType: TextInputType.url),
            const SizedBox(height: AppSpacing.stackMd),
            _LogoPreview(controller: controller),
            const SizedBox(height: AppSpacing.stackXl),
            Text('Branding', style: AppTypography.labelCaps),
            const SizedBox(height: AppSpacing.stackSm),
            _UniformColorPicker(controller: controller),
            const SizedBox(height: AppSpacing.stackXl),
            Text('Fees', style: AppTypography.labelCaps),
            const SizedBox(height: AppSpacing.stackSm),
            GlassInput(
                label: 'Monthly fee due day (1–31)',
                hint: 'e.g. 5',
                controller: controller.feeDueDay,
                keyboardType: TextInputType.number),
            const SizedBox(height: AppSpacing.stackSm),
            Text('Invoices generated each month will be due on this day.',
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.stackXl),
            Obx(() => PrimaryButton(
                  label: 'Save Settings',
                  isLoading: controller.saving.value,
                  expanded: true,
                  onPressed:
                      controller.saving.value ? null : controller.save,
                )),
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
  final v = ((c.a * 255).round() << 24) |
      ((c.r * 255).round() << 16) |
      ((c.g * 255).round() << 8) |
      (c.b * 255).round();
  final rgb = (v & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  return '#$rgb';
}

const List<Color> _kPalette = [
  Color(0xFFF44336), Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF673AB7),
  Color(0xFF3F51B5), Color(0xFF2196F3), Color(0xFF03A9F4), Color(0xFF00BCD4),
  Color(0xFF009688), Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39),
  Color(0xFFFFEB3B), Color(0xFFFFC107), Color(0xFFFF9800), Color(0xFFFF5722),
  Color(0xFF795548), Color(0xFF9E9E9E), Color(0xFF607D8B), Color(0xFF1565C0),
  Color(0xFF0D47A1), Color(0xFF212121), Color(0xFFFFFFFF), Color(0xFF000000),
];

class _UniformColorPicker extends StatelessWidget {
  final SettingsController controller;
  const _UniformColorPicker({required this.controller});

  Future<void> _openPicker(BuildContext context, Color current) async {
    final picked = await showModalBottomSheet<Color>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pick uniform colour', style: AppTypography.titleLg),
                const SizedBox(height: AppSpacing.stackMd),
                GridView.count(
                  crossAxisCount: 6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.stackSm,
                  mainAxisSpacing: AppSpacing.stackSm,
                  children: [
                    for (final c in _kPalette)
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(c),
                        child: Container(
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                            border: Border.all(
                                color: current.value == c.value
                                    ? AppColors.primary
                                    : AppColors.outlineVariant,
                                width: current.value == c.value ? 3 : 1),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) {
      controller.uniformColor.text = _hexOf(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller.uniformColor,
      builder: (context, value, _) {
        final color = _parseHex(value.text) ?? AppColors.surfaceContainerLowest;
        final label = value.text.trim().isEmpty ? 'Not set' : value.text.trim();
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: () => _openPicker(context, color),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.outlineVariant),
              color: AppColors.surfaceContainerLowest,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Uniform colour', style: AppTypography.bodyLg),
                      const SizedBox(height: 2),
                      Text(label,
                          style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                const Icon(Icons.palette_outlined),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LogoPreview extends StatelessWidget {
  final SettingsController controller;
  const _LogoPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller.logoUrl,
      builder: (context, value, _) {
        final url = value.text.trim();
        if (url.isEmpty) return const SizedBox.shrink();
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Image.network(
            url,
            height: 72,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            errorBuilder: (_, _, _) => Text('Could not load logo preview',
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
        );
      },
    );
  }
}
