import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/admin_api_service.dart';
import '../../../ui/admin_widgets/admin_confirm_dialog.dart';
import '../../subscriptions/models/subscription_models.dart';
import '../models/school.dart';
import '../../../ui/admin_theme.dart';

/// Opens the "change subscription" sheet for [school]. Picks a live plan and an
/// optional discount and assigns it via the instance-based flow (which records
/// the first payment). Calls [onChanged] after a successful assignment so the
/// caller can refresh. Returns true when the plan was changed.
Future<bool> showSubscriptionSheet(
  School school, {
  Future<void> Function()? onChanged,
}) async {
  final changed = await Get.bottomSheet<bool>(
    _SubscriptionSheet(school: school),
    isScrollControlled: true,
    backgroundColor: AdminPalette.canvas,
  );
  if (changed == true && onChanged != null) await onChanged();
  return changed == true;
}

class _SubscriptionSheet extends StatefulWidget {
  final School school;
  const _SubscriptionSheet({required this.school});

  @override
  State<_SubscriptionSheet> createState() => _SubscriptionSheetState();
}

class _SubscriptionSheetState extends State<_SubscriptionSheet> {
  final _api = AdminApiService();
  final _discountCtrl = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<SubscriptionPlanModel> _plans = [];
  String? _selectedPlanId;
  DiscountType _discountType = DiscountType.none;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    final res = await _api.fetchPlans();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _plans = res.data!;
        _selectedPlanId = _plans
                .firstWhereOrNull((p) => p.code == widget.school.planCode)
                ?.id ??
            _plans.firstOrNull?.id;
      } else {
        _error = res.error ?? 'Could not load plans.';
      }
    });
  }

  SubscriptionPlanModel? get _selectedPlan =>
      _plans.firstWhereOrNull((p) => p.id == _selectedPlanId);

  double get _discountValue => double.tryParse(_discountCtrl.text.trim()) ?? 0;

  double get _net {
    final plan = _selectedPlan;
    if (plan == null) return 0;
    final v = _discountValue;
    return switch (_discountType) {
      DiscountType.none => plan.price,
      DiscountType.percent => (plan.price * (1 - v / 100)).clamp(0, plan.price),
      DiscountType.fixed => (plan.price - v).clamp(0, plan.price),
    };
  }

  String? _validate() {
    if (_selectedPlanId == null) return 'Select a plan.';
    if (_discountType == DiscountType.none) return null;
    final v = _discountValue;
    if (v <= 0) return 'Enter a discount amount, or choose "No discount".';
    if (_discountType == DiscountType.percent && v > 100) {
      return 'A percentage discount cannot exceed 100%.';
    }
    return null;
  }

  Future<void> _assign() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final plan = _selectedPlan;
    final isSame = plan?.code == widget.school.planCode;
    final confirmed = await showAdminConfirm(
      icon: Icons.card_membership_rounded,
      title: 'Change subscription?',
      message:
          '${widget.school.name} will be moved to the ${plan?.name ?? 'selected'} plan. '
          'This records a new payment on the school’s ledger.',
      confirmLabel: 'Confirm & Assign',
      details: [
        AdminConfirmDetail(label: 'School', value: widget.school.name),
        AdminConfirmDetail(
          label: isSame ? 'Plan (renew)' : 'New plan',
          value: plan?.name ?? '—',
        ),
        if (_discountType != DiscountType.none)
          AdminConfirmDetail(
            label: 'Discount',
            value: _discountType == DiscountType.percent
                ? '${_discountValue.toStringAsFixed(0)}%'
                : _money(_discountValue),
          ),
        AdminConfirmDetail(
          label: 'Net amount',
          value: _money(_net),
          valueColor: AdminPalette.ink,
          emphasize: true,
        ),
      ],
    );
    if (!confirmed) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final res = await _api.assignSubscriptionInstance(
      schoolId: widget.school.id,
      planId: _selectedPlanId!,
      discountType: _discountType.code,
      discountValue: _discountValue,
    );
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _submitting = false;
        _error = res.error ?? 'Could not assign the subscription.';
      });
      return;
    }
    Get.back<bool>(result: true);
    Get.snackbar('Subscription updated', 'Plan changed for ${widget.school.name}.',
        snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.containerPaddingMobile,
          right: AppSpacing.containerPaddingMobile,
          top: AppSpacing.stackMd,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.stackMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subscription — ${widget.school.name}',
                style: AdminType.cardTitle),
            const SizedBox(height: AppSpacing.stackMd),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.stackLg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_plans.isEmpty)
              Text(
                _error ??
                    'No subscription plans exist. Create one first '
                        '(Settings → Subscription Plans).',
                style: AdminType.body.copyWith(color: AdminPalette.danger),
              )
            else ...[
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final plan in _plans) ...[
                        _PlanRow(
                          plan: plan,
                          selected: _selectedPlanId == plan.id,
                          onTap: () => setState(() => _selectedPlanId = plan.id),
                        ),
                        const SizedBox(height: AppSpacing.stackSm),
                      ],
                      const SizedBox(height: AppSpacing.stackSm),
                      _DiscountRow(
                        type: _discountType,
                        controller: _discountCtrl,
                        onTypeChanged: (t) => setState(() {
                          _discountType = t;
                          _error = null;
                        }),
                        onValueChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Net amount', style: AdminType.body),
                  Text(_money(_net),
                      style: AdminType.cardTitle
                          .copyWith(color: AdminPalette.ink)),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.stackSm),
                Text(_error!,
                    style: AdminType.body.copyWith(color: AdminPalette.danger)),
              ],
              const SizedBox(height: AppSpacing.stackMd),
              PrimaryButton(
                label: 'Assign Plan',
                expanded: true,
                isLoading: _submitting,
                onPressed: _assign,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _money(double v) =>
    '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

class _PlanRow extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final bool selected;
  final VoidCallback onTap;
  const _PlanRow(
      {required this.plan, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: selected
              ? AdminPalette.ink.withValues(alpha: 0.06)
              : AdminPalette.card,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: selected ? AdminPalette.ink : AdminPalette.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AdminPalette.ink : AdminPalette.faint,
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name,
                      style: AdminType.rowTitle
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${_money(plan.price)} ${plan.billingPeriod.priceSuffix}',
                      style: AdminType.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountRow extends StatelessWidget {
  final DiscountType type;
  final TextEditingController controller;
  final ValueChanged<DiscountType> onTypeChanged;
  final VoidCallback onValueChanged;

  const _DiscountRow({
    required this.type,
    required this.controller,
    required this.onTypeChanged,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Discount', style: AdminType.label),
        const SizedBox(height: AppSpacing.stackSm),
        Row(
          children: [
            for (final t in DiscountType.values) ...[
              ChoiceChip(
                label: Text(switch (t) {
                  DiscountType.none => 'None',
                  DiscountType.percent => 'Percent',
                  DiscountType.fixed => 'Fixed',
                }),
                selected: type == t,
                onSelected: (_) => onTypeChanged(t),
              ),
              const SizedBox(width: AppSpacing.stackSm),
            ],
          ],
        ),
        if (type != DiscountType.none) ...[
          const SizedBox(height: AppSpacing.stackSm),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: (_) => onValueChanged(),
            decoration: InputDecoration(
              hintText: type == DiscountType.percent ? 'e.g. 10 (%)' : 'e.g. 100',
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }
}
