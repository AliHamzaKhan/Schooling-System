import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../ui/layout/app_scaffold.dart';
import '../../../ui/tokens/app_colors.dart';
import '../../../ui/tokens/app_radius.dart';
import '../../../ui/tokens/app_spacing.dart';
import '../../../ui/tokens/app_typography.dart';
import '../controller/conversation_controller.dart';
import '../models/direct_message.dart';
import 'messaging_format.dart';

/// One conversation thread with a single counterpart: a scrollable list of
/// chat bubbles above a compose bar. Reachable from the inbox or by starting a
/// new message with a contact.
class ConversationView extends StatefulWidget {
  final String counterpartId;
  final String counterpartName;
  final String? studentId;

  const ConversationView({
    super.key,
    required this.counterpartId,
    required this.counterpartName,
    this.studentId,
  });

  @override
  State<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> {
  late final ConversationController controller;
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _tag = UniqueKey().toString();
  Worker? _scrollWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      ConversationController(
        counterpartId: widget.counterpartId,
        counterpartName: widget.counterpartName,
        studentId: widget.studentId,
      ),
      tag: _tag,
    );
    // Jump to the newest message whenever the thread changes.
    _scrollWorker =
        ever<List<DirectMessage>>(controller.messages, (_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _scrollWorker?.dispose();
    _composer.dispose();
    _scroll.dispose();
    Get.delete<ConversationController>(tag: _tag);
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _composer.text;
    if (text.trim().isEmpty) return;
    final ok = await controller.send(text);
    if (ok) {
      _composer.clear();
    } else if (controller.error.value != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.error.value!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          _topBar(),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.messages.isEmpty) {
                return _empty();
              }
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackMd,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackMd),
                itemCount: controller.messages.length,
                itemBuilder: (_, i) => _bubble(controller.messages[i]),
              );
            }),
          ),
          _composerBar(),
        ],
      ),
    );
  }

  Widget _topBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.stackSm, AppSpacing.stackSm,
            AppSpacing.containerPaddingMobile, AppSpacing.stackSm),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.onSurface,
              onPressed: () => Get.back<void>(),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                widget.counterpartName.trim().isEmpty
                    ? '?'
                    : widget.counterpartName.trim()[0].toUpperCase(),
                style: AppTypography.labelMd.copyWith(color: AppColors.onPrimary),
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: Text(
                widget.counterpartName,
                style: AppTypography.titleMd.copyWith(color: AppColors.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 44, color: AppColors.outline),
            const SizedBox(height: AppSpacing.stackMd),
            Text('No messages yet.',
                style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: AppSpacing.stackSm),
            Text('Say hello — your message starts the conversation.',
                textAlign: TextAlign.center, style: AppTypography.bodySm),
          ],
        ),
      ),
    );
  }

  Widget _bubble(DirectMessage m) {
    final mine = m.sentByMe(controller.me);
    final bg = mine ? AppColors.primary : AppColors.surfaceContainerHigh;
    final fg = mine ? AppColors.onPrimary : AppColors.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.76),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.stackMd, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.card),
                topRight: const Radius.circular(AppRadius.card),
                bottomLeft: Radius.circular(mine ? AppRadius.card : 4),
                bottomRight: Radius.circular(mine ? 4 : AppRadius.card),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (m.isComplaint)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_rounded,
                            size: 13,
                            color: mine ? AppColors.onPrimary : AppColors.error),
                        const SizedBox(width: 4),
                        Text('Concern',
                            style: AppTypography.labelCaps.copyWith(
                                color: mine
                                    ? AppColors.onPrimary
                                    : AppColors.error)),
                      ],
                    ),
                  ),
                Text(m.body,
                    style: AppTypography.bodyMd.copyWith(color: fg)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Text(messagingClock(m.createdAt),
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.outline, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _composerBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.stackMd, AppSpacing.stackSm,
            AppSpacing.stackMd, AppSpacing.stackSm),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _composer,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Write a message…',
                  hintStyle:
                      AppTypography.bodyMd.copyWith(color: AppColors.outline),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.stackMd, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Obx(() => _SendButton(
                  sending: controller.sending.value,
                  onTap: _send,
                )),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool sending;
  final VoidCallback onTap;
  const _SendButton({required this.sending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: sending ? null : onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: sending
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: AppColors.onPrimary),
                )
              : const Icon(Icons.send_rounded,
                  color: AppColors.onPrimary, size: 20),
        ),
      ),
    );
  }
}
