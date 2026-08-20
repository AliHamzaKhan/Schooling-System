import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../controller/guardian_session_controller.dart';
import 'child_avatar.dart';

/// Multi-child switching UI — a horizontal strip of selectable child avatars
/// shown at the top of guardian screens. Selecting one updates the shared
/// [GuardianSessionController], which every feature reacts to.
///
/// Hidden automatically when the guardian has a single child. An optional
/// trailing "Manage" action opens the full Child Selection screen.
class ChildSwitcher extends StatelessWidget {
  final VoidCallback? onManage;
  const ChildSwitcher({super.key, this.onManage});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<GuardianSessionController>();
    return Obx(() {
      if (!session.hasMultiple) return const SizedBox.shrink();
      final children = session.children;
      final selectedId = session.selectedId.value;
      return SizedBox(
        height: 84,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.containerPaddingMobile),
          itemCount: children.length + (onManage != null ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.stackMd),
          itemBuilder: (context, i) {
            if (i == children.length) {
              return _ManageButton(onTap: onManage!);
            }
            final c = children[i];
            final selected = c.id == selectedId;
            return GestureDetector(
              onTap: () => session.select(c.id),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                width: 64,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ChildAvatar(child: c, size: 48),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.name.split(' ').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

class _ManageButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ManageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHigh,
              ),
              child: const Icon(AppIcons.tuneRounded,
                  size: 20, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text('Manage',
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
