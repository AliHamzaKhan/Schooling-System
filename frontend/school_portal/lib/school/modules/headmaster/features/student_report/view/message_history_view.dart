import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../data/student_report_service.dart';
import '../models/direct_message_item.dart';
import '../../../../../widgets/skeletons.dart';

/// Arguments for [MessageHistoryView].
class MessageHistoryArgs {
  final String studentId;
  final String studentName;
  const MessageHistoryArgs({
    required this.studentId,
    required this.studentName,
  });
}

/// The staff member's sent messages/complaints about one student — the other
/// side of the guardian conversation, with delivery (read) state.
class MessageHistoryView extends StatefulWidget {
  const MessageHistoryView({super.key});

  @override
  State<MessageHistoryView> createState() => _MessageHistoryViewState();
}

class _MessageHistoryViewState extends State<MessageHistoryView> {
  static final _dt = DateTimeParserService();

  late final String _studentId;
  String _studentName = 'Student';
  bool _loading = true;
  String? _error;
  List<DirectMessageItem> _messages = const [];

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    final fromUrl = Get.parameters['student_id']?.trim() ?? '';
    _studentId = fromUrl.isNotEmpty
        ? fromUrl
        : (arg is MessageHistoryArgs ? arg.studentId : '');
    if (fromUrl.isEmpty && arg is MessageHistoryArgs) {
      _studentName = arg.studentName;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _messages = const [];
    });
    if (_studentId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'A valid student is required.';
      });
      return;
    }
    final service = StudentReportService();
    final report = await service.fetchReport(_studentId);
    if (!report.success || report.data == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = report.error ?? 'Student not found.';
      });
      return;
    }
    final res = await service.fetchSentMessages(studentId: _studentId);
    if (!mounted) return;
    setState(() {
      _studentName = report.data!.studentName;
      if (res.success) {
        _messages = res.data ?? const [];
      } else {
        _error = res.error ?? 'Could not load messages.';
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text('Messages · $_studentName')),
      body: _loading
          ? const SkeletonPage(withHeader: false, body: SkeletonThreadList())
          : _error != null
          ? AppStateView.error(
              title: 'Could not load message history',
              message: _error!,
              actionLabel: _studentId.isEmpty ? null : 'Try again',
              onAction: _studentId.isEmpty ? null : _load,
            )
          : _messages.isEmpty
          ? Center(
              child: Text(
                'No messages sent about this student yet.',
                style: AppTypography.bodyLg,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackMd,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackXl,
              ),
              itemCount: _messages.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.stackSm),
              itemBuilder: (context, i) =>
                  _MessageCard(message: _messages[i], dt: _dt),
            ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final DirectMessageItem message;
  final DateTimeParserService dt;
  const _MessageCard({required this.message, required this.dt});

  @override
  Widget build(BuildContext context) {
    final complaint = message.isComplaint;
    final accent = complaint ? const Color(0xFFE8A317) : AppColors.primary;
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  complaint ? 'Concern' : 'Message',
                  style: AppTypography.labelMd.copyWith(color: accent),
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Expanded(
                child: Text(
                  'To ${message.recipientName}',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                message.createdAt == null
                    ? ''
                    : dt.toRelative(message.createdAt!),
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(message.body, style: AppTypography.bodyLg),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                message.read ? AppIcons.doneAllRounded : AppIcons.doneRounded,
                size: 14,
                color: message.read
                    ? AppColors.tertiary
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                message.read ? 'Read' : 'Delivered',
                style: AppTypography.bodySm.copyWith(
                  color: message.read
                      ? AppColors.tertiary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
