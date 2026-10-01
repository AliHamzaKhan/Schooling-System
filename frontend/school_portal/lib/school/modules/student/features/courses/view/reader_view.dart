import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/skeletons.dart';
import '../controller/reader_controller.dart';

/// The reading screen for a book chapter or a note. Renders the text with
/// in-place search/find highlighting, saves the scroll position on the backend,
/// and — for notes — offers share/print. Book chapters get prev/next + a TOC.
class ReaderView extends GetView<ReaderController> {
  const ReaderView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.title.value.isEmpty ? 'Reading' : controller.title.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(AppIcons.searchRounded),
            onPressed: controller.toggleSearch,
          ),
          if (controller.args.isNote)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'share') controller.sharePdf();
                if (v == 'print') controller.printDoc();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                        leading: Icon(AppIcons.iosShareRounded),
                        title: Text('Share'))),
                PopupMenuItem(
                    value: 'print',
                    child: ListTile(
                        leading: Icon(AppIcons.printOutlined),
                        title: Text('Print'))),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Obx(() => controller.searchOpen.value
              ? _SearchBar(controller: controller)
              : const SizedBox.shrink()),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const SkeletonPage(
                    withHeader: false, body: SkeletonCardList(count: 5, height: 60));
              }
              if (controller.error.value != null) {
                return Center(
                    child: Text(controller.error.value!,
                        style: AppTypography.bodyLg));
              }
              return _ReaderBody(controller: controller);
            }),
          ),
          if (controller.isBook) _ChapterNavBar(controller: controller),
        ],
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final ReaderController controller;
  const _SearchBar({required this.controller});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> with ScreenTextControllers {
  ReaderController get controller => widget.controller;

  // Owned by this bar — created with it, disposed with it.
  late final _searchCtrl = boundController(controller.query);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(AppSpacing.stackMd, 8, AppSpacing.stackSm, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: controller.runSearch,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Find in text…',
                prefixIcon: Icon(AppIcons.searchRounded, size: 18),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Obx(() {
            final n = controller.matches.length;
            final i = controller.activeMatch.value;
            return Text(
              n == 0 ? '0/0' : '${i + 1}/$n',
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            );
          }),
          IconButton(
            tooltip: 'Previous match',
            icon: const Icon(AppIcons.keyboardArrowUpRounded),
            onPressed: controller.findPrev,
          ),
          IconButton(
            tooltip: 'Next match',
            icon: const Icon(AppIcons.keyboardArrowDownRounded),
            onPressed: controller.findNext,
          ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(AppIcons.closeRounded),
            onPressed: controller.toggleSearch,
          ),
        ],
      ),
    );
  }
}

class _ReaderBody extends StatelessWidget {
  final ReaderController controller;
  const _ReaderBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final query = controller.query.value;
      final active = controller.activeMatch.value;
      final activeLoc = (active >= 0 && active < controller.matches.length)
          ? controller.matches[active]
          : null;
      final paras = controller.paragraphs;
      return ListView.builder(
        controller: controller.scroll,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackLg,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackXxl),
        itemCount: paras.length,
        itemBuilder: (_, i) {
          final activeStart =
              (activeLoc != null && activeLoc.paragraph == i) ? activeLoc.start : -1;
          return Padding(
            key: i < controller.paragraphKeys.length
                ? controller.paragraphKeys[i]
                : null,
            padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
            child: SelectableText.rich(
              TextSpan(
                children: _spansFor(paras[i], query, activeStart),
              ),
              style: AppTypography.bodyLg.copyWith(height: 1.55),
            ),
          );
        },
      );
    });
  }

  /// Splits [text] into styled spans, highlighting every case-insensitive
  /// occurrence of [query]; the occurrence at [activeStart] gets a stronger tint.
  List<TextSpan> _spansFor(String text, String query, int activeStart) {
    if (query.trim().isEmpty) return [TextSpan(text: text)];
    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final needle = query.toLowerCase();
    var from = 0;
    while (true) {
      final idx = lower.indexOf(needle, from);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(from)));
        break;
      }
      if (idx > from) spans.add(TextSpan(text: text.substring(from, idx)));
      final isActive = idx == activeStart;
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          backgroundColor: isActive
              ? const Color(0xFFE8A317)
              : const Color(0x55E8A317),
          fontWeight: FontWeight.w700,
        ),
      ));
      from = idx + query.length;
    }
    return spans;
  }
}

class _ChapterNavBar extends StatelessWidget {
  final ReaderController controller;
  const _ChapterNavBar({required this.controller});

  void _openToc(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var i = 0; i < controller.args.chapters.length; i++)
              Obx(() => ListTile(
                    selected: i == controller.chapterIndex.value,
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text('${i + 1}',
                          style: AppTypography.labelMd),
                    ),
                    title: Text(controller.args.chapters[i].title),
                    onTap: () {
                      Get.back<void>();
                      controller.jumpToChapter(controller.args.chapters[i].id);
                    },
                  )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Obx(() => Row(
                children: [
                  IconButton(
                    tooltip: 'Previous',
                    icon: const Icon(AppIcons.chevronLeftRounded),
                    onPressed: controller.hasPrev ? controller.goPrevChapter : null,
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _openToc(context),
                      child: Text(
                        'Chapter ${controller.chapterIndex.value + 1} '
                        'of ${controller.args.chapters.length}',
                        style: AppTypography.labelMd,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next',
                    icon: const Icon(AppIcons.chevronRightRounded),
                    onPressed: controller.hasNext ? controller.goNextChapter : null,
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
