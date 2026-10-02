import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';
import 'package:school_portal/school/utils/finance_roles.dart';

import '../../../data/headmaster_repository.dart';
import '../../../../../widgets/skeletons.dart';

/// Reviews immutable proposals for refunds, credits, waivers, and payroll
/// corrections. A decision records approval only; it does not post a money
/// movement while the school's currency and rounding policy is being defined.
class FinancialAdjustmentsView extends StatefulWidget {
  const FinancialAdjustmentsView({super.key});

  @override
  State<FinancialAdjustmentsView> createState() =>
      _FinancialAdjustmentsViewState();
}

class _FinancialAdjustmentsViewState extends State<FinancialAdjustmentsView> {
  static const _pageSize = 20;
  final _repository = Get.find<HeadmasterRepository>();
  final _items = <Map<String, dynamic>>[];
  final _busy = <String>{};
  bool _loading = true;
  String? _error;
  int _offset = 0;
  String? _kind;
  String? _targetType;
  String? _decision;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final response = await _repository.loadFinancialAdjustments(
      limit: _pageSize,
      offset: _offset,
      kind: _kind,
      targetType: _targetType,
      decision: _decision,
    );
    if (!mounted) return;
    setState(() {
      if (response.success && response.data != null) {
        _items
          ..clear()
          ..addAll(response.data!);
      } else {
        _error = response.error ?? 'Could not load financial adjustments.';
      }
      _loading = false;
    });
  }

  Future<void> _updateFilters({
    String? kind,
    String? targetType,
    String? decision,
    required bool clearKind,
    required bool clearTargetType,
    required bool clearDecision,
  }) async {
    setState(() {
      _kind = clearKind ? null : kind;
      _targetType = clearTargetType ? null : targetType;
      _decision = clearDecision ? null : decision;
      _offset = 0;
    });
    await _load();
  }

  Future<void> _changePage(int offset) async {
    if (offset < 0 || (_items.length < _pageSize && offset > _offset)) return;
    setState(() => _offset = offset);
    await _load();
  }

  Future<void> _decide(Map<String, dynamic> item, String decision) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _DecisionDialog(adjustment: item, decision: decision),
    );
    if (reason == null || !mounted) return;

    final id = item['id'] as String? ?? '';
    if (id.isEmpty) return;
    setState(() => _busy.add(id));
    final response = await _repository.decideFinancialAdjustment(
      adjustmentId: id,
      decision: decision,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _busy.remove(id));
    if (response.success) {
      Get.snackbar(
        decision == 'approved' ? 'Adjustment approved' : 'Adjustment rejected',
        'The decision is recorded. It does not post a balance or payroll change.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await _load();
    } else {
      Get.snackbar(
        'Decision not recorded',
        response.error ?? 'Please refresh and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Financial adjustments'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(AppIcons.refreshRounded),
          ),
        ],
      ),
      body: _loading
          ? const SkeletonPage(body: SkeletonCardList(count: 4, height: 180))
          : _error != null
          ? AppStateView.error(
              title: 'Could not load adjustments',
              message: _error!,
              actionLabel: 'Try again',
              onAction: _load,
            )
          : _AdjustmentList(
              items: _items,
              busy: _busy,
              onDecide: _decide,
              kind: _kind,
              targetType: _targetType,
              decision: _decision,
              offset: _offset,
              pageSize: _pageSize,
              loading: _loading,
              onKindChanged: (value) => _updateFilters(
                kind: value,
                targetType: _targetType,
                decision: _decision,
                clearKind: value == null,
                clearTargetType: false,
                clearDecision: false,
              ),
              onTargetTypeChanged: (value) => _updateFilters(
                kind: _kind,
                targetType: value,
                decision: _decision,
                clearKind: false,
                clearTargetType: value == null,
                clearDecision: false,
              ),
              onDecisionChanged: (value) => _updateFilters(
                kind: _kind,
                targetType: _targetType,
                decision: value,
                clearKind: false,
                clearTargetType: false,
                clearDecision: value == null,
              ),
              onPageChanged: _changePage,
            ),
    );
  }
}

