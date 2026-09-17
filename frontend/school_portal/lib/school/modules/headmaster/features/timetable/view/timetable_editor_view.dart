import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/headmaster_repository.dart';
import '../../classes/models/classes_data.dart';
import '../../teachers/models/teacher.dart';
import '../models/timetable_slot.dart';
import '../../../../../widgets/skeletons.dart';

/// Timetable editor. The headmaster picks a class + section, sees its weekly
/// schedule broken down by day, taps a slot to edit or "+ Add slot" to
/// insert. Every action hits the timetable CRUD endpoints, which the backend
/// validates for teacher / section overlaps.
class TimetableEditorView extends StatefulWidget {
  const TimetableEditorView({super.key});

  @override
  State<TimetableEditorView> createState() => _TimetableEditorViewState();
}

class _TimetableEditorViewState extends State<TimetableEditorView>
    with SingleTickerProviderStateMixin {
  static const _dayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  final _repo = Get.find<HeadmasterRepository>();

  final _classes = <GradeGroup>[].obs;
  final _selectedClassId = RxnString();
  final _sectionsForClass = <ClassSection>[].obs;
  final _selectedSectionId = RxnString();

  final _teachers = <Teacher>[].obs;
  final _subjects = <SubjectOption>[].obs;
  final _slots = <TimetableSlot>[].obs;

  final _loading = true.obs;
  final _slotsLoading = false.obs;
  final _error = RxnString();

  TabController? _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _dayNames.length, vsync: this);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _loading.value = true;
    _error.value = null;
    final results = await Future.wait([
      _repo.loadClasses(),
      _repo.loadTeachers(),
      _repo.loadSubjectOptions(),
    ]);
    final classesRes = results[0] as dynamic;
    final teachersRes = results[1] as dynamic;
    final subjectsRes = results[2] as dynamic;

    if (classesRes.success && classesRes.data != null) {
      _classes.assignAll(classesRes.data.grades as List<GradeGroup>);
    }
    if (teachersRes.success && teachersRes.data != null) {
      _teachers.assignAll(teachersRes.data as List<Teacher>);
    }
    if (subjectsRes.success && subjectsRes.data != null) {
      _subjects.assignAll(subjectsRes.data as List<SubjectOption>);
    }
    if (_classes.isNotEmpty) {
      _onClassChanged(_classes.first.classId, initial: true);
    }
    _loading.value = false;
  }

  void _onClassChanged(String? classId, {bool initial = false}) {
    _selectedClassId.value = classId;
    if (classId == null) {
      _sectionsForClass.clear();
      _selectedSectionId.value = null;
      _slots.clear();
      return;
    }
    final group = _classes.firstWhereOrNull((g) => g.classId == classId);
    _sectionsForClass.assignAll(group?.sections ?? const []);
    if (_sectionsForClass.isNotEmpty) {
      _selectedSectionId.value = _sectionsForClass.first.id;
      _fetchSlots();
    } else {
      _selectedSectionId.value = null;
      _slots.clear();
    }
    if (initial) return;
  }

  void _onSectionChanged(String? sectionId) {
    _selectedSectionId.value = sectionId;
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    final sectionId = _selectedSectionId.value;
    if (sectionId == null) return;
    _slotsLoading.value = true;
    final res = await _repo.loadTimetableSlots(sectionId: sectionId);
    if (res.success && res.data != null) {
      _slots.assignAll(res.data!);
    } else {
      _error.value = res.error ?? 'Could not load slots';
    }
    _slotsLoading.value = false;
  }

  Future<void> _openSlotEditor({TimetableSlot? existing}) async {
    final sectionId = _selectedSectionId.value;
    if (sectionId == null) return;
    final result = await Get.bottomSheet<_SlotSubmit>(
      _SlotEditorSheet(
        existing: existing,
        subjects: _subjects,
        teachers: _teachers,
        defaultDay: _tabs?.index ?? 0,
        onDelete: existing == null
            ? null
            : () async {
                Get.back<_SlotSubmit>(result: const _SlotSubmit.delete());
              },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
    if (result == null) return;
    if (result.deleted) {
      final res = await _repo.deleteTimetableSlot(existing!.id);
      if (res.success) {
        Get.snackbar('Slot deleted', 'Removed from the timetable.',
            snackPosition: SnackPosition.BOTTOM);
        _slots.removeWhere((s) => s.id == existing.id);
      } else {
        Get.snackbar('Could not delete', res.error ?? 'Please try again.',
            snackPosition: SnackPosition.BOTTOM);
      }
      return;
    }
    if (existing == null) {
      final res = await _repo.createTimetableSlot(
        sectionId: sectionId,
        subjectId: result.subjectId!,
        teacherId: result.teacherId,
        dayOfWeek: result.dayOfWeek!,
        startTime: result.startTime!,
        endTime: result.endTime!,
        room: result.room,
      );
      if (res.success && res.data != null) {
        _slots.add(res.data!);
        Get.snackbar('Slot added', 'Saved to the timetable.',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Could not save', res.error ?? 'Please try again.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } else {
      final res = await _repo.updateTimetableSlot(
        slotId: existing.id,
        subjectId: result.subjectId,
        teacherId: result.teacherId,
        dayOfWeek: result.dayOfWeek,
        startTime: result.startTime,
        endTime: result.endTime,
        room: result.room,
      );
      if (res.success && res.data != null) {
        final i = _slots.indexWhere((s) => s.id == existing.id);
        if (i >= 0) _slots[i] = res.data!;
        Get.snackbar('Slot updated', 'Changes saved.',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Could not save', res.error ?? 'Please try again.',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Timetable Management'),
        backgroundColor: AppColors.surface,
      ),
      floatingActionButton: Obx(() {
        if (_selectedSectionId.value == null) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: () => _openSlotEditor(),
          icon: const Icon(AppIcons.add),
          label: const Text('Add slot'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
        );
      }),
      body: Obx(() {
        if (_loading.value) {
          return const SkeletonPage(body: SkeletonForm(fields: 3, withSubmit: false));
        }
        if (_classes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.stackXl),
            child: Center(
              child: Text(
                'Create a class and section before building the timetable.',
                style: AppTypography.bodyLg,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackMd,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackSm,
              ),
              child: Column(
                children: [
                  _LabeledDropdown<String>(
                    label: 'Class',
                    value: _selectedClassId.value,
                    items: [
                      for (final g in _classes)
                        DropdownMenuItem(
                          value: g.classId,
                          child: Text(g.className.isNotEmpty
                              ? g.className
                              : 'Grade ${g.grade}'),
                        ),
                    ],
                    onChanged: _onClassChanged,
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  _LabeledDropdown<String>(
                    label: 'Section',
                    value: _selectedSectionId.value,
                    items: [
                      for (final s in _sectionsForClass)
                        DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        ),
                    ],
                    onChanged: _onSectionChanged,
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.onSurfaceVariant,
              indicatorColor: AppColors.primary,
              tabs: [for (final d in _dayNames) Tab(text: d)],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  for (var day = 0; day < _dayNames.length; day++)
                    _DaySlots(
                      loading: _slotsLoading.value,
                      slots: _slots
                          .where((s) => s.dayOfWeek == day)
                          .toList()
                        ..sort(
                            (a, b) => a.startMinutes.compareTo(b.startMinutes)),
                      teachers: _teachers,
                      subjects: _subjects,
                      onTapSlot: (slot) => _openSlotEditor(existing: slot),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTypography.labelCaps
                .copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _DaySlots extends StatelessWidget {
  final bool loading;
  final List<TimetableSlot> slots;
  final List<Teacher> teachers;
  final List<SubjectOption> subjects;
  final ValueChanged<TimetableSlot> onTapSlot;
  const _DaySlots({
    required this.loading,
    required this.slots,
    required this.teachers,
    required this.subjects,
    required this.onTapSlot,
  });

  String _subjectName(String id) =>
      subjects.firstWhereOrNull((s) => s.id == id)?.name ?? 'Subject';
  String _teacherName(String? id) => id == null
      ? 'Unassigned'
      : (teachers.firstWhereOrNull((t) => t.id == id)?.name ?? 'Teacher');

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SkeletonPage(withHeader: false, body: SkeletonForm(fields: 3));
    }
    if (slots.isEmpty) {
      return Center(
        child: Text('No periods scheduled for this day.',
            style: AppTypography.bodyLg),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackMd,
        AppSpacing.containerPaddingMobile,
        96, // room for FAB
      ),
      itemCount: slots.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppSpacing.stackSm),
      itemBuilder: (_, i) {
        final s = slots[i];
        return InkWell(
          onTap: () => onTapSlot(s),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 66,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Column(
                    children: [
                      Text(s.startHm,
                          style: AppTypography.titleMd.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                      Text(s.endHm,
                          style: AppTypography.labelMd.copyWith(
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_subjectName(s.subjectId),
                          style: AppTypography.bodyLg),
                      const SizedBox(height: 2),
                      Text(_teacherName(s.teacherId),
                          style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant)),
                      if (s.room != null && s.room!.isNotEmpty)
                        Text('Room ${s.room}',
                            style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                const Icon(AppIcons.chevronRightRounded,
                    color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Result of the slot editor sheet.
class _SlotSubmit {
  final bool deleted;
  final String? subjectId;
  final String? teacherId;
  final int? dayOfWeek;
  final String? startTime;
  final String? endTime;
  final String? room;

  const _SlotSubmit({
    this.deleted = false,
    this.subjectId,
    this.teacherId,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.room,
  });

  const _SlotSubmit.delete() : this(deleted: true);
}

class _SlotEditorSheet extends StatefulWidget {
  final TimetableSlot? existing;
  final List<SubjectOption> subjects;
  final List<Teacher> teachers;
  final int defaultDay;
  final Future<void> Function()? onDelete;
  const _SlotEditorSheet({
    required this.subjects,
    required this.teachers,
    required this.defaultDay,
    this.existing,
    this.onDelete,
  });

  @override
  State<_SlotEditorSheet> createState() => _SlotEditorSheetState();
}

class _SlotEditorSheetState extends State<_SlotEditorSheet> {
  late String? _subjectId;
  late String? _teacherId;
  late int _day;
  late TimeOfDay _start;
  late TimeOfDay _end;
  final _room = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _subjectId = e?.subjectId ?? widget.subjects.firstOrNull?.id;
    _teacherId = e?.teacherId;
    _day = e?.dayOfWeek ?? widget.defaultDay;
    _start = e != null
        ? _parse(e.startHm) ?? const TimeOfDay(hour: 8, minute: 0)
        : const TimeOfDay(hour: 8, minute: 0);
    _end = e != null
        ? _parse(e.endHm) ?? const TimeOfDay(hour: 8, minute: 45)
        : const TimeOfDay(hour: 8, minute: 45);
    _room.text = e?.room ?? '';
  }

  static TimeOfDay? _parse(String hm) {
    final parts = hm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _asWire(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}';

  Future<void> _pick(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  int _mins(TimeOfDay t) => t.hour * 60 + t.minute;

  void _submit() {
    setState(() => _error = null);
    if (_subjectId == null) {
      setState(() => _error = 'Choose a subject');
      return;
    }
    if (_mins(_end) <= _mins(_start)) {
      setState(() => _error = 'End time must be after start time');
      return;
    }
    Get.back<_SlotSubmit>(
      result: _SlotSubmit(
        subjectId: _subjectId,
        teacherId: _teacherId,
        dayOfWeek: _day,
        startTime: _asWire(_start),
        endTime: _asWire(_end),
        room: _room.text.trim().isEmpty ? null : _room.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _room.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackLg,
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackLg + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.existing == null ? 'Add Slot' : 'Edit Slot',
              style: AppTypography.titleLg,
            ),
            const SizedBox(height: AppSpacing.stackLg),
            _LabeledDropdown<String>(
              label: 'Subject',
              value: _subjectId,
              items: [
                for (final s in widget.subjects)
                  DropdownMenuItem(value: s.id, child: Text(s.name)),
              ],
              onChanged: (v) => setState(() => _subjectId = v),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            _LabeledDropdown<String?>(
              label: 'Teacher',
              value: _teacherId,
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Unassigned')),
                for (final t in widget.teachers)
                  DropdownMenuItem(value: t.id, child: Text(t.name)),
              ],
              onChanged: (v) => setState(() => _teacherId = v),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            _LabeledDropdown<int>(
              label: 'Day',
              value: _day,
              items: [
                for (var i = 0; i < 7; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(_TimetableEditorViewState._dayNames[i]),
                  ),
              ],
              onChanged: (v) => setState(() => _day = v ?? 0),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Start',
                    time: _start,
                    onTap: () => _pick(true),
                  ),
                ),
                const SizedBox(width: AppSpacing.stackSm),
                Expanded(
                  child: _TimeField(
                    label: 'End',
                    time: _end,
                    onTap: () => _pick(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackSm),
            GlassInput(
              label: 'Room (optional)',
              hint: 'e.g. B-102',
              controller: _room,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
                child: Text(_error!,
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.error)),
              ),
            Row(
              children: [
                if (widget.onDelete != null) ...[
                  Expanded(
                    child: GhostButton(
                      label: 'Delete',
                      leadingIcon: AppIcons.deleteOutline,
                      onPressed: () async {
                        await widget.onDelete!();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.stackSm),
                ],
                Expanded(
                  child: PrimaryButton(
                    label: widget.existing == null ? 'Add' : 'Save',
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTypography.labelCaps
                .copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.stackMd, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    time.format(context),
                    style: AppTypography.bodyLg,
                  ),
                ),
                const Icon(AppIcons.scheduleRounded,
                    color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
