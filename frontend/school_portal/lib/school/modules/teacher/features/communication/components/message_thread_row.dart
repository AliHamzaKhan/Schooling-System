import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/message_thread.dart';

/// One thread in the Communication Center: avatar, name + preview + time, and
/// a colored party badge (PARENT / STUDENT / STAFF). Unread threads sit in a
/// soft wash with a left accent rail in the party's color.
class MessageThreadRow extends StatelessWidget {
  final MessageThread thread;
  final VoidCallback? onTap;

  const MessageThreadRow({super.key, required this.thread, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = thread;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.stackMd, vertical: AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: t.unread ? AppColors.surfaceContainerLow : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: t.unread
              ? Border(left: BorderSide(color: t.party.color, width: 3))
              : const Border(
                  bottom: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: Row(
          children: [
            _Avatar(thread: t),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(t.senderName,
                            style: AppTypography.titleMd
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                      Text(t.time, style: AppTypography.bodySm),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(t.preview,
                      style: AppTypography.bodyLg, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  _PartyBadge(party: t.party),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final MessageThread thread;
  const _Avatar({required this.thread});

  @override
  Widget build(BuildContext context) {
    if (thread.avatarIcon != null) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: thread.party.color.withValues(alpha: 0.18),
        child: Icon(thread.avatarIcon, color: thread.party.color, size: 20),
      );
    }
    if (thread.avatarUrl != null) {
      return CircleAvatar(radius: 22, backgroundImage: schoolImage(thread.avatarUrl!));
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: thread.party.color.withValues(alpha: 0.18),
      child: Text(thread.initial,
          style: AppTypography.titleMd.copyWith(color: thread.party.color)),
    );
  }
}

class _PartyBadge extends StatelessWidget {
  final ThreadParty party;
  const _PartyBadge({required this.party});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: party.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(party.label,
          style: AppTypography.labelCaps.copyWith(
              color: party.color, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }
}