class _AdjustmentList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Set<String> busy;
  final void Function(Map<String, dynamic> item, String decision) onDecide;
  final String? kind;
  final String? targetType;
  final String? decision;
  final int offset;
  final int pageSize;
  final bool loading;
  final ValueChanged<String?> onKindChanged;
  final ValueChanged<String?> onTargetTypeChanged;
  final ValueChanged<String?> onDecisionChanged;
  final ValueChanged<int> onPageChanged;

  const _AdjustmentList({
    required this.items,
    required this.busy,
    required this.onDecide,
    required this.kind,
    required this.targetType,
    required this.decision,
    required this.offset,
    required this.pageSize,
    required this.loading,
    required this.onKindChanged,
    required this.onTargetTypeChanged,
    required this.onDecisionChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pending = items.where((item) => item['decision'] == null).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackLg,
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackXl,
      ),
      children: [
        Text('Financial adjustments', style: AppTypography.headlineLg),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          '${pending.length} awaiting a Headmaster decision. Approving applies the change to the invoice or payslip.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        _AdjustmentFilters(
          kind: kind,
          targetType: targetType,
          decision: decision,
          onKindChanged: onKindChanged,
          onTargetTypeChanged: onTargetTypeChanged,
          onDecisionChanged: onDecisionChanged,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        if (items.isEmpty)
          AppStateView.empty(
            title: 'No adjustment proposals',
            message:
                'Try changing the filters, or create a refund, credit, waiver, or payroll correction proposal.',
          )
        else ...[
          for (final item in items) ...[
            _AdjustmentCard(
              item: item,
              isBusy: busy.contains(item['id']),
              onDecide: onDecide,
            ),
            const SizedBox(height: AppSpacing.stackMd),
          ],
          _AdjustmentPagination(
            offset: offset,
            pageSize: pageSize,
            showingFullPage: items.length == pageSize,
            busy: loading,
            onPageChanged: onPageChanged,
          ),
        ],
      ],
    );
  }
}

class _AdjustmentFilters extends StatelessWidget {
  final String? kind;
  final String? targetType;
  final String? decision;
  final ValueChanged<String?> onKindChanged;
  final ValueChanged<String?> onTargetTypeChanged;
  final ValueChanged<String?> onDecisionChanged;

  const _AdjustmentFilters({
    required this.kind,
    required this.targetType,
    required this.decision,
    required this.onKindChanged,
    required this.onTargetTypeChanged,
    required this.onDecisionChanged,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.stackSm,
    runSpacing: AppSpacing.stackSm,
    children: [
      _AdjustmentFilterMenu(
        label: 'Decision',
        value: decision,
        entries: const {'pending': 'Pending', 'approved': 'Approved', 'rejected': 'Rejected'},
        onChanged: onDecisionChanged,
      ),
      _AdjustmentFilterMenu(
        label: 'Type',
        value: kind,
        entries: const {
          'refund': 'Refund',
          'credit': 'Credit',
          'waiver': 'Waiver',
          'payroll_correction': 'Payroll correction',
        },
        onChanged: onKindChanged,
      ),
      _AdjustmentFilterMenu(
        label: 'Target',
        value: targetType,
        entries: const {'invoice': 'Invoice', 'payslip': 'Payslip'},
        onChanged: onTargetTypeChanged,
      ),
    ],
  );
}

class _AdjustmentFilterMenu extends StatelessWidget {
  final String label;
  final String? value;
  final Map<String, String> entries;
  final ValueChanged<String?> onChanged;

