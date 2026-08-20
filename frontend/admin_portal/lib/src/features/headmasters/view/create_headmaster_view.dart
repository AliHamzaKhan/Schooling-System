import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../schools/models/school.dart';
import '../controller/headmasters_controller.dart';
import '../../../ui/admin_theme.dart';
import '../../../ui/admin_widgets/admin_page_header.dart';
import '../../../ui/admin_widgets/admin_search_field.dart';
import '../../../ui/admin_widgets/admin_surface.dart';
import '../../../ui/admin_widgets/admin_text_field.dart';

/// Full-screen create-headmaster form (replaces the old modal dialog): pick a
/// school via the searchable, paginated picker, enter the account details, and
/// POST via the controller. Returns to the list on success.
class CreateHeadmasterView extends StatefulWidget {
  const CreateHeadmasterView({super.key});

  @override
  State<CreateHeadmasterView> createState() => _CreateHeadmasterViewState();
}

class _CreateHeadmasterViewState extends State<CreateHeadmasterView> {
  final _controller = Get.find<HeadmastersController>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _selectedSchoolId = RxnString();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    // Loads only the first page; typing runs a server-side search.
    _controller.resetSchoolPicker();
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
    final schoolId = _selectedSchoolId.value;
    if (schoolId == null ||
        _name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.length < 8) {
      _controller.submitError.value =
          'Pick a school and fill name, email, and a password (8+ chars).';
      return;
    }
    final ok = await _controller.createHeadmaster(
      schoolId: schoolId,
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
    return AppScaffold(
      safeArea: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminScreenHeader(title: 'New Headmaster'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackSm,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl,
                ),
                children: [
                  Text('Provision a school administrator account.',
                      style: AdminType.body.copyWith(color: AdminPalette.muted)),
                  const SizedBox(height: AppSpacing.stackLg),
                  _SchoolPicker(
                    controller: _controller,
                    selectedId: _selectedSchoolId,
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Text('Account details', style: AdminType.sectionTitle),
                  const SizedBox(height: AppSpacing.stackMd),
                  AdminTextField(
                    label: 'Full name',
                    hint: 'Jane Doe',
                    controller: _name,
                    required: true,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  AdminTextField(
                    label: 'Email',
                    hint: 'head@school.edu',
                    controller: _email,
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  _PasswordField(
                    controller: _password,
                    obscure: _obscure,
                    onToggle: () => setState(() => _obscure = !_obscure),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  AdminTextField(
                    label: 'Phone (optional)',
                    hint: '+1 (555) 123-4567',
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                  ),
                  Obx(() {
                    final err = _controller.submitError.value;
                    if (err == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.stackMd),
                      child: _ErrorBanner(message: err),
                    );
                  }),
                  const SizedBox(height: AppSpacing.stackLg),
                  Obx(() => PrimaryButton(
                        label: _controller.submitting.value
                            ? 'Creating…'
                            : 'Create Headmaster',
                        expanded: true,
                        trailingIcon: null,
                        isLoading: _controller.submitting.value,
                        onPressed: _controller.submitting.value ? null : _submit,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Searchable, paginated school picker backed by the live schools API.
class _SchoolPicker extends StatelessWidget {
  final HeadmastersController controller;
  final RxnString selectedId;

  const _SchoolPicker({required this.controller, required this.selectedId});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: 'School',
              style: AdminType.label.copyWith(color: AdminPalette.ink),
              children: const [
                TextSpan(text: ' *', style: TextStyle(color: AdminPalette.danger)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          AdminSearchField(
            hint: 'Search schools by name or code',
            onChanged: controller.onSchoolSearch,
            action: AdminIconButton(
              icon: AppIcons.searchRounded,
              onTap: controller.searchSchoolsNow,
            ),
          ),
          const SizedBox(height: 6),
          Text('Type at least 3 characters to search, or tap the search button.',
              style: AdminType.meta.copyWith(color: AdminPalette.faint)),
          const SizedBox(height: AppSpacing.stackMd),
          Obx(() {
            if (controller.loadingSchools.value &&
                controller.schoolResults.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final items = controller.schoolResults;
            if (items.isEmpty) {
              final typing = controller.schoolQuery.value.trim().isNotEmpty;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
                child: Center(
                  child: Text(
                      typing
                          ? 'No schools match “${controller.schoolQuery.value.trim()}”.'
                          : 'No schools found.',
                      style: AdminType.body.copyWith(color: AdminPalette.muted)),
                ),
              );
            }
            return Column(
              children: [
                for (final s in items) ...[
                  _SchoolTile(
                    school: s,
                    selected: selectedId.value == s.id,
                    onTap: () => selectedId.value = s.id,
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                ],
                _PickerPager(controller: controller),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SchoolTile extends StatelessWidget {
  final School school;
  final bool selected;
  final VoidCallback onTap;

  const _SchoolTile({
    required this.school,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AdminPalette.ink.withValues(alpha: 0.06) : AdminPalette.card,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.stackMd, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: selected ? AdminPalette.ink : AdminPalette.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AdminPalette.tint,
                child: Text(school.initial,
                    style: AdminType.rowTitle.copyWith(color: AdminPalette.ink)),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(school.name,
                        style: AdminType.rowTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (school.code.isNotEmpty)
                      Text(school.code,
                          style: AdminType.meta
                              .copyWith(color: AdminPalette.muted)),
                  ],
                ),
              ),
              Icon(
                selected
                    ? AppIcons.checkCircleRounded
                    : AppIcons.radioButtonUncheckedRounded,
                color: selected ? AdminPalette.ink : AdminPalette.faint,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerPager extends StatelessWidget {
  final HeadmastersController controller;
  const _PickerPager({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final page = controller.schoolPickerPage.value;
      final hasMore = controller.schoolHasMore.value;
      // Only show the pager once paging is actually possible.
      if (page <= 1 && !hasMore) return const SizedBox.shrink();
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: page > 1 ? controller.schoolPickerPrev : null,
            icon: const Icon(AppIcons.chevronLeftRounded),
          ),
          Text('Page $page', style: AdminType.label),
          IconButton(
            onPressed: hasMore ? controller.schoolPickerNext : null,
            icon: const Icon(AppIcons.chevronRightRounded),
          ),
        ],
      );
    });
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Password',
            style: AdminType.label.copyWith(color: AdminPalette.ink),
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: AdminPalette.danger)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: AdminType.body.copyWith(color: AdminPalette.ink),
          decoration: InputDecoration(
            hintText: 'At least 8 characters',
            hintStyle: AdminType.body.copyWith(color: AdminPalette.faint),
            filled: true,
            fillColor: AdminPalette.card,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.stackMd, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: const BorderSide(color: AdminPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: const BorderSide(color: AdminPalette.ink, width: 1.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: const BorderSide(color: AdminPalette.border),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? AppIcons.visibilityOffOutlined
                    : AppIcons.visibilityOutlined,
                color: AdminPalette.muted,
                size: 20,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.stackMd, vertical: 10),
      decoration: BoxDecoration(
        color: AdminPalette.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.errorOutlineRounded,
              color: AdminPalette.danger, size: 18),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Text(message,
                style: AdminType.body.copyWith(color: AdminPalette.danger)),
          ),
        ],
      ),
    );
  }
}
