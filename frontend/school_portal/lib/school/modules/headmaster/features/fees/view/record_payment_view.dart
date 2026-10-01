import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_search_field.dart';
import '../../../data/headmaster_repository.dart';
import '../models/student_fee_snapshot.dart';
import '../../../../../widgets/skeletons.dart';

/// Record Payment — full-page. Headmaster searches by student name / father /
/// class, picks a student, and records a manual cash/bank/cheque payment.
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
  final _saving = <String>{}.obs;

  /// Invoices whose last payment attempt has an unknown outcome (timeout or
  /// server error). Kept on screen until a refresh shows the invoice paid.
  final _uncertain = <String>{}.obs;
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
    if (_saving.contains(inv.id)) return;
    final intent = await showModalBottomSheet<_ManualPayment>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ManualPaymentSheet(balance: inv.balance),
    );
    if (intent == null || !mounted) return;
    _saving.add(inv.id);
    try {
      String? proofUrl;
      if (intent.proof != null) {
        final proof = intent.proof!;
        final upload = await _repo.uploadImage(
          folder: 'payment_proofs',
          filePath: proof.path,
          bytes: proof.path == null ? proof.bytes : null,
          filename: proof.name,
          contentType: _contentTypeFor(proof.extension),
        );
        if (!upload.success || upload.data == null) {
          if (mounted) {
            Get.snackbar(
              'Proof not saved',
              upload.error ?? 'The payment was not recorded.',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
          return;
        }
        proofUrl = upload.data;
      }
      final res = await _repo.recordPayment(
        invoiceId: inv.id,
        amount: intent.amount,
        method: intent.method,
        reference: intent.reference,
        note: intent.note,
        proofUrl: proofUrl,
      );
      if (!mounted) return;
      if (res.success) {
        _uncertain.remove(inv.id);
        Get.snackbar(
          'Payment recorded',
          'Recorded for "${inv.title}". Refreshing balances…',
          snackPosition: SnackPosition.BOTTOM,
        );
        // Refresh the current student so balances update in place.
        await _search(_query.value);
        _selected.value = _results.firstWhereOrNull(
          (r) => r.studentId == s.studentId,
        );
      } else {
        Get.snackbar(
          'Payment not confirmed',
          res.isNetworkError || res.isServerError
              ? 'The result is uncertain. Retry here to check the same payment; do not create another payment.'
              : (res.error ?? 'Please try again.'),
          snackPosition: SnackPosition.BOTTOM,
        );
        if (res.isNetworkError || res.isServerError) {
          // The server may have recorded it: re-read balances now, and keep a
          // visible warning on the invoice until it reads as paid.
          _uncertain.add(inv.id);
          await _search(_query.value);
          final refreshed = _results.firstWhereOrNull(
            (r) => r.studentId == s.studentId,
          );
          if (refreshed != null) _selected.value = refreshed;
          final now = refreshed?.invoices.firstWhereOrNull(
            (i) => i.id == inv.id,
          );
          if (now?.status == 'paid') _uncertain.remove(inv.id);
        }
      }
    } finally {
      _saving.remove(inv.id);
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
                  saving: _saving.toSet(),
                  uncertain: _uncertain.toSet(),
                  onBack: () => _selected.value = null,
                  onMarkPaid: (inv) => _markPaid(_selected.value!, inv),
                  onRequestAdjustment: (inv) =>
                      _requestInvoiceAdjustment(_selected.value!, inv),
                  onManageBillingContacts: () =>
                      _manageBillingContacts(_selected.value!),
                );
              }
              if (_loading.value && _results.isEmpty) {
                return const SkeletonPage(
                  withHeader: false,
                  body: SkeletonForm(fields: 3),
                );
              }
              if (_error.value != null) {
                return Center(
                  child: Text(_error.value!, style: AppTypography.bodyLg),
                );
              }
              if (_results.isEmpty) {
                return Center(
                  child: Text(
                    'No students match your search.',
                    style: AppTypography.bodyLg,
                  ),
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

  Future<void> _manageBillingContacts(StudentFeeSnapshot student) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BillingContactsSheet(
        repository: _repo,
        studentId: student.studentId,
        studentName: student.fullName,
      ),
    );
  }

  Future<void> _requestInvoiceAdjustment(
    StudentFeeSnapshot student,
    InvoiceSummary invoice,
  ) async {
    final requested = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InvoiceAdjustmentSheet(
        repository: _repo,
        studentName: student.fullName,
        invoice: invoice,
      ),
    );
    if (requested == true && mounted) {
      Get.snackbar(
        'Adjustment requested',
        'The request is pending Headmaster review. No balance has changed.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

String _contentTypeFor(String? extension) => switch (extension?.toLowerCase()) {
  'pdf' => 'application/pdf',
  'png' => 'image/png',
  'webp' => 'image/webp',
  _ => 'image/jpeg',
};

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
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                snapshot.fullName.isNotEmpty
                    ? snapshot.fullName[0].toUpperCase()
                    : '?',
                style: AppTypography.titleLg.copyWith(color: AppColors.primary),
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
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: AppTypography.labelMd.copyWith(
                            color: _statusColor(status),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${_money(snapshot.outstandingTotal)} due',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              AppIcons.chevronRightRounded,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentDetail extends StatelessWidget {
  final Set<String> saving;
  final Set<String> uncertain;
  final StudentFeeSnapshot snapshot;
  final VoidCallback onBack;
  final void Function(InvoiceSummary) onMarkPaid;
  final void Function(InvoiceSummary) onRequestAdjustment;
  final VoidCallback onManageBillingContacts;
  const _StudentDetail({
    required this.saving,
    required this.uncertain,
    required this.snapshot,
    required this.onBack,
    required this.onMarkPaid,
    required this.onRequestAdjustment,
    required this.onManageBillingContacts,
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
          icon: const Icon(AppIcons.arrowBackRounded, size: 18),
          label: const Text('Back to search'),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.stackLg),
          decoration: BoxDecoration(
            color: AppColors.card,
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
                Text(
                  "Father: ${snapshot.fatherName}",
                  style: AppTypography.bodyMd,
                ),
              if (snapshot.className != null)
                Text(
                  "Class: ${snapshot.className}${snapshot.sectionName != null ? " · ${snapshot.sectionName}" : ""}",
                  style: AppTypography.bodyMd,
                ),
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
              const SizedBox(height: AppSpacing.stackMd),
              OutlinedButton.icon(
                onPressed: onManageBillingContacts,
                icon: const Icon(AppIcons.personOutlineRounded),
                label: const Text('Manage guardian billing details'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Text('Invoices', style: AppTypography.labelCaps),
        const SizedBox(height: AppSpacing.stackSm),
        if (snapshot.invoices.isEmpty)
          Text(
            'No invoices yet.',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          )
        else
          for (final inv in snapshot.invoices) ...[
            _InvoiceTile(
              inv: inv,
              saving: saving.contains(inv.id),
              uncertain: uncertain.contains(inv.id) && inv.status != 'paid',
              onMarkPaid: () => onMarkPaid(inv),
              onRequestAdjustment: () => onRequestAdjustment(inv),
            ),
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
          Text(label, style: AppTypography.labelCaps.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleLg.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final bool saving;
  final bool uncertain;
  final InvoiceSummary inv;
  final VoidCallback onMarkPaid;
  final VoidCallback onRequestAdjustment;
  const _InvoiceTile({
    required this.inv,
    required this.onMarkPaid,
    required this.onRequestAdjustment,
    required this.saving,
    this.uncertain = false,
  });

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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(inv.title, style: AppTypography.bodyLg)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  isOverdue && !isPaid ? 'OVERDUE' : inv.status.toUpperCase(),
                  style: AppTypography.labelMd.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Due ${_fmt(inv.dueDate)} · ${_money(inv.amount)} billed · ${_money(inv.balance)} balance',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (uncertain) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Semantics(
              liveRegion: true,
              child: Text(
                'The last payment attempt did not confirm. It may already be '
                'recorded. Use Check payment to retry the same payment; do not '
                'record it again elsewhere.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.error),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.stackSm),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isPaid || saving ? null : onMarkPaid,
              child: Text(
                saving
                    ? 'Recording…'
                    : (isPaid
                          ? 'Paid'
                          : (uncertain ? 'Check payment' : 'Mark as paid')),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: saving ? null : onRequestAdjustment,
              child: const Text('Request refund, credit, or waiver'),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, "0")}/${d.month.toString().padLeft(2, "0")}/${d.year}';
}

class _ManualPayment {
  final double amount;
  final String method;
  final String? reference;
  final String? note;
  final PlatformFile? proof;

  const _ManualPayment({
    required this.amount,
    required this.method,
    this.reference,
    this.note,
    this.proof,
  });
}

class _ManualPaymentSheet extends StatefulWidget {
  final double balance;
  const _ManualPaymentSheet({required this.balance});

  @override
  State<_ManualPaymentSheet> createState() => _ManualPaymentSheetState();
}

class _ManualPaymentSheetState extends State<_ManualPaymentSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.balance.toStringAsFixed(2),
  );
  final _reference = TextEditingController();
  final _note = TextEditingController();
  String _method = 'bank_transfer';
  PlatformFile? _proof;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );
    if (result?.files.singleOrNull case final proof?) {
      setState(() => _proof = proof);
    }
  }

  void _save() {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0 || amount > widget.balance) {
      setState(() => _error = 'Enter an amount up to the remaining balance.');
      return;
    }
    Navigator.of(context).pop(
      _ManualPayment(
        amount: amount,
        method: _method,
        reference: _reference.text,
        note: _note.text,
        proof: _proof,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackLg,
          AppSpacing.containerPaddingMobile,
          bottom + AppSpacing.stackLg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record manual payment', style: AppTypography.titleLg),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                'Record only a payment you have verified. A bank screenshot is evidence, not automatic confirmation.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              DropdownButtonFormField<String>(
                initialValue: _method,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Payment method'),
                items: const [
                  DropdownMenuItem(
                    value: 'bank_transfer',
                    child: Text('Bank transfer'),
                  ),
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                ],
                onChanged: (value) =>
                    setState(() => _method = value ?? _method),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              TextField(
                controller: _reference,
                decoration: const InputDecoration(
                  labelText: 'Bank / cheque reference (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              TextField(
                controller: _note,
                maxLength: 255,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              TextButton.icon(
                onPressed: _pickProof,
                icon: const Icon(AppIcons.uploadRounded),
                label: Text(
                  _proof == null
                      ? 'Attach bank screenshot or PDF'
                      : _proof!.name,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  _error!,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.stackMd),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Record payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceAdjustmentSheet extends StatefulWidget {
  final HeadmasterRepository repository;
  final String studentName;
  final InvoiceSummary invoice;

  const _InvoiceAdjustmentSheet({
    required this.repository,
    required this.studentName,
    required this.invoice,
  });

  @override
  State<_InvoiceAdjustmentSheet> createState() =>
      _InvoiceAdjustmentSheetState();
}

class _InvoiceAdjustmentSheetState extends State<_InvoiceAdjustmentSheet> {
  late final TextEditingController _amount = TextEditingController(
    text:
        (widget.invoice.balance > 0
                ? widget.invoice.balance
                : widget.invoice.amount)
            .toStringAsFixed(2),
  );
  final _currency = TextEditingController();
  final _reason = TextEditingController();
  String _kind = 'credit';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _currency.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amount.text.trim());
    final currency = _currency.text.trim().toUpperCase();
    final reason = _reason.text.trim();
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a positive proposed amount.');
      return;
    }
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
      setState(() => _error = 'Enter a three-letter currency code.');
      return;
    }
    if (reason.length < 3) {
      setState(() => _error = 'Give a reason with at least 3 characters.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await widget.repository.createFinancialAdjustment(
      kind: _kind,
      targetId: widget.invoice.id,
      proposedAmount: _amount.text.trim(),
      currencyCode: currency,
      reason: reason,
    );
    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _error = result.error ?? 'Could not submit the adjustment request.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackLg,
          AppSpacing.containerPaddingMobile,
          bottom + AppSpacing.stackLg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Request invoice adjustment', style: AppTypography.titleLg),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                '${widget.studentName} · ${widget.invoice.title}',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Text(
                  'This creates an approval request only. It does not change the invoice balance or record a payment.',
                  style: AppTypography.bodyMd,
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              DropdownButtonFormField<String>(
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'Adjustment type'),
                items: const [
                  DropdownMenuItem(value: 'refund', child: Text('Refund')),
                  DropdownMenuItem(value: 'credit', child: Text('Credit')),
                  DropdownMenuItem(value: 'waiver', child: Text('Waiver')),
                ],
                onChanged: (value) => setState(() => _kind = value ?? _kind),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Proposed amount'),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              TextField(
                controller: _currency,
                textCapitalization: TextCapitalization.characters,
                maxLength: 3,
                decoration: const InputDecoration(
                  labelText: 'Currency code',
                  hintText: 'For example: PKR',
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              TextField(
                controller: _reason,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  _error!,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.stackMd),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(
                    _submitting
                        ? 'Submitting…'
                        : 'Submit for Headmaster review',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BillingContactsSheet extends StatefulWidget {
  final HeadmasterRepository repository;
  final String studentId;
  final String studentName;

  const _BillingContactsSheet({
    required this.repository,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<_BillingContactsSheet> createState() => _BillingContactsSheetState();
}

class _BillingContactsSheetState extends State<_BillingContactsSheet> {
  List<Map<String, dynamic>> _guardians = const [];
  Map<String, Map<String, dynamic>> _contacts = const {};
  bool _loading = true;
  String? _error;

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
    final results = await Future.wait([
      widget.repository.loadBillingContactCandidates(widget.studentId),
      widget.repository.loadBillingContacts(widget.studentId),
    ]);
    if (!mounted) return;
    final guardians = results[0];
    final contacts = results[1];
    if (!guardians.success || guardians.data == null) {
      setState(() {
        _loading = false;
        _error = guardians.error ?? 'Could not load linked guardians.';
      });
      return;
    }
    if (!contacts.success || contacts.data == null) {
      setState(() {
        _loading = false;
        _error = contacts.error ?? 'Could not load billing details.';
      });
      return;
    }
    setState(() {
      _loading = false;
      _guardians = guardians.data!;
      _contacts = {
        for (final contact in contacts.data!)
          '${contact['guardian_id']}': contact,
      };
    });
  }

  Future<void> _edit(
    Map<String, dynamic> guardian,
    Map<String, dynamic>? contact,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BillingContactEditorSheet(
        repository: widget.repository,
        studentId: widget.studentId,
        guardian: guardian,
        contact: contact,
      ),
    );
    if (saved == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackLg,
          AppSpacing.containerPaddingMobile,
          bottom + AppSpacing.stackLg,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Guardian billing details', style: AppTypography.titleLg),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                'Set the billing contact and payer reference for ${widget.studentName}. Only linked guardians can be selected.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.stackSm),
            OutlinedButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (_guardians.isEmpty) {
      return Center(
        child: Text(
          'No guardians are linked to this student yet.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _guardians.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.stackSm),
      itemBuilder: (_, index) {
        final guardian = _guardians[index];
        final contact = _contacts['${guardian['guardian_id']}'];
        final isPrimary = contact?['is_primary'] == true;
        final relationship = guardian['relationship']?.toString();
        final detail =
            contact?['billing_email']?.toString().trim().isNotEmpty == true
            ? contact!['billing_email'].toString()
            : guardian['email']?.toString() ?? '';
        return Container(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      guardian['full_name']?.toString() ?? 'Guardian',
                      style: AppTypography.bodyLg,
                    ),
                  ),
                  if (isPrimary)
                    Text(
                      'PRIMARY PAYER',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
              if (relationship?.isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  relationship!,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              if (detail.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.stackSm),
              OutlinedButton(
                onPressed: () => _edit(guardian, contact),
                child: Text(
                  contact == null
                      ? 'Set billing details'
                      : 'Edit billing details',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BillingContactEditorSheet extends StatefulWidget {
  final HeadmasterRepository repository;
  final String studentId;
  final Map<String, dynamic> guardian;
  final Map<String, dynamic>? contact;

  const _BillingContactEditorSheet({
    required this.repository,
    required this.studentId,
    required this.guardian,
    required this.contact,
  });

  @override
  State<_BillingContactEditorSheet> createState() =>
      _BillingContactEditorSheetState();
}

class _BillingContactEditorSheetState
    extends State<_BillingContactEditorSheet> {
  late final TextEditingController _email = TextEditingController(
    text:
        widget.contact?['billing_email']?.toString() ??
        widget.guardian['email']?.toString() ??
        '',
  );
  late final TextEditingController _phone = TextEditingController(
    text:
        widget.contact?['billing_phone']?.toString() ??
        widget.guardian['phone']?.toString() ??
        '',
  );
  late final TextEditingController _reference = TextEditingController(
    text: widget.contact?['payer_reference']?.toString() ?? '',
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.contact?['note']?.toString() ?? '',
  );
  late bool _primary = widget.contact?['is_primary'] == true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await widget.repository.saveBillingContact(
      studentId: widget.studentId,
      guardianId: '${widget.guardian['guardian_id']}',
      billingEmail: _optional(_email),
      billingPhone: _optional(_phone),
      payerReference: _optional(_reference),
      isPrimary: _primary,
      note: _optional(_note),
    );
    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = result.error ?? 'Could not save billing details.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final guardianName = widget.guardian['full_name']?.toString() ?? 'Guardian';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackLg,
          AppSpacing.containerPaddingMobile,
          bottom + AppSpacing.stackLg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Billing details for $guardianName',
                style: AppTypography.titleLg,
              ),
              const SizedBox(height: AppSpacing.stackLg),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Billing email'),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Billing phone'),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              TextField(
                controller: _reference,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Payer reference (optional)',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _primary,
                onChanged: (value) => setState(() => _primary = value),
                title: const Text('Primary payer'),
                subtitle: const Text(
                  'This replaces any current primary payer.',
                ),
              ),
              TextField(
                controller: _note,
                maxLength: 255,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Internal note (optional)',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  _error!,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.stackMd),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save billing details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
