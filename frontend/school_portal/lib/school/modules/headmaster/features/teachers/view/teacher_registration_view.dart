import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../../../widgets/avatar_picker_field.dart';
import '../../../data/headmaster_repository.dart';
import '../../salary/controller/salary_controller.dart';

/// Full-page teacher registration form — collects account credentials,
/// personal details, employment info, and initial salary in one flow.
///
/// Extended fields (DOB, education, experience, etc.) are stored under
/// `users.profile_metadata`. Base salary + designation create a staff profile
/// so payslips can be generated immediately.
class TeacherRegistrationView extends StatefulWidget {
  const TeacherRegistrationView({super.key});

  @override
  State<TeacherRegistrationView> createState() =>
      _TeacherRegistrationViewState();
}

class _TeacherRegistrationViewState extends State<TeacherRegistrationView> {
  final _repo = Get.find<HeadmasterRepository>();

  // Account
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _avatarUrl = TextEditingController();

  // Personal
  final _gender = 'Male'.obs;
  final _dob = Rxn<DateTime>();
  final _maritalStatus = 'Single'.obs;
  final _phone = TextEditingController();
  final _address = TextEditingController();

  // Employment
  final _education = TextEditingController();
  final _experience = TextEditingController();
  final _specialization = TextEditingController();
  final _salary = TextEditingController();
  final _designation = 'Teacher'.obs;
  final _joiningDate = Rx<DateTime>(DateTime.now());
  final _nationalId = TextEditingController();
  final _emergencyContact = TextEditingController();
  final _notes = TextEditingController();

  final _submitting = false.obs;
  final _error = RxnString();

  String? _createdTeacherId;
  double? _pendingSalary;
  String? _pendingDesignation;

