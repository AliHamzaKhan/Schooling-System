import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/student_repository.dart';
import '../models/course_models.dart';

/// What the reader should open: a book chapter (with prev/next navigation across
/// the book's chapters) or a standalone note.
class ReaderArgs {
  final bool isNote;
  final String heading; // book title, or note's course context
  final String? bookId;
  final List<ChapterBrief> chapters;
  final String? initialChapterId;
  final String? noteId;
  final String noteTitle;

  const ReaderArgs._({
    required this.isNote,
    required this.heading,
    this.bookId,
    this.chapters = const [],
    this.initialChapterId,
    this.noteId,
    this.noteTitle = '',
  });

  factory ReaderArgs.book({
    required String bookId,
    required String bookTitle,
    required List<ChapterBrief> chapters,
    String? initialChapterId,
  }) =>
      ReaderArgs._(
        isNote: false,
        heading: bookTitle,
        bookId: bookId,
        chapters: chapters,
        initialChapterId: initialChapterId,
      );

  factory ReaderArgs.note({required String noteId, required String title}) =>
      ReaderArgs._(isNote: true, heading: 'Note', noteId: noteId, noteTitle: title);
}

/// A single search hit: which paragraph, and where within it.
class ReaderMatch {
  final int paragraph;
  final int start;
  final int length;
  const ReaderMatch(this.paragraph, this.start, this.length);
}

/// Powers the reading screen for both book chapters and notes: loads the text,
/// remembers the scroll position on the backend, and provides in-text
/// search/find. Notes can additionally be shared or printed.
class ReaderController extends GetxController {
  final StudentRepository _repo;
  final ReaderArgs args;
  ReaderController(this.args, {StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final error = RxnString();

  /// The current piece's title (chapter title, or note title).
  final title = ''.obs;
  final paragraphs = <String>[].obs;
  List<GlobalKey> paragraphKeys = const [];

  final scroll = ScrollController();

  // Book navigation.
  final chapterIndex = 0.obs;
  String? _currentChapterId;

  // Search state.
  final searchOpen = false.obs;

  /// Search text. The `TextEditingController` behind it belongs to the search
  /// bar's State — clearing it here flows back into the field.
  final query = ''.obs;
  final matches = <ReaderMatch>[].obs;
  final activeMatch = (-1).obs;

  Timer? _saveDebounce;
  int _restorePage = 0;

  bool get isBook => !args.isNote;

  @override
  void onInit() {
    super.onInit();
    scroll.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void onClose() {
    _saveDebounce?.cancel();
    _saveProgressNow();
    scroll.removeListener(_onScroll);
    scroll.dispose();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    // Resolve the saved position first so we can restore scroll / chapter.
    final resourceId = args.isNote ? args.noteId! : args.bookId!;
    final prog = await _repo.loadReadingProgress(
        resourceType: args.isNote ? 'note' : 'book', resourceId: resourceId);
    String? startChapter = args.initialChapterId;
    if (prog.success && prog.data != null) {
      _restorePage = prog.data!.page;
      if (isBook && args.initialChapterId == null && prog.data!.chapterId != null) {
        startChapter = prog.data!.chapterId;
      }
    }
    if (isBook) {
      final idx = startChapter == null
          ? 0
          : args.chapters.indexWhere((c) => c.id == startChapter);
      chapterIndex.value = idx < 0 ? 0 : idx;
      await _loadChapter(chapterIndex.value, restore: true);
    } else {
      await _loadNote(restore: true);
    }
  }

  // ------------------------------ loading ------------------------------ #

  Future<void> _loadChapter(int index, {bool restore = false}) async {
    if (index < 0 || index >= args.chapters.length) return;
    loading.value = true;
    error.value = null;
    _clearSearch();
    final res = await _repo.loadChapter(args.chapters[index].id);
    if (res.success && res.data != null) {
      _currentChapterId = res.data!.id;
      title.value = res.data!.title;
      _setContent(res.data!.content);
    } else {
      error.value = res.error ?? 'Could not load this chapter.';
    }
    loading.value = false;
    _afterLayout(restore: restore);
  }

  Future<void> _loadNote({bool restore = false}) async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadNote(args.noteId!);
    if (res.success && res.data != null) {
      title.value = res.data!.title;
      _setContent(res.data!.content);
    } else {
      error.value = res.error ?? 'Could not load this note.';
    }
    loading.value = false;
    _afterLayout(restore: restore);
  }

  void _setContent(String content) {
    final paras = content
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    paragraphs.assignAll(paras);
    paragraphKeys = List.generate(paras.length, (_) => GlobalKey());
  }

  void _afterLayout({required bool restore}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      if (restore && _restorePage > 0) {
        final max = scroll.position.maxScrollExtent;
        scroll.jumpTo(_restorePage.toDouble().clamp(0, max));
      }
    });
  }

