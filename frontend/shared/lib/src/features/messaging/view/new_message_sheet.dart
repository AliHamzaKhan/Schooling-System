import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../ui/tokens/app_colors.dart';
import '../../../ui/tokens/app_radius.dart';
import '../../../ui/tokens/app_spacing.dart';
import '../../../ui/tokens/app_typography.dart';
import '../controller/new_message_controller.dart';
import '../models/messaging_contact.dart';
import 'messaging_format.dart';

/// Opens the contact picker as a bottom sheet and resolves to the chosen
/// [MessagingContact], or null if dismissed.
Future<MessagingContact?> showNewMessageSheet(BuildContext context) {
  return showModalBottomSheet<MessagingContact>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (_) => const _NewMessageSheet(),
  );
}

class _NewMessageSheet extends StatefulWidget {
  const _NewMessageSheet();

  @override
  State<_NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends State<_NewMessageSheet> {
  final _tag = UniqueKey().toString();
  late final NewMessageController controller =
      Get.put(NewMessageController(), tag: _tag);

  @override
  void dispose() {
    Get.delete<NewMessageController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackMd,
                AppSpacing.containerPaddingMobile,
                0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('New message',
                      style: AppTypography.titleLg
                          .copyWith(color: AppColors.onSurface)),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                TextField(
                  onChanged: controller.onSearch,
                  style:
                      AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search people…',
                    prefixIcon: const Icon(Icons.search_rounded),
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
                const SizedBox(height: AppSpacing.stackSm),
                Expanded(
                  child: Obx(() {
                    if (controller.loading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.error.value != null) {
                      return Center(
                        child: Text(controller.error.value!,
                            style: AppTypography.bodyMd
                                .copyWith(color: AppColors.error)),
                      );
                    }
                    final people = controller.visible;
                    if (people.isEmpty) {
                      return Center(
                        child: Text('No one to message here yet.',
                            style: AppTypography.bodyMd),
                      );
                    }
                    return ListView.separated(
                      itemCount: people.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.outlineVariant),
                      itemBuilder: (_, i) => _tile(people[i]),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(MessagingContact c) {
    final color = messagingRoleColor(c.role);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Text(c.initial,
            style: AppTypography.labelMd.copyWith(color: color)),
      ),
      title: Text(c.name,
          style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface)),
      subtitle: Text(c.roleLabel, style: AppTypography.bodySm),
      onTap: () => Navigator.of(context).pop(c),
    );
  }
}
