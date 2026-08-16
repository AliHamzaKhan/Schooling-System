import 'package:get/get.dart';

import '../../../../data/admin_api_service.dart';
import '../../../subscriptions/models/subscription_models.dart';
import '../../models/school.dart';
import '../../models/schools_repository.dart';

/// Drives the 3-step school wizard (details → contact → subscription), used for
/// BOTH creating a new school and editing an existing one. Pass a [School] via
/// `Get.arguments` to enter edit mode.
///
/// Setup requires a subscription: the last step picks a live plan and an
/// optional discount (percentage or fixed). On create the school is provisioned
/// and the subscription assigned (which records the first payment).
class CreateSchoolController extends GetxController {
  final SchoolsRepository _repo = SchoolsRepository();
  final AdminApiService _api = AdminApiService();

  /// The school being edited, or null in create mode (set from `Get.arguments`).
  School? editing;
  bool get isEdit => editing != null;

  static const _createSteps = [
    'School Details',
    'Contact Info',
    'Subscription',
    'Payment Mode',
    'Headmaster',
  ];
  static const _editSteps = [
    'School Details',
    'Contact Info',
    'Subscription',
    'Payment Mode',
  ];

  /// Create mode also provisions the school's Headmaster; edit mode does not.
  List<String> get steps => isEdit ? _editSteps : _createSteps;

  static const institutionTypes = [
    'Public School',
    'Private School',
    'Charter School',
    'International',
    'Other',
  ];

  final step = 0.obs;
  final submitting = false.obs;

  // Field values for every step. The `TextEditingController`s that edit them
  // are owned by the step widgets' State, so each field's controller is created
  // and disposed with the step that shows it, while the values below survive
  // navigating back and forth through the wizard.

  // Step 1 — details.
  final name = ''.obs;
  final registration = ''.obs;
  final description = ''.obs;
  final institutionType = RxnString();

  // Step 2 — contact.
  final phone = ''.obs;
  final email = ''.obs;
  final address = ''.obs;
  final city = ''.obs;
  final stateProvince = ''.obs;
  final postal = ''.obs;

  // Step 3 — subscription.
  final loadingPlans = true.obs;
  final plans = <SubscriptionPlanModel>[].obs;
  final selectedPlanId = RxnString();
  final discountType = DiscountType.none.obs;
  final discount = ''.obs;

  // Step 4 — payment mode (how the school pays us; stored in settings.billing).
  final paymentMethod = RxnString();
  final bankName = ''.obs;
  final accountTitle = ''.obs;
  final accountNumber = ''.obs;
  final paymentNotes = ''.obs;

  // Step 5 — headmaster (create mode only).
  final hmName = ''.obs;
  final hmEmail = ''.obs;
  final hmPassword = ''.obs;
  final hmPhone = ''.obs;

  /// Plan id the school already had (edit mode) — matched from its plan code so
  /// we only re-assign a subscription when the admin actually changes the plan.
  String? _initialPlanId;

  final error = RxnString();

