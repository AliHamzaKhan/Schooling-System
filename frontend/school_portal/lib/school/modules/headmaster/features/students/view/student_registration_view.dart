import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../../../widgets/avatar_picker_field.dart';
import '../../../data/headmaster_api_service.dart' show PickerOption;
import '../../../data/headmaster_repository.dart';

/// Full-page student registration form — collects account credentials,
/// personal details, guardian info, and section enrollment in one flow.
///
/// Extended fields (father's name, DOB, address, etc.) are stored under
/// `users.profile_metadata` on the backend. Guardian info creates a paired
/// guardian account and links it to the student via `linkChild`.
class StudentRegistrationView extends StatefulWidget {
  const StudentRegistrationView({super.key});

  @override
  State<StudentRegistrationView> createState() =>
      _StudentRegistrationViewState();
}

class _StudentRegistrationViewState extends State<StudentRegistrationView> {
  final _repo = Get.find<HeadmasterRepository>();

  // Account
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _avatarUrl = TextEditingController();

  // Personal
  final _gender = 'Male'.obs;
  final _dob = Rxn<DateTime>();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _admissionDate = Rx<DateTime>(DateTime.now());

  // Family
  final _fatherName = TextEditingController();
  final _motherName = TextEditingController();
  final _emergencyContact = TextEditingController();
  final _notes = TextEditingController();

  // Guardian account (optional)
  final _createGuardian = false.obs;
  final _guardianName = TextEditingController();
  final _guardianEmail = TextEditingController();
  final _guardianPhone = TextEditingController();
  final _guardianPassword = TextEditingController();

  // Section
  final _sections = <PickerOption>[].obs;
  final _selectedSection = Rxn<String>();

  final _sectionsLoading = true.obs;
  final _submitting = false.obs;
  final _error = RxnString();

