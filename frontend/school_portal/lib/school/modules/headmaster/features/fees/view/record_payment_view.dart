import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_search_field.dart';
import '../../../data/headmaster_repository.dart';
import '../models/student_fee_snapshot.dart';

/// Record Payment — full-page. Headmaster searches by student name / father /
/// class, picks a student, and either marks a specific invoice paid in full
/// or leaves it pending.
class RecordPaymentView extends StatefulWidget {
  const RecordPaymentView({super.key});

  @override
  State<RecordPaymentView> createState() => _RecordPaymentViewState();
}

class _RecordPaymentViewState extends State<RecordPaymentView> {
  final _repo = Get.find<HeadmasterRepository>();

  final _query = ''.obs;
  final _results = <StudentFeeSnapshot>[].obs;
  final _loading = false.obs;
  final _error = RxnString();
  final _selected = Rxn<StudentFeeSnapshot>();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Prime with an empty search so the list shows every student's snapshot.
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String v) {
    _query.value = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(v));
  }

  Future<void> _search(String q) async {
    _loading.value = true;
    _error.value = null;
    final res = await _repo.searchStudentFees(query: q, limit: 50);
    if (res.success && res.data != null) {
      _results.assignAll(res.data!.items);
    } else {
      _error.value = res.error ?? 'Could not search students';
    }
    _loading.value = false;
  }

  Future<void> _markPaid(StudentFeeSnapshot s, InvoiceSummary inv) async {
    final res = await _repo.recordPayment(
      invoiceId: inv.id,
      amount: inv.balance,
      method: 'cash',
    );
    if (!mounted) return;
    if (res.success) {
      Get.snackbar('Payment recorded', 'Marked "${inv.title}" as paid.',
          snackPosition: SnackPosition.BOTTOM);
      // Refresh the current student so balances update in place.
      await _search(_query.value);
      _selected.value = _results
          .firstWhereOrNull((r) => r.studentId == s.studentId);
    } else {
      Get.snackbar('Could not record', res.error ?? 'Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackLg,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackSm,
            ),
            child: PortalSearchField(
              hint: 'Search by name, father name, or class…',
              onChanged: _onQuery,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_selected.value != null) {
                return _StudentDetail(
                  snapshot: _selected.value!,
                  onBack: () => _selected.value = null,
                  onMarkPaid: (inv) => _markPaid(_selected.value!, inv),
                );
              }
              if (_loading.value && _results.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_error.value != null) {
                return Center(
                    child: Text(_error.value!, style: AppTypography.bodyLg));
              }
              if (_results.isEmpty) {
                return Center(
                  child: Text('No students match your search.',
                      style: AppTypography.bodyLg),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackSm,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl,
                ),
                itemCount: _results.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.stackSm),
                itemBuilder: (_, i) => _StudentResultTile(
                  snapshot: _results[i],
                  onTap: () => _selected.value = _results[i],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) => switch (status) {
      'overdue' => AppColors.error,
      'pending' => const Color(0xFFF59E0B),
      'paid' => AppColors.tertiary,
      _ => AppColors.onSurfaceVariant,
    };

String _money(double v) =>
    '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

class _StudentResultTile extends StatelessWidget {
  final StudentFeeSnapshot snapshot;
  final VoidCallback onTap;
  const _StudentResultTile({required this.snapshot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = snapshot.displayStatus;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                snapshot.fullName.isNotEmpty
                    ? snapshot.fullName[0].toUpperCase()
                    : '?',
                style: AppTypography.titleLg
                    .copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(snapshot.fullName, style: AppTypography.bodyLg),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (snapshot.fatherName != null &&
                          snapshot.fatherName!.isNotEmpty)
                        'S/o ${snapshot.fatherName}',
                      if (snapshot.className != null &&
                          snapshot.className!.isNotEmpty)
                        '${snapshot.className}${snapshot.sectionName != null ? " · ${snapshot.sectionName}" : ""}',
                    ].join(' · '),
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              _statusColor(status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: AppTypography.labelMd.copyWith(
                              color: _statusColor(status),
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(_money(snapshot.outstandingTotal),
                          style: AppTypography.labelMd),
                      Text(' due',
                          style: AppTypography.labelMd
                              .copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _StudentDetail extends StatelessWidget {
  final StudentFeeSnapshot snapshot;
  final VoidCallback onBack;
  final void Function(InvoiceSummary) onMarkPaid;
  const _StudentDetail({
    required this.snapshot,
    required this.onBack,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackMd,
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackXl,
      ),
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back to search'),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.stackLg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(snapshot.fullName, style: AppTypography.titleLg),
              const SizedBox(height: 4),
              if (snapshot.fatherName != null &&
                  snapshot.fatherName!.isNotEmpty)
                Text("Father: ${snapshot.fatherName}",
                    style: AppTypography.bodyMd),
              if (snapshot.className != null)
                Text(
                    "Class: ${snapshot.className}${snapshot.sectionName != null ? " · ${snapshot.sectionName}" : ""}",
                    style: AppTypography.bodyMd),
              const SizedBox(height: AppSpacing.stackMd),
              Row(
                children: [
                  Expanded(
                    child: _MoneyChip(
                      label: 'OUTSTANDING',
                      value: _money(snapshot.outstandingTotal),
                      color: snapshot.outstandingTotal > 0
                          ? const Color(0xFFF59E0B)
                          : AppColors.tertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.stackSm),
                  Expanded(
                    child: _MoneyChip(
                      label: 'PAID',
                      value: _money(snapshot.paidTotal),
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Text('Invoices', style: AppTypography.labelCaps),
        const SizedBox(height: AppSpacing.stackSm),
        if (snapshot.invoices.isEmpty)
          Text('No invoices yet.',
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant))
        else
          for (final inv in snapshot.invoices) ...[
            _InvoiceTile(inv: inv, onMarkPaid: () => onMarkPaid(inv)),
            const SizedBox(height: AppSpacing.stackSm),
          ],
      ],
    );
  }
}

class _MoneyChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MoneyChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.labelCaps.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTypography.titleLg
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final InvoiceSummary inv;
  final VoidCallback onMarkPaid;
  const _InvoiceTile({required this.inv, required this.onMarkPaid});

  @override
  Widget build(BuildContext context) {
    final isPaid = inv.status == 'paid';
    final isOverdue = inv.isOverdue;
    final statusColor = isPaid
        ? AppColors.tertiary
        : (isOverdue ? AppColors.error : const Color(0xFFF59E0B));
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(inv.title, style: AppTypography.bodyLg),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  isOverdue && !isPaid
                      ? 'OVERDUE'
                      : inv.status.toUpperCase(),
                  style: AppTypography.labelMd
                      .copyWith(color: statusColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Due ${_fmt(inv.dueDate)} · ${_money(inv.amount)} billed · ${_money(inv.balance)} balance',
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: isPaid ? 'Paid' : 'Mark as paid',
                  onPressed: isPaid ? null : onMarkPaid,
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Expanded(
                child: GhostButton(
                  label: 'Keep pending',
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, "0")}/${d.month.toString().padLeft(2, "0")}/${d.year}';
}
