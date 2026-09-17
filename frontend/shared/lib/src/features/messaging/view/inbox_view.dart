import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../ui/layout/app_scaffold.dart';
import '../../../ui/tokens/app_colors.dart';
import '../../../ui/tokens/app_radius.dart';
import '../../../ui/tokens/app_spacing.dart';
import '../../../ui/tokens/app_typography.dart';
import '../controller/inbox_controller.dart';
import '../models/conversation.dart';
import 'conversation_view.dart';
import 'messaging_format.dart';
import 'new_message_sheet.dart';
import 'package:shared/shared.dart';

/// Shared Messages inbox: a searchable list of conversations grouped by the
/// person on the other side. Mounted by any portal (teacher, guardian,
/// student, headmaster) — the backend scopes the list to the signed-in user.
///
/// Navigation to a thread and the new-message picker are handled internally via
/// GetX, so a portal only needs to route to this screen.
class InboxView extends StatefulWidget {
  /// Title shown in the header (e.g. 'Messages').
  final String title;

  /// Whether to show a back button in the header (true when pushed onto a
  /// stack, false when hosted inside a tab shell).
  final bool showBack;

  const InboxView({super.key, this.title = 'Messages', this.showBack = true});

  @override
  State<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<InboxView> {
  late final InboxController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(InboxController());
  }

  @override
  void dispose() {
    Get.delete<InboxController>();
    super.dispose();
  }

  Future<void> _openConversation(Conversation c) async {
    await Get.to<void>(() => ConversationView(
          counterpartId: c.counterpartId,
          counterpartName: c.counterpartName,
          // Derive reply context from the freshly loaded thread, not the
          // potentially stale inbox preview.
        ));
    // Coming back, refresh so read state / new replies show.
    await controller.load();
  }

  Future<void> _newMessage() async {
    final contact = await showNewMessageSheet(context);
    if (contact == null) return;
    await Get.to<void>(() => ConversationView(
          counterpartId: contact.id,
          counterpartName: contact.name,
        ));
    await controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _newMessage,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(AppIcons.editRounded),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.error.value != null &&
                  controller.conversations.isEmpty) {
                return _message(controller.error.value!);
              }
              final items = controller.visible;
              if (items.isEmpty) {
                return _message(controller.query.value.isEmpty
                    ? 'No conversations yet.\nTap the pencil to message someone.'
                    : 'No conversations match your search.');
              }
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(
                      height: 1, indent: 76, color: AppColors.outlineVariant),
                  itemBuilder: (_, i) => _row(items[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackSm,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.showBack)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.stackSm),
                    child: InkWell(
                      onTap: () => Get.back<void>(),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: const Icon(AppIcons.arrowBackRounded,
                          color: AppColors.onSurface),
                    ),
                  ),
                Text(widget.title,
                    style: AppTypography.headlineLg
                        .copyWith(color: AppColors.primary)),
                const Spacer(),
                Obx(() {
                  final n = controller.totalUnread;
                  if (n == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text('$n new',
                        style: AppTypography.labelMd
                            .copyWith(color: AppColors.onPrimary)),
                  );
                }),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            TextField(
              onChanged: controller.onSearch,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Search conversations…',
                prefixIcon: const Icon(AppIcons.searchRounded),
                filled: true,
                fillColor: AppColors.surfaceContainer,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(String text) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackXxl,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackMd),
          child: Column(
            children: [
              const Icon(AppIcons.forumOutlined,
                  size: 48, color: AppColors.outline),
              const SizedBox(height: AppSpacing.stackMd),
              Text(text,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLg
                      .copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(Conversation c) {
    return _ConversationRow(
      conversation: c,
      unread: controller.unreadFor(c),
      onTap: () => _openConversation(c),
    );
  }
}

/// A single inbox row. Kept separate so its unread count is computed from the
/// signed-in user consistently.
class _ConversationRow extends StatelessWidget {
  final Conversation conversation;
  final int unread;
  final VoidCallback onTap;

  const _ConversationRow({
    required this.conversation,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = unread;
    final last = conversation.last;
    final hasUnread = unreadCount > 0;
    final name = conversation.counterpartName.trim();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerPaddingMobile,
          vertical: AppSpacing.stackSm),
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primaryContainer,
        child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
            style: AppTypography.titleMd.copyWith(color: AppColors.onPrimary)),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(name.isEmpty ? 'Unknown' : name,
                style: AppTypography.titleMd.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis),
          ),
          Text(messagingRelativeTime(last.createdAt),
              style: AppTypography.bodySm.copyWith(
                  color: hasUnread ? AppColors.primary : AppColors.outline)),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            if (last.isComplaint)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child:
                    Icon(AppIcons.flagRounded, size: 13, color: AppColors.error),
              ),
            Expanded(
              child: Text(last.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd.copyWith(
                    color: hasUnread
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  )),
            ),
            if (hasUnread)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text('$unreadCount',
                    style: AppTypography.labelMd
                        .copyWith(color: AppColors.onPrimary, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}
