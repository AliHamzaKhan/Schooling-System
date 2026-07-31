import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/student_routes.dart';
import '../../../../../widgets/skeletons.dart';
import '../controller/notes_controller.dart';
import '../controller/reader_controller.dart';

/// The Notes track: a list of standalone notes; each opens in the reader.
class NotesListView extends GetView<NotesController> {
  const NotesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 5, height: 64));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        if (controller.notes.isEmpty) {
          return Center(
              child: Text('No notes yet.', style: AppTypography.bodyLg));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackLg,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackXl),
          itemCount: controller.notes.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.stackSm),
          itemBuilder: (_, i) {
            final n = controller.notes[i];
            return GlassSurface(
              onTap: () => Get.toNamed(
                StudentRoutes.courseReader,
                arguments: ReaderArgs.note(noteId: n.id, title: n.title),
              ),
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              child: Row(
                children: [
                  const Icon(Icons.sticky_note_2_outlined,
                      color: AppColors.tertiary),
                  const SizedBox(width: AppSpacing.stackMd),
                  Expanded(child: Text(n.title, style: AppTypography.bodyLg)),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.onSurfaceVariant),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