  bool get isLast => step.value == steps.length - 1;
  String get title => isEdit ? 'Edit School Profile' : 'New School Profile';
  String get primaryLabel =>
      isLast ? (isEdit ? 'Save Changes' : 'Create School') : 'Next Step';

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is School) {
      editing = arg;
      _prefill(arg);
    }
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    loadingPlans.value = true;
    final res = await _api.fetchPlans();
    if (res.success && res.data != null) {
      plans.assignAll(res.data!);
      // Preselect the school's current plan (edit) or the first plan (create).
      if (editing?.planCode != null) {
        final match = plans.firstWhereOrNull((p) => p.code == editing!.planCode);
        _initialPlanId = match?.id;
        selectedPlanId.value = match?.id ?? plans.firstOrNull?.id;
      } else {
        selectedPlanId.value ??= plans.firstOrNull?.id;
      }
    }
    loadingPlans.value = false;
  }

  /// Prefills every step from the school being edited.
  void _prefill(School s) {
    name.value = s.name;
    registration.value = s.code;
    email.value = s.contactEmail ?? '';
    phone.value = s.contactPhone ?? '';
    address.value = s.address ?? '';
    final billing = s.billing;
    paymentMethod.value = billing['method'] as String?;
    bankName.value = '${billing['bank_name'] ?? ''}';
    accountTitle.value = '${billing['account_title'] ?? ''}';
    accountNumber.value = '${billing['account_number'] ?? ''}';
    paymentNotes.value = '${billing['notes'] ?? ''}';
  }

  void selectInstitutionType(String? v) => institutionType.value = v;
  void selectPaymentMethod(String? v) => paymentMethod.value = v;

  /// Builds the `settings.billing` payload from the payment-mode fields, or null
  /// when nothing was entered (so we don't write an empty block).
  Map<String, dynamic>? _billingSettings() {
    final billing = <String, dynamic>{
      if (paymentMethod.value != null) 'method': paymentMethod.value,
      if (bankName.value.trim().isNotEmpty) 'bank_name': bankName.value.trim(),
      if (accountTitle.value.trim().isNotEmpty)
        'account_title': accountTitle.value.trim(),
      if (accountNumber.value.trim().isNotEmpty)
        'account_number': accountNumber.value.trim(),
      if (paymentNotes.value.trim().isNotEmpty) 'notes': paymentNotes.value.trim(),
    };
    if (billing.isEmpty) return null;
    return {'billing': billing};
  }
  void selectPlan(String planId) => selectedPlanId.value = planId;
  void setDiscountType(DiscountType t) => discountType.value = t;

  SubscriptionPlanModel? get selectedPlan =>
      plans.firstWhereOrNull((p) => p.id == selectedPlanId.value);

  void next() {
    error.value = null;
    final stepError = _validateStep(steps[step.value]);
    if (stepError != null) {
      error.value = stepError;
      return;
    }
    if (isLast) {
      _submit();
      return;
    }
    step.value++;
  }

  /// Per-step validation, keyed by the step label so it works for both the
  /// 4-step create flow and the 3-step edit flow.
  String? _validateStep(String label) => switch (label) {
        'School Details' =>
          name.value.trim().isEmpty ? 'Official school name is required.' : null,
        'Subscription' => _validateSubscription(),
        'Headmaster' => _validateHeadmaster(),
        _ => null,
      };

  String? _validateSubscription() {
    if (plans.isEmpty) {
      return 'No subscription plans exist. Create a plan first.';
    }
    if (selectedPlanId.value == null) {
      return 'Select a subscription plan to continue.';
    }
    return _validateDiscount();
  }

  String? _validateHeadmaster() {
    if (hmName.value.trim().length < 2) {
      return "Enter the headmaster's full name.";
    }
    if (!hmEmail.value.contains('@')) {
      return "Enter a valid headmaster email.";
    }
    if (hmPassword.value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  void back() {
    error.value = null;
    if (step.value == 0) {
      Get.back<void>();
    } else {
      step.value--;
    }
  }

  /// Backend `code` is required (min 2 chars). Use the registration number when
  /// provided, otherwise derive a slug from the name.
  String _code() {
    final reg = registration.value.trim();
    if (reg.length >= 2) return reg;
    final slug = name.value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.length >= 2 ? slug : 'SCH-${DateTime.now().millisecondsSinceEpoch}';
  }

  double get _discountValue =>
      double.tryParse(discount.value.trim()) ?? 0;

  /// Validates the discount input against the selected type.
  String? _validateDiscount() {
    if (discountType.value == DiscountType.none) return null;
    final v = _discountValue;
    if (v <= 0) return 'Enter a discount amount, or choose "No discount".';
    if (discountType.value == DiscountType.percent && v > 100) {
      return 'A percentage discount cannot exceed 100%.';
    }
    return null;
  }

  Future<void> _submit() async {
    // Steps are validated on the way through; re-check the subscription as a
    // final guard (it can be reached without visiting the step in edit mode).
    final subError = _validateSubscription();
    if (subError != null) {
      error.value = subError;
      return;
    }

    submitting.value = true;
    error.value = null;
    final addr = [
      address.value.trim(),
      city.value.trim(),
      stateProvince.value.trim(),
      postal.value.trim(),
    ].where((p) => p.isNotEmpty).join(', ');

    if (isEdit) {
      await _submitEdit(addr);
    } else {
      await _submitCreate(addr);
    }
    submitting.value = false;
  }

  Future<void> _submitCreate(String addr) async {
    final billing = _billingSettings();
    final payload = <String, dynamic>{
      'name': name.value.trim(),
      'code': _code(),
      if (email.value.trim().isNotEmpty) 'contact_email': email.value.trim(),
      if (phone.value.trim().isNotEmpty) 'contact_phone': phone.value.trim(),
      if (addr.isNotEmpty) 'address': addr,
    };
    if (billing != null) payload['settings'] = billing;
    final res = await _repo.create(payload);
    if (!res.success || res.data == null) {
      error.value = res.error ?? 'Could not create the school. Try again.';
      return;
    }
    // Required: assign the subscription (with any discount). This also activates
    // the school and records the first payment.
    final assigned = await _assignSubscription(res.data!.id);
    if (!assigned) return;

    // Provision the school's Headmaster account.
    final hmOk = await _createHeadmaster(res.data!.id);
    if (!hmOk) return;

    Get.back<bool>(result: true);
    Get.snackbar('School created', '${name.value} has been added.',
        snackPosition: SnackPosition.BOTTOM);
  }

  /// Creates the school's Headmaster (create flow only). Returns false (and sets
  /// [error]) on failure — the school + subscription already exist at this point.
  Future<bool> _createHeadmaster(String schoolId) async {
    final phone = hmPhone.value.trim();
    final res = await _api.createHeadmaster(schoolId, {
      'email': hmEmail.value.trim(),
      'password': hmPassword.value,
      'full_name': hmName.value.trim(),
      if (phone.isNotEmpty) 'phone': phone,
    });
    if (!res.success) {
      error.value = res.error ??
          'School & subscription created, but the headmaster account failed.';
      return false;
    }
    return true;
  }

  Future<void> _submitEdit(String addr) async {
    final id = editing!.id;
    // `code` is not editable via SchoolUpdate; update general info only.
    final billing = _billingSettings();
    final payload = <String, dynamic>{
      'name': name.value.trim(),
      'contact_email': email.value.trim().isEmpty ? null : email.value.trim(),
      'contact_phone': phone.value.trim().isEmpty ? null : phone.value.trim(),
      if (addr.isNotEmpty) 'address': addr,
    };
    // Backend merges `settings`, so this only touches the billing block.
    if (billing != null) payload['settings'] = billing;
    final res = await _repo.update(id, payload);
    if (!res.success) {
      error.value = res.error ?? 'Could not save changes. Try again.';
      return;
    }
    // Re-assign a subscription only when the plan changed (or a discount is set).
    final planChanged = selectedPlanId.value != _initialPlanId;
    final hasDiscount = discountType.value != DiscountType.none;
    if (planChanged || hasDiscount) {
      final assigned = await _assignSubscription(id);
      if (!assigned) return;
    }
    Get.back<bool>(result: true);
    Get.snackbar('Saved', 'School profile updated.',
        snackPosition: SnackPosition.BOTTOM);
  }

  /// Assigns the selected plan + discount to [schoolId]. Returns false (and sets
  /// [error]) on failure.
  Future<bool> _assignSubscription(String schoolId) async {
    final res = await _api.assignSubscriptionInstance(
      schoolId: schoolId,
      planId: selectedPlanId.value!,
      discountType: discountType.value.code,
      discountValue: _discountValue,
    );
    if (!res.success) {
      error.value = res.error ?? 'School saved, but the subscription failed.';
      return false;
    }
    return true;
  }
}