  static const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  static const _maritalStatuses = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'Prefer not to say',
  ];

  Future<void> _submit() async {
    _error.value = null;
    if (_fullName.text.trim().isEmpty) return _fail('Full name is required');
    if (!_email.text.contains('@')) return _fail('A valid email is required');
    if (_password.text.trim().length < 8) {
      return _fail('Password must be at least 8 characters');
    }
    var salaryValue = _pendingSalary;
    if (_createdTeacherId == null && _salary.text.trim().isNotEmpty) {
      salaryValue = double.tryParse(_salary.text.trim());
      if (salaryValue == null || salaryValue < 0) {
        return _fail('Enter a valid salary or leave blank');
      }
    }

    _submitting.value = true;
    try {
      final metadata = <String, dynamic>{
        if (_avatarUrl.text.trim().isNotEmpty)
          'avatar_url': _avatarUrl.text.trim(),
        'gender': _gender.value,
        if (_dob.value != null) 'date_of_birth': _iso(_dob.value!),
        'marital_status': _maritalStatus.value,
        if (_address.text.trim().isNotEmpty) 'address': _address.text.trim(),
        if (_education.text.trim().isNotEmpty)
          'education': _education.text.trim(),
        if (_experience.text.trim().isNotEmpty)
          'years_experience': _experience.text.trim(),
        if (_specialization.text.trim().isNotEmpty)
          'specialization': _specialization.text.trim(),
        'joining_date': _iso(_joiningDate.value),
        if (_nationalId.text.trim().isNotEmpty)
          'national_id': _nationalId.text.trim(),
        if (_emergencyContact.text.trim().isNotEmpty)
          'emergency_contact': _emergencyContact.text.trim(),
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      };

      var userId = _createdTeacherId;
      if (userId == null) {
        final created = await _repo.createUser(
          email: _email.text.trim(),
          password: _password.text.trim(),
          fullName: _fullName.text.trim(),
          role: 'teacher',
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          profileMetadata: metadata,
        );
        if (!created.success) {
          return _fail(created.error ?? 'Could not create teacher');
        }
        userId = '${(created.data as Map)['id']}';
        _createdTeacherId = userId;
        _pendingSalary = salaryValue;
        _pendingDesignation = _designation.value;
      }

      if (salaryValue != null) {
        final prof = await _repo.createStaffProfile(
          userId: userId,
          designation: _pendingDesignation ?? _designation.value,
          baseSalary: salaryValue,
        );
        if (!prof.success) {
          return _fail(
            'Teacher account created, but salary setup is still pending. '
            'Retry to continue without creating another account. '
            '${prof.error ?? 'Please try again.'}',
          );
        }
      }

      Get.back<bool>(result: true);
      Get.snackbar(
        'Teacher registered',
        'The teacher account was created.',
        snackPosition: SnackPosition.BOTTOM,
      );
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

  Future<void> _pickDate(
    Rx<DateTime> target, {
    DateTime? first,
    DateTime? last,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: target.value,
      firstDate: first ?? DateTime(now.year - 100),
      lastDate: last ?? DateTime(now.year + 5),
    );
    if (picked != null) target.value = picked;
  }

  Future<void> _pickDateNullable(Rxn<DateTime> target) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: target.value ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year),
    );
    if (picked != null) target.value = picked;
  }

  @override
  void dispose() {
    for (final c in [
      _fullName,
      _email,
      _password,
      _avatarUrl,
      _phone,
      _address,
      _education,
      _experience,
      _specialization,
      _salary,
      _nationalId,
      _emergencyContact,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Register Teacher'),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackLg,
          AppSpacing.containerPaddingMobile,
          AppSpacing.stackXl,
        ),
        children: [
          _section('Account'),
          GlassInput(
            label: 'Full name',
            hint: 'Teacher name',
            controller: _fullName,
          ),
          _gap(),
          GlassInput(
            label: 'Email',
            hint: 'teacher@school.edu',
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
          Obx(
            () => ActionDropdownField<String>(
              label: 'Gender',
              hint: 'Select gender',
              value: _gender.value,
              items: [
                for (final g in _genders)
                  DropdownMenuItem(value: g, child: Text(g)),
              ],
              onChanged: (v) => _gender.value = v ?? 'Male',
            ),
          ),
          _gap(),
          Obx(
            () => _DateField(
              label: 'Date of birth',
              value: _dob.value,
              placeholder: 'Tap to pick',
              onTap: () => _pickDateNullable(_dob),
            ),
          ),
          _gap(),
          Obx(
            () => ActionDropdownField<String>(
              label: 'Marital status',
              hint: 'Select status',
              value: _maritalStatus.value,
              items: [
                for (final m in _maritalStatuses)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: (v) => _maritalStatus.value = v ?? 'Single',
            ),
          ),
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
          _gapLg(),
          _section('Employment'),
          GlassInput(
            label: 'Educational qualification',
            hint: 'e.g. M.Ed, B.Sc',
            controller: _education,
          ),
          _gap(),
          GlassInput(
            label: 'Years of experience',
            hint: 'e.g. 5',
            controller: _experience,
            keyboardType: TextInputType.number,
          ),
          _gap(),
          GlassInput(
            label: 'Specialization / subject',
            hint: 'e.g. Mathematics',
            controller: _specialization,
          ),
          _gap(),
          Obx(
            () => ActionDropdownField<String>(
              label: 'Designation',
              hint: 'Select designation',
              value: _designation.value,
              items: [
                for (final d in SalaryController.designationOptions)
                  DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: (v) => _designation.value = v ?? 'Teacher',
            ),
          ),
          _gap(),
          GlassInput(
            label: 'Base salary (monthly, optional)',
            hint: 'e.g. 60000',
            controller: _salary,
            keyboardType: TextInputType.number,
          ),
          _gap(),
          Obx(
            () => _DateField(
              label: 'Joining date',
              value: _joiningDate.value,
              onTap: () => _pickDate(_joiningDate),
            ),
          ),
          _gap(),
          GlassInput(
            label: 'National / Employee ID (optional)',
            hint: 'e.g. EMP-0421',
            controller: _nationalId,
          ),
          _gap(),
          GlassInput(
            label: 'Emergency contact',
            hint: 'Name — Phone',
            controller: _emergencyContact,
          ),
          _gap(),
          GlassInput(
            label: 'Additional notes (optional)',
            hint: 'Certifications, availability, etc.',
            controller: _notes,
          ),
          _gapLg(),
          Obx(() {
            final err = _error.value;
            if (err == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
              child: Text(
                err,
                style: AppTypography.bodyMd.copyWith(color: AppColors.error),
              ),
            );
          }),
          Obx(
            () => PrimaryButton(
              label: 'Create Teacher',
              isLoading: _submitting.value,
              expanded: true,
              onPressed: _submitting.value ? null : _submit,
            ),
          ),
        ],
      ),
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
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.stackMd,
              vertical: 14,
            ),
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
                          : AppColors.onSurface,
                    ),
                  ),
                ),
                const Icon(
                  AppIcons.calendarTodayOutlined,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
