import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Read-only operational evidence. This screen never retries a delivery or
/// turns provider acceptance into a confirmed delivery receipt.
class DeliveryReviewDialog extends StatefulWidget {
  final Future<ApiResponse<dynamic>> Function(int offset) load;
  const DeliveryReviewDialog({super.key, required this.load});

  @override
  State<DeliveryReviewDialog> createState() => _DeliveryReviewDialogState();
}

class _DeliveryReviewDialogState extends State<DeliveryReviewDialog> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _fetch(0);
  }

  Future<void> _fetch(int offset) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await widget.load(offset);
      if (!mounted) return;
      setState(() {
        if (response.success && response.data is Map) {
          _data = Map<String, dynamic>.from(response.data as Map);
          _offset = offset;
        } else {
          _error = response.error ?? 'Could not load delivery review.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load delivery review. Try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _status(String status) => status == 'sending'
      ? 'Attempt in progress — unconfirmed'
      : BroadcastOutcome(status).label;

  String _queue(String? state) => switch (state) {
    'pending' => 'Queued for worker',
    'processing' => 'Worker processing',
    'complete' => 'Processing complete — check outcomes below',
    'needs_review' => 'Manual investigation required',
    _ => 'Historical message — no durable worker record',
  };

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final message = data?['message'] as Map? ?? const {};
    final counts = data?['counts'] as Map? ?? const {};
    final items = data?['items'] as List? ?? const [];
    final outcome = BroadcastOutcome(message['status'] as String?);
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Delivery review',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close review',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text('Read-only • Recipient contact details are masked'),
              const Divider(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? ListView(
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                          TextButton(
                            onPressed: () => _fetch(_offset),
                            child: const Text('Try again'),
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          Text(
                            message['title'] as String? ?? 'Announcement',
                            style: AppTypography.titleLg,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  outcome.label,
                                  style: AppTypography.titleMd,
                                ),
                                Text(outcome.description),
                                const SizedBox(height: 12),
                                Text(_queue(data?['outbox_state'] as String?)),
                                Text(
                                  'Worker claims: ${data?['worker_attempts'] ?? 0} (not recipient sends)',
                                ),
                                if (data?['lease_expired'] == true)
                                  const Text(
                                    'Worker lease expired. Attempted deliveries may be uncertain; do not resend.',
                                  ),
                                if (data?['available_at'] != null &&
                                    data?['outbox_state'] == 'pending')
                                  Text(
                                    'Eligible after: ${data!['available_at']}',
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final entry in counts.entries)
                                if (entry.value is num && entry.value > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_status(entry.key.toString())}: ${entry.value}',
                                    ),
                                  ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${data?['total'] ?? 0} delivery records',
                            style: AppTypography.titleMd,
                          ),
                          const Text(
                            'One person may have multiple devices. These are attempt records, not unique people.',
                          ),
                          if (items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No delivery records on this page. Queued messages may not have a recipient snapshot yet.',
                              ),
                            ),
                          for (final item in items)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['recipient'] as String? ??
                                          'Unavailable recipient',
                                      style: AppTypography.titleMd,
                                    ),
                                    Text(
                                      item['address_label'] as String? ??
                                          'Contact details hidden',
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _status(
                                        item['status'] as String? ?? 'unknown',
                                      ),
                                    ),
                                    if (item['provider'] != null)
                                      Text('Provider: ${item['provider']}'),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          const Text(
                            'Unknown outcomes require provider evidence before any resend. No resend or “mark delivered” action is available here.',
                          ),
                        ],
                      ),
              ),
              const Divider(),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _loading ? null : () => _fetch(0),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                  TextButton(
                    onPressed: _loading || _offset == 0
                        ? null
                        : () => _fetch((_offset - 25).clamp(0, _offset)),
                    child: const Text('Previous'),
                  ),
                  TextButton(
                    onPressed:
                        _loading || _error != null || data?['has_more'] != true
                        ? null
                        : () => _fetch(_offset + 25),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