  const _AdjustmentFilterMenu({
    required this.label,
    required this.value,
    required this.entries,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text('All $label')),
        ...entries.entries.map(
          (entry) => DropdownMenuItem<String?>(
            value: entry.key,
            child: Text(entry.value),
          ),
        ),
      ],
      onChanged: onChanged,
    ),
  );
}

class _AdjustmentPagination extends StatelessWidget {
  final int offset;
  final int pageSize;
  final bool showingFullPage;
  final bool busy;
  final ValueChanged<int> onPageChanged;

  const _AdjustmentPagination({
    required this.offset,
    required this.pageSize,
    required this.showingFullPage,
    required this.busy,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text('Page ${(offset ~/ pageSize) + 1}', style: AppTypography.bodySm),
      const SizedBox(width: AppSpacing.stackSm),
      OutlinedButton(
        onPressed: busy || offset == 0 ? null : () => onPageChanged(offset - pageSize),
        child: const Text('Previous'),
      ),
      const SizedBox(width: AppSpacing.stackSm),
      PrimaryButton(
        label: 'Next',
        trailingIcon: null,
        onPressed: busy || !showingFullPage
            ? null
            : () => onPageChanged(offset + pageSize),
      ),
    ],
  );
}

class _AdjustmentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isBusy;
  final void Function(Map<String, dynamic> item, String decision) onDecide;

  const _AdjustmentCard({
    required this.item,
    required this.isBusy,
    required this.onDecide,
  });

  @override
  Widget build(BuildContext context) {
    final kind = (item['kind'] as String? ?? 'adjustment').replaceAll('_', ' ');
    final decision = item['decision'] as String?;
    final decisionColor = switch (decision) {
      'approved' => AppColors.tertiary,
      'rejected' => AppColors.error,
      _ => const Color(0xFFF59E0B),
    };
    final target = item['target_type'] as String? ?? 'record';
    final targetId = item['target_id'] as String? ?? '';
    final amount = item['proposed_amount'] as String? ?? '—';
    final reason = item['reason'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_titleCase(kind), style: AppTypography.titleLg),
              ),
              _StatusPill(label: decision ?? 'pending', color: decisionColor),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(amount, style: AppTypography.titleLg),
          const SizedBox(height: AppSpacing.stackSm),
          Text(reason, style: AppTypography.bodyMd),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            '${_titleCase(target)} · ${_shortId(targetId)}',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (decision != null) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'Decision reason: ${item['decision_reason'] ?? '—'}',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ] else if (!signedInAsHeadmaster()) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'Waiting for the Headmaster',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.stackMd),
            if (isBusy)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onDecide(item, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.stackSm),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Approve',
                      leadingIcon: AppIcons.checkRounded,
                      trailingIcon: null,
                      onPressed: () => onDecide(item, 'approved'),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _DecisionDialog extends StatefulWidget {
  final Map<String, dynamic> adjustment;
  final String decision;

  const _DecisionDialog({required this.adjustment, required this.decision});

  @override
  State<_DecisionDialog> createState() => _DecisionDialogState();
}

class _DecisionDialogState extends State<_DecisionDialog> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _reason.text.trim();
    if (value.length < 3) {
      setState(
        () => _error = 'Enter at least 3 characters for the decision reason.',
      );
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final approving = widget.decision == 'approved';
    return AlertDialog(
      title: Text(approving ? 'Approve adjustment?' : 'Reject adjustment?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            approving
                ? 'Approving applies this change to the invoice or payslip now. It cannot be undone.'
                : 'Rejecting records the decision. Nothing is changed.',
            style: AppTypography.bodyMd,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          TextField(
            controller: _reason,
            minLines: 2,
            maxLines: 5,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Decision reason',
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: approving
              ? null
              : FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: Text(approving ? 'Approve' : 'Reject'),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Text(
      _titleCase(label),
      style: AppTypography.labelMd.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

String _titleCase(String text) => text
    .split(' ')
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

String _shortId(String id) => id.length > 8 ? '${id.substring(0, 8)}…' : id;