  static const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    final res = await _repo.loadSectionOptions();
    _sections.assignAll(res.data ?? const []);
    if (_sections.isNotEmpty) _selectedSection.value = _sections.first.id;
    _sectionsLoading.value = false;
  }

  Future<void> _submit() async {
    _error.value = null;
    if (_fullName.text.trim().isEmpty) return _fail('Full name is required');
    if (!_email.text.contains('@')) return _fail('A valid email is required');
    if (_password.text.trim().length < 8) {
      return _fail('Password must be at least 8 characters');
    }
    if (_selectedSection.value == null) return _fail('Select a section');
    if (_createGuardian.value) {
      if (_guardianName.text.trim().isEmpty) {
        return _fail('Guardian full name is required');
      }
      if (!_guardianEmail.text.contains('@')) {
        return _fail('Guardian email is required');
      }
      if (_guardianPassword.text.trim().length < 8) {
        return _fail('Guardian password must be at least 8 characters');
      }
    }

    _submitting.value = true;
    try {
      final metadata = <String, dynamic>{
        if (_avatarUrl.text.trim().isNotEmpty)
          'avatar_url': _avatarUrl.text.trim(),
        'gender': _gender.value,
        if (_dob.value != null) 'date_of_birth': _iso(_dob.value!),
        if (_address.text.trim().isNotEmpty) 'address': _address.text.trim(),
        'admission_date': _iso(_admissionDate.value),
        if (_fatherName.text.trim().isNotEmpty)
          'father_name': _fatherName.text.trim(),
        if (_motherName.text.trim().isNotEmpty)
          'mother_name': _motherName.text.trim(),
        if (_emergencyContact.text.trim().isNotEmpty)
          'emergency_contact': _emergencyContact.text.trim(),
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      };

      final created = await _repo.createUser(
        email: _email.text.trim(),
        password: _password.text.trim(),
        fullName: _fullName.text.trim(),
        role: 'student',
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        profileMetadata: metadata,
      );
      if (!created.success) return _fail(created.error ?? 'Could not create student');
      final studentId = '${(created.data as Map)['id']}';

      final enrolled = await _repo.enrollStudent(
          sectionId: _selectedSection.value!, studentId: studentId);
      if (!enrolled.success) {
        return _fail(enrolled.error ?? 'Student created, but enrollment failed');
      }

      if (_createGuardian.value) {
        final guardianCreated = await _repo.createUser(
          email: _guardianEmail.text.trim(),
          password: _guardianPassword.text.trim(),
          fullName: _guardianName.text.trim(),
          role: 'guardian',
          phone: _guardianPhone.text.trim().isEmpty
              ? null
              : _guardianPhone.text.trim(),
        );
        if (!guardianCreated.success) {
          return _fail(guardianCreated.error ??
              'Student enrolled, but guardian creation failed');
        }
        final guardianId = '${(guardianCreated.data as Map)['id']}';
        final linked = await _repo.linkChild(
            guardianId: guardianId, studentId: studentId);
        if (!linked.success) {
          return _fail(linked.error ??
              'Student and guardian created, but linking failed');
        }
      }

      Get.back<bool>(result: true);
      Get.snackbar('Student registered', 'The student was admitted successfully.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _submitting.value = false;
    }
  }

  void _fail(String msg) {
    _error.value = msg;
    _submitting.value = false;
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, "0")}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';

  Future<void> _pickDate(Rx<DateTime> target,
      {DateTime? first, DateTime? last}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: target.value,
      firstDate: first ?? DateTime(now.year - 100),
      lastDate: last ?? DateTime(now.year + 5),
    );
    if (picked != null) target.value = picked;
  }

  Future<void> _pickDateNullable(Rxn<DateTime> target,
      {DateTime? first, DateTime? last}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: target.value ?? DateTime(now.year - 6, now.month, now.day),
      firstDate: first ?? DateTime(now.year - 100),
      lastDate: last ?? DateTime(now.year + 5),
    );
    if (picked != null) target.value = picked;
  }

  @override
  void dispose() {
    for (final c in [
      _fullName, _email, _password, _avatarUrl, _phone, _address,
      _fatherName, _motherName, _emergencyContact, _notes,
      _guardianName, _guardianEmail, _guardianPhone, _guardianPassword,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Register Student'),
        backgroundColor: AppColors.surface,
      ),
      body: Obx(() {
        if (_sectionsLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_sections.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.stackXl),
            child: Center(
              child: Text(
                'Create a class and section before enrolling students.',
                style: AppTypography.bodyLg,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackLg,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackXl,
          ),
          children: [
            _section('Account'),
            GlassInput(
                label: 'Full name', hint: 'Student name', controller: _fullName),
            _gap(),
            GlassInput(
              label: 'Email',
              hint: 'student@school.edu',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
            ),
            _gap(),
            GlassInput(
              label: 'Temporary password',
              hint: 'At least 8 characters',
              controller: _password,
              obscureText: true,
            ),
            _gap(),
            AvatarPickerField(urlController: _avatarUrl),
            _gapLg(),
            _section('Personal'),
            Obx(() => ActionDropdownField<String>(
                  label: 'Gender',
                  hint: 'Select gender',
                  value: _gender.value,
                  items: [
                    for (final g in _genders)
                      DropdownMenuItem(value: g, child: Text(g)),
                  ],
                  onChanged: (v) => _gender.value = v ?? 'Male',
                )),
            _gap(),
            Obx(() => _DateField(
                  label: 'Date of birth',
                  value: _dob.value,
                  placeholder: 'Tap to pick',
                  onTap: () => _pickDateNullable(_dob),
                )),
            _gap(),
            GlassInput(
              label: 'Contact number',
              hint: '+1 555 0100',
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
            _gap(),
            GlassInput(
              label: 'Address',
              hint: 'Street, city, ZIP',
              controller: _address,
            ),
            _gap(),
            Obx(() => _DateField(
                  label: 'Admission date',
                  value: _admissionDate.value,
                  onTap: () => _pickDate(_admissionDate),
                )),
            _gapLg(),
            _section('Family'),
            GlassInput(
                label: "Father's name",
                hint: 'Full name',
                controller: _fatherName),
            _gap(),
            GlassInput(
                label: "Mother's name (optional)",
                hint: 'Full name',
                controller: _motherName),
            _gap(),
            GlassInput(
              label: 'Emergency contact',
              hint: 'Name — Phone',
              controller: _emergencyContact,
            ),
            _gap(),
            GlassInput(
              label: 'Additional notes (optional)',
              hint: 'Allergies, siblings, etc.',
              controller: _notes,
            ),
            _gapLg(),
            _section('Guardian account'),
            Obx(() => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Create guardian profile and link to student',
                      style: AppTypography.bodyLg),
                  value: _createGuardian.value,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => _createGuardian.value = v,
                )),
            Obx(() {
              if (!_createGuardian.value) return const SizedBox.shrink();
              return Column(
                children: [
                  _gap(),
                  GlassInput(
                      label: 'Guardian full name',
                      hint: 'Full name',
                      controller: _guardianName),
                  _gap(),
                  GlassInput(
                    label: 'Guardian email',
                    hint: 'guardian@example.com',
                    controller: _guardianEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _gap(),
                  GlassInput(
                    label: 'Guardian phone',
                    hint: '+1 555 0100',
                    controller: _guardianPhone,
                    keyboardType: TextInputType.phone,
                  ),
                  _gap(),
                  GlassInput(
                    label: 'Guardian temporary password',
                    hint: 'At least 8 characters',
                    controller: _guardianPassword,
                    obscureText: true,
                  ),
                ],
              );
            }),
            _gapLg(),
            _section('Enrollment'),
            Obx(() => ActionDropdownField<String>(
                  label: 'Section',
                  hint: 'Select a section',
                  value: _selectedSection.value,
                  items: [
                    for (final s in _sections)
                      DropdownMenuItem(value: s.id, child: Text(s.label)),
                  ],
                  onChanged: (v) => _selectedSection.value = v,
                )),
            _gapLg(),
            Obx(() {
              final err = _error.value;
              if (err == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                child: Text(err,
                    style:
                        AppTypography.bodyMd.copyWith(color: AppColors.error)),
              );
            }),
            Obx(() => PrimaryButton(
                  label: 'Admit & Enroll',
                  isLoading: _submitting.value,
                  expanded: true,
                  onPressed: _submitting.value ? null : _submit,
                )),
          ],
        );
      }),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
        child: Text(title, style: AppTypography.labelCaps),
      );

  Widget _gap() => const SizedBox(height: AppSpacing.stackMd);
  Widget _gapLg() => const SizedBox(height: AppSpacing.stackLg);
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final String placeholder;
  final VoidCallback onTap;
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder = 'Tap to pick',
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, "0")} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTypography.labelCaps
                .copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.stackMd, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? placeholder : _fmt(value!),
                    style: AppTypography.bodyLg.copyWith(
                        color: value == null
                            ? AppColors.onSurfaceVariant
                            : AppColors.onSurface),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
