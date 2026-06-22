import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/admin_search_field.dart';
import '../../../ui/admin_widgets/filter_chips.dart';
import '../components/headmaster_card.dart';
import '../controller/headmasters_controller.dart';
import '../models/headmaster.dart';

/// Confirms then soft-deletes (deactivates) a headmaster.
Future<void> _confirmDeleteHeadmaster(Headmaster h) async {
  final ok = await Get.dialog<bool>(
    AlertDialog(
      title: const Text('Delete headmaster?'),
      content: Text(
          '${h.name} will be deactivated and lose access. You can re-add them later.'),
      actions: [
        TextButton(onPressed: () => Get.back<bool>(result: false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Get.back<bool>(result: true),
          child: const Text('Delete', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final removed = await Get.find<HeadmastersController>().deleteHeadmaster(h);
  if (removed) {
    Get.snackbar('Deleted', '${h.name} was removed.',
        snackPosition: SnackPosition.BOTTOM);
  }
}

/// Headmaster Management — manage school leadership and administrative access.
class HeadmastersView extends GetView<HeadmastersController> {
  const HeadmastersView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      safeArea: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _Header(),
                  const SizedBox(height: AppSpacing.stackMd),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.containerPaddingMobile),
                    child: GlassSurface(
                      padding: const EdgeInsets.all(AppSpacing.stackMd),
                      child: Column(
                        children: [
                          AdminSearchField(
                            hint: 'Search by name, email, or school',
                            onChanged: controller.onSearch,
                          ),
                          const SizedBox(height: AppSpacing.stackMd),
                          Obx(() => FilterChips(
                                options: HeadmastersController.filters,
                                selectedIndex: controller.filterIndex.value,
                                onSelected: controller.selectFilter,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.containerPaddingMobile),
                    child: _list(),
                  ),
                  const SizedBox(height: AppSpacing.stackXl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    return Obx(() {
      if (controller.loading.value) {
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.stackXl),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final items = controller.pageItems;
      if (items.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.stackXl),
          child: Center(
            child: Text('No headmasters match your filters.',
                style: AppTypography.bodyLg),
          ),
        );
      }
      return Column(
        children: [
          for (final h in items) ...[
            HeadmasterCard(
              headmaster: h,
              onEdit: () => Get.dialog<void>(_EditHeadmasterDialog(headmaster: h)),
              onDelete: () => _confirmDeleteHeadmaster(h),
            ),
            const SizedBox(height: AppSpacing.stackLg),
          ],
          const SizedBox(height: AppSpacing.stackSm),
          _Pager(
            page: controller.page.value,
            total: controller.totalPages,
            onPrev: controller.prevPage,
            onNext: controller.nextPage,
          ),
        ],
      );
    });
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackSm,
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackLg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCEAD6), Color(0xFFF3DCE6), Color(0xFFD9CDEF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back<void>(),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.person, color: AppColors.onPrimary, size: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Text('EduMaster Admin',
                  style: AppTypography.titleLg.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
              const Spacer(),
              const Icon(Icons.notifications_none_rounded, color: AppColors.onSurface),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Headmasters',
              style: AppTypography.displayLg.copyWith(color: AppColors.primary, fontSize: 34)),
          const SizedBox(height: AppSpacing.stackSm),
          Text('Manage school leadership and administrative access.',
              style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: AppSpacing.stackLg),
          PrimaryButton(
            label: 'New Headmaster',
            leadingIcon: Icons.add,
            trailingIcon: null,
            onPressed: () => Get.dialog<void>(const _CreateHeadmasterDialog()),
          ),
        ],
      ),
    );
  }
}

/// Create-headmaster form: pick a school, enter the account details, and POST
/// to the backend via the controller. Refreshes the list on success.
class _CreateHeadmasterDialog extends StatefulWidget {
  const _CreateHeadmasterDialog();

  @override
  State<_CreateHeadmasterDialog> createState() => _CreateHeadmasterDialogState();
}

class _CreateHeadmasterDialogState extends State<_CreateHeadmasterDialog> {
  final _controller = Get.find<HeadmastersController>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  String? _schoolId;

  @override
  void initState() {
    super.initState();
    _controller.loadSchools();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_schoolId == null ||
        _name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.length < 8) {
      _controller.submitError.value =
          'Pick a school and fill name, email, and a password (8+ chars).';
      return;
    }
    final ok = await _controller.createHeadmaster(
      schoolId: _schoolId!,
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      phone: _phone.text.trim(),
    );
    if (ok) {
      Get.back<void>();
      Get.snackbar('Headmaster created', '${_name.text.trim()} was added.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Headmaster'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => DropdownButtonFormField<String>(
                  initialValue: _schoolId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: _controller.loadingSchools.value
                        ? 'Loading schools…'
                        : 'School',
                  ),
                  items: _controller.schools
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _schoolId = v),
                )),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password (8+ chars)')),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (optional)')),
            const SizedBox(height: 8),
            Obx(() => _controller.submitError.value == null
                ? const SizedBox.shrink()
                : Text(_controller.submitError.value!,
                    style: const TextStyle(color: AppColors.error))),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back<void>(), child: const Text('Cancel')),
        Obx(() => TextButton(
              onPressed: _controller.submitting.value ? null : _submit,
              child: Text(_controller.submitting.value ? 'Creating…' : 'Create'),
            )),
      ],
    );
  }
}

class _Pager extends StatelessWidget {
  final int page;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _Pager({
    required this.page,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 1 ? onPrev : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text('Page $page of $total', style: AppTypography.labelMd),
        IconButton(
          onPressed: page < total ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// Edit a headmaster's name + phone (email/school aren't editable here).
class _EditHeadmasterDialog extends StatefulWidget {
  final Headmaster headmaster;
  const _EditHeadmasterDialog({required this.headmaster});

  @override
  State<_EditHeadmasterDialog> createState() => _EditHeadmasterDialogState();
}

class _EditHeadmasterDialogState extends State<_EditHeadmasterDialog> {
  final _controller = Get.find<HeadmastersController>();
  late final _name = TextEditingController(text: widget.headmaster.name);
  late final _phone = TextEditingController(text: widget.headmaster.phone ?? '');

  @override
  void initState() {
    super.initState();
    _controller.submitError.value = null;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().length < 2) {
      _controller.submitError.value = 'Enter a valid name.';
      return;
    }
    final ok = await _controller.updateHeadmaster(
      headmaster: widget.headmaster,
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
    );
    if (ok) {
      Get.back<void>();
      Get.snackbar('Saved', 'Headmaster updated.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Headmaster'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (optional)')),
          const SizedBox(height: 8),
          Obx(() => _controller.submitError.value == null
              ? const SizedBox.shrink()
              : Text(_controller.submitError.value!,
                  style: const TextStyle(color: AppColors.error))),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back<void>(), child: const Text('Cancel')),
        Obx(() => TextButton(
              onPressed: _controller.submitting.value ? null : _submit,
              child: Text(_controller.submitting.value ? 'Saving…' : 'Save'),
            )),
      ],
    );
  }
}
