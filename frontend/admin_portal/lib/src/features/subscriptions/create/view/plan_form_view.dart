import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../ui/admin_theme.dart';
import '../../../../ui/admin_widgets/admin_surface.dart';
import '../../../../ui/admin_widgets/admin_text_field.dart';
import '../../controller/subscriptions_controller.dart';
import '../../models/plan_features.dart';
import '../../models/subscription_models.dart';

/// Full-screen create / edit form for a subscription plan. Replaces the old
/// dialog: name, price, billing duration, student cap, description, and the
/// add-on feature toggles (stored in the plan's `modules` array).
///
/// The plan to edit is passed via `Get.arguments`; a null argument means
/// "new plan".
class PlanFormView extends StatefulWidget {
  const PlanFormView({super.key});

  @override
  State<PlanFormView> createState() => _PlanFormViewState();
}

class _PlanFormViewState extends State<PlanFormView> {
  final _controller = Get.find<SubscriptionsController>();

  late final SubscriptionPlanModel? _plan =
      Get.arguments as SubscriptionPlanModel?;

  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _maxStudents;
  late BillingPeriod _period;

  /// Feature keys currently switched on.
  final _selected = <String>{};

  /// Module keys the plan carried that aren't in the feature catalog (e.g.
  /// seeded core modules like `exams`). Preserved untouched on save.
  final _preserved = <String>[];

  String? _error;

  bool get _isEdit => _plan != null;

  @override
  void initState() {
    super.initState();
    final p = _plan;
    _name = TextEditingController(text: p?.name ?? '');
    _price =
        TextEditingController(text: p == null ? '' : p.price.toStringAsFixed(0));
    _description = TextEditingController(text: p?.description ?? '');
    _maxStudents = TextEditingController(
        text: p?.maxStudents == null ? '' : '${p!.maxStudents}');
    _period = p?.billingPeriod ?? BillingPeriod.monthly;
    for (final key in p?.modules ?? const <String>[]) {
      if (kPlanFeatureByKey.containsKey(key)) {
        _selected.add(key);
      } else {
        _preserved.add(key);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _maxStudents.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim());
    if (name.length < 2 || price == null || price < 0) {
      setState(() => _error = 'Enter a name and a valid price.');
      return;
    }
    final capText = _maxStudents.text.trim();
    int? maxStudents;
    if (capText.isNotEmpty) {
      maxStudents = int.tryParse(capText);
      if (maxStudents == null || maxStudents < 1) {
        setState(() => _error =
            'Max students must be a whole number (or blank for unlimited).');
        return;
      }
    }
    setState(() => _error = null);
    // Persist selected features alongside any modules we chose not to surface.
    final modules = <String>[..._preserved, ..._selected];
    final ok = await _controller.savePlan(
      existing: _plan,
      name: name,
      price: price,
      billingPeriod: _period,
      description: _description.text.trim(),
      maxStudents: maxStudents,
      modules: modules,
    );
    if (ok && mounted) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.stackSm,
                AppSpacing.stackSm, AppSpacing.containerPaddingMobile, AppSpacing.stackSm),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Get.back<void>(),
                  icon:
                      const Icon(AppIcons.closeRounded, color: AdminPalette.ink),
                ),
                Text(_isEdit ? 'Edit Plan' : 'New Plan',
                    style: AdminType.cardTitle.copyWith(
                        color: AdminPalette.ink, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  0,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Basics ──
                  AdminCard(
                    padding: const EdgeInsets.all(AppSpacing.stackLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plan details', style: AdminType.rowTitle),
                        const SizedBox(height: AppSpacing.stackLg),
                        AdminTextField(
                          label: 'Plan name',
                          hint: 'e.g. Standard',
                          controller: _name,
                          required: true,
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                        AdminTextField(
                          label: 'Price',
                          hint: '0',
                          controller: _price,
                          required: true,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                        AdminDropdownField<BillingPeriod>(
                          label: 'Billing duration',
                          value: _period,
                          items: BillingPeriod.values,
                          labelOf: (p) => p.label,
                          onChanged: (v) =>
                              setState(() => _period = v ?? _period),
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                        AdminTextField(
                          label: 'Max students',
                          hint: 'Leave blank for unlimited',
                          controller: _maxStudents,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                        AdminTextField(
                          label: 'Description',
                          hint: 'Optional summary shown on the plan card…',
                          controller: _description,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),

                  // ── Features ──
                  Text('Features', style: AdminType.rowTitle),
                  const SizedBox(height: 4),
                  Text(
                    'Toggle the add-ons this plan unlocks. Schools on the plan '
                    'get exactly what is switched on here.',
                    style: AdminType.body.copyWith(color: AdminPalette.muted),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  for (final group in kPlanFeatureGroups) ...[
                    _FeatureGroupCard(
                      group: group,
                      selected: _selected,
                      onToggle: (key, on) => setState(() {
                        on ? _selected.add(key) : _selected.remove(key);
                      }),
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(_error!,
                        style: const TextStyle(color: AdminPalette.danger)),
                  ],
                ],
              ),
            ),
          ),
          _SaveBar(saving: _controller.saving, onSave: _submit),
        ],
      ),
    );
  }
}

class _FeatureGroupCard extends StatelessWidget {
  final PlanFeatureGroup group;
  final Set<String> selected;
  final void Function(String key, bool on) onToggle;

  const _FeatureGroupCard({
    required this.group,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.stackMd, vertical: AppSpacing.stackSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                4, AppSpacing.stackSm, 4, AppSpacing.stackSm),
            child: Row(
              children: [
                Icon(group.icon, size: 18, color: AdminPalette.muted),
                const SizedBox(width: 8),
                Text(group.title,
                    style: AdminType.label.copyWith(
                        color: AdminPalette.muted,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          for (final f in group.features)
            _FeatureRow(
              feature: f,
              value: selected.contains(f.key),
              onChanged: (on) => onToggle(f.key, on),
            ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final PlanFeature feature;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FeatureRow({
    required this.feature,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Icon(feature.icon,
                size: 20,
                color: value ? AdminPalette.ink : AdminPalette.faint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(feature.label, style: AdminType.rowTitle),
                  const SizedBox(height: 2),
                  Text(feature.description,
                      style: AdminType.meta
                          .copyWith(color: AdminPalette.muted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: value,
              activeThumbColor: AdminPalette.ink,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  final RxBool saving;
  final VoidCallback onSave;
  const _SaveBar({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.containerPaddingMobile,
            AppSpacing.stackSm, AppSpacing.containerPaddingMobile, AppSpacing.stackSm),
        child: Obx(() => PrimaryButton(
              label: saving.value ? 'Saving…' : 'Save Plan',
              expanded: true,
              trailingIcon: null,
              leadingIcon: AppIcons.checkRounded,
              onPressed: saving.value ? null : onSave,
            )),
      ),
    );
  }
}