  // ---------------------------- book chapters -------------------------- #

  bool get hasPrev => isBook && chapterIndex.value > 0;
  bool get hasNext => isBook && chapterIndex.value < args.chapters.length - 1;

  Future<void> goPrevChapter() async {
    if (!hasPrev) return;
    _saveProgressNow();
    _restorePage = 0;
    chapterIndex.value -= 1;
    scroll.jumpTo(0);
    await _loadChapter(chapterIndex.value);
  }

  Future<void> goNextChapter() async {
    if (!hasNext) return;
    _saveProgressNow();
    _restorePage = 0;
    chapterIndex.value += 1;
    scroll.jumpTo(0);
    await _loadChapter(chapterIndex.value);
  }

  Future<void> jumpToChapter(String chapterId) async {
    final idx = args.chapters.indexWhere((c) => c.id == chapterId);
    if (idx < 0 || idx == chapterIndex.value) return;
    _saveProgressNow();
    _restorePage = 0;
    chapterIndex.value = idx;
    scroll.jumpTo(0);
    await _loadChapter(idx);
  }

  // ------------------------------ search ------------------------------- #

  void toggleSearch() {
    searchOpen.value = !searchOpen.value;
    if (!searchOpen.value) clearSearch();
  }

  void runSearch(String q) {
    query.value = q;
    final found = <ReaderMatch>[];
    if (q.trim().isNotEmpty) {
      final needle = q.toLowerCase();
      for (var p = 0; p < paragraphs.length; p++) {
        final hay = paragraphs[p].toLowerCase();
        var from = 0;
        while (true) {
          final i = hay.indexOf(needle, from);
          if (i < 0) break;
          found.add(ReaderMatch(p, i, q.length));
          from = i + q.length;
        }
      }
    }
    matches.assignAll(found);
    activeMatch.value = found.isEmpty ? -1 : 0;
    if (found.isNotEmpty) _ensureActiveVisible();
  }

  void clearSearch() => _clearSearch();

  void _clearSearch() {
    query.value = '';
    matches.clear();
    activeMatch.value = -1;
  }

  void findNext() {
    if (matches.isEmpty) return;
    activeMatch.value = (activeMatch.value + 1) % matches.length;
    _ensureActiveVisible();
  }

  void findPrev() {
    if (matches.isEmpty) return;
    activeMatch.value =
        (activeMatch.value - 1 + matches.length) % matches.length;
    _ensureActiveVisible();
  }

  void _ensureActiveVisible() {
    final i = activeMatch.value;
    if (i < 0 || i >= matches.length) return;
    final para = matches[i].paragraph;
    if (para < 0 || para >= paragraphKeys.length) return;
    final ctx = paragraphKeys[para].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 250),
          alignment: 0.1,
          curve: Curves.easeInOut);
    }
  }

  // --------------------------- reading progress ------------------------ #

  void _onScroll() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 900), _saveProgressNow);
  }

  void _saveProgressNow() {
    if (!scroll.hasClients) return;
    final page = scroll.offset.round();
    _repo.saveReadingProgress(
      resourceType: args.isNote ? 'note' : 'book',
      resourceId: args.isNote ? args.noteId! : args.bookId!,
      chapterId: args.isNote ? null : _currentChapterId,
      page: page < 0 ? 0 : page,
    );
  }

  // ---------------------------- share / print -------------------------- #

  Future<pw.Document> _buildPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Header(level: 0, text: title.value),
          for (final p in paragraphs) ...[
            pw.Paragraph(text: p),
          ],
        ],
      ),
    );
    return doc;
  }

  Future<void> sharePdf() async {
    final doc = await _buildPdf();
    await Printing.sharePdf(
        bytes: await doc.save(), filename: '${_safeName(title.value)}.pdf');
  }

  Future<void> printDoc() async {
    final doc = await _buildPdf();
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  String _safeName(String s) =>
      s.replaceAll(RegExp(r'[^A-Za-z0-9._ -]+'), '_').trim();
}
