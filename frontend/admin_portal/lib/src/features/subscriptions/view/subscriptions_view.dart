import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../controller/subscriptions_controller.dart';
import '../models/subscription_models.dart';

/// Subscription Plans — the admin-editable products. Each plan carries a price
/// and a billing duration (Monthly / 6-Month / Annual); admins can add, edit,
/// or archive plans at any time.
class SubscriptionsView extends GetView<SubscriptionsController> {
  const SubscriptionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminTopBar(showAvatar: true),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.error.value != null) {
              return Center(
                  child: Text(controller.error.value!,
                      style: AppTypography.bodyLg));
            }
            return RefreshIndicator(
              onRefresh: controller.fetch,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  Text('Subscription\nPlans', style: AppTypography.headlineLg),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text('Add, edit, or archive pricing plans at any time.',
                      style: AppTypography.bodyLg),
                  const SizedBox(height: AppSpacing.stackLg),
                  PrimaryButton(
                    label: 'New Plan',
                    leadingIcon: Icons.add,
                    trailingIcon: null,
                    onPressed: () => _openPlanForm(context),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  if (controller.plans.isEmpty)
                    Text('No plans yet. Create your first plan.',
                        style: AppTypography.bodyLg
                            .copyWith(color: AppColors.onSurfaceVariant))
                  else
                    for (final plan in controller.plans) ...[
                      _PlanCard(
                        plan: plan,
                        onEdit: () => _openPlanForm(context, plan: plan),
                        onArchive: () => _confirmArchive(plan),
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                    ],
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  void _openPlanForm(BuildContext context, {SubscriptionPlanModel? plan}) {
    Get.dialog<void>(_PlanFormDialog(plan: plan));
  }

  Future<void> _confirmArchive(SubscriptionPlanModel plan) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Archive plan?'),
        content: Text(
            '${plan.name} will be hidden from new subscriptions. Existing subscriptions keep their pricing.'),
        actions: [
          TextButton(
              onPressed: () => Get.back<bool>(result: false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Archive',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) await controller.archivePlan(plan);
  }
}

String _money(double v) =>
    '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

/// Accent color per billing duration, so the three durations read distinctly.
Color _accentFor(BillingPeriod p) => switch (p) {
      BillingPeriod.monthly => AppColors.primary,
      BillingPeriod.sixMonth => AppColors.aiAccent,
      BillingPeriod.annual => const Color(0xFFE8A317),
    };

class _PlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _PlanCard({
    required this.plan,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(plan.billingPeriod);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: AppColors.outlineVariant),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.07), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Chip(label: plan.billingPeriod.label, color: accent),
              const SizedBox(width: AppSpacing.stackSm),
              _Chip(
                label:
                    '${plan.modules.length} module${plan.modules.length == 1 ? '' : 's'}',
                color: AppColors.onSurfaceVariant,
                subtle: true,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.archive_outlined,
                    color: AppColors.onSurfaceVariant),
                tooltip: 'Archive',
                visualDensity: VisualDensity.compact,
                onPressed: onArchive,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(plan.name, style: AppTypography.titleLg),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(_money(plan.price),
                  style: AppTypography.displayLg
                      .copyWith(fontSize: 40, color: accent)),
              const SizedBox(width: 4),
              Text(plan.billingPeriod.priceSuffix, style: AppTypography.bodyLg),
            ],
          ),
          if (plan.description != null && plan.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Text(plan.description!, style: AppTypography.bodyMd),
          ],
          const SizedBox(height: AppSpacing.stackLg),
          PrimaryButton(
            label: 'Edit Plan',
            expanded: true,
            trailingIcon: null,
            leadingIcon: Icons.edit_outlined,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool subtle;
  const _Chip({required this.label, required this.color, this.subtle = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: subtle ? 0.10 : 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label,
          style: AppTypography.labelMd
              .copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

/// Create / edit form for a plan (name, price, billing duration, description).
class _PlanFormDialog extends StatefulWidget {
  final SubscriptionPlanModel? plan;
  const _PlanFormDialog({this.plan});

  @override
  State<_PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends State<_PlanFormDialog> {
  final _controller = Get.find<SubscriptionsController>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late BillingPeriod _period;
  String? _error;

  bool get _isEdit => widget.plan != null;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p == null ? '' : p.price.toStringAsFixed(0));
    _description = TextEditingController(text: p?.description ?? '');
    _period = p?.billingPeriod ?? BillingPeriod.monthly;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim());
    if (name.length < 2 || price == null || price < 0) {
      setState(() => _error = 'Enter a name and a valid price.');
      return;
    }
    setState(() => _error = null);
    final ok = await _controller.savePlan(
      existing: widget.plan,
      name: name,
      price: price,
      billingPeriod: _period,
      description: _description.text.trim(),
    );
    if (ok) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Plan' : 'New Plan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Plan name')),
            TextField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Price', prefixText: '\$ '),
            ),
            DropdownButtonFormField<BillingPeriod>(
              initialValue: _period,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Billing duration'),
              items: BillingPeriod.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                  .toList(),
              onChanged: (v) => setState(() => _period = v ?? _period),
            ),
            TextField(
                controller: _description,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)')),
            const SizedBox(height: 8),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back<void>(), child: const Text('Cancel')),
        Obx(() => TextButton(
              onPressed: _controller.saving.value ? null : _submit,
              child: Text(_controller.saving.value ? 'Saving…' : 'Save'),
            )),
      ],
    );
  }
}
