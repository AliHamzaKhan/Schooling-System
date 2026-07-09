import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../controller/settings_controller.dart';

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
          return const Center(child: CircularProgressIndicator());
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: GlassInput(
                      label: 'Uniform colour (hex)',
                      hint: '#1565C0',
                      controller: controller.uniformColor),
                ),
                const SizedBox(width: AppSpacing.stackMd),
                _ColorSwatch(controller: controller),
              ],
            ),
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

class _ColorSwatch extends StatelessWidget {
  final SettingsController controller;
  const _ColorSwatch({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller.uniformColor,
      builder: (context, value, _) {
        final color = _parseHex(value.text) ?? AppColors.surfaceContainerLowest;
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.outlineVariant),
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
