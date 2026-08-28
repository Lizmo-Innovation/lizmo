import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../tenant/tenant_providers.dart';

/// What a tenant tells a landlord before signing a lease.
///
/// Nothing here is required to save. A tenant fills this in on a phone, often
/// standing in the doorway of the room they are about to rent, and a form that
/// refuses the lot because the ID number is not to hand would leave nothing
/// saved at all. The banner at the top says what is still missing instead.
///
/// Identity the account already carries — name, phone, email — is not repeated
/// here. What a landlord asks a *tenant* is: who to call in an emergency, what
/// ID they carry, where they are from.
class TenantProfileScreen extends ConsumerStatefulWidget {
  const TenantProfileScreen({super.key});

  @override
  ConsumerState<TenantProfileScreen> createState() =>
      _TenantProfileScreenState();
}

class _TenantProfileScreenState extends ConsumerState<TenantProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _permanentAddress = TextEditingController();
  final _occupation = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyRelationship = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _idNumber = TextEditingController();

  DateTime? _birthdate;
  TenantProfileRequestIdTypeEnum? _idType;

  /// Seeded once from the API. A rebuild must never overwrite what is typed.
  bool _seeded = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _permanentAddress.dispose();
    _occupation.dispose();
    _emergencyName.dispose();
    _emergencyRelationship.dispose();
    _emergencyPhone.dispose();
    _idNumber.dispose();
    super.dispose();
  }

  void _seed(TenantProfileResponse profile) {
    _permanentAddress.text = profile.permanentAddress ?? '';
    _occupation.text = profile.occupation ?? '';
    _emergencyName.text = profile.emergencyContactName ?? '';
    _emergencyRelationship.text = profile.emergencyContactRelationship ?? '';
    _emergencyPhone.text = profile.emergencyContactPhone ?? '';
    _idNumber.text = profile.idNumber ?? '';
    _birthdate = profile.birthdate;
    _idType = TenantProfileRequestIdTypeEnum.fromJson(profile.idType?.toJson());
    _seeded = true;
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime.utc(now.year - 25, now.month, now.day),
      firstDate: DateTime.utc(1900, 1, 2),
      // The API refuses a birthdate in the future, so the calendar does not
      // offer one.
      lastDate: DateTime.utc(now.year, now.month, now.day),
    );
    if (picked == null) return;

    // Held as UTC midnight. The generated client formats birthdate through
    // toUtc(), and local midnight in Manila is the previous day in UTC — which
    // would quietly save everyone a day older than they are.
    setState(
      () => _birthdate = DateTime.utc(picked.year, picked.month, picked.day),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(tenantProfileApiProvider)
          .updateMyTenantProfile(
            TenantProfileRequest(
              birthdate: _birthdate,
              permanentAddress: _trimToNull(_permanentAddress.text),
              occupation: _trimToNull(_occupation.text),
              emergencyContactName: _trimToNull(_emergencyName.text),
              emergencyContactRelationship: _trimToNull(
                _emergencyRelationship.text,
              ),
              emergencyContactPhone: _trimToNull(_emergencyPhone.text),
              idType: _idType,
              idNumber: _trimToNull(_idNumber.text),
            ),
          );

      ref.invalidate(myTenantProfileProvider);

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
      }
    } catch (error) {
      final failure = ApiFailure.from(error);
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Blank is not an answer. Clearing a field stores null rather than spaces,
  /// so "not said yet" stays distinguishable from a real value.
  static String? _trimToNull(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Mirrors TenantProfile.isReadyForALease, so the banner moves as the form is
  /// filled in rather than only after a save.
  bool get _readyForALease =>
      _emergencyName.text.trim().isNotEmpty &&
      _emergencyPhone.text.trim().isNotEmpty &&
      _idType != null &&
      _idNumber.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myTenantProfileProvider);

    if (!_seeded) {
      switch (profile) {
        case AsyncData(:final value):
          _seed(value);
        case AsyncError(:final error):
          return _LoadFailed(failure: ApiFailure.from(error));
        default:
          return const _LoadingScaffold();
      }
    }

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(
          'My profile',
          style: LizmoType.screenTitle.copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Form(
            key: _formKey,
            // Every keystroke moves the readiness banner.
            onChanged: () => setState(() {}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReadinessBanner(ready: _readyForALease),
                const SizedBox(height: 20),

                const _SectionHeading('About you'),
                const SizedBox(height: 10),
                _BirthdateField(value: _birthdate, onTap: _pickBirthdate),
                const SizedBox(height: 14),
                _Field(
                  controller: _occupation,
                  label: 'Occupation',
                  hint: 'Nurse at Bicol Medical Center',
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _permanentAddress,
                  label: 'Permanent address',
                  hint: 'Brgy. San Isidro, Naga City',
                  // Where a tenant is from, not where they are renting: the
                  // address that goes on the contract, and where family can be
                  // reached.
                  maxLines: 3,
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 24),
                const _SectionHeading('Emergency contact'),
                const SizedBox(height: 4),
                Text(
                  'Who your landlord should call if something happens.',
                  style: LizmoType.rowSub,
                ),
                const SizedBox(height: 10),
                _Field(
                  controller: _emergencyName,
                  label: 'Full name',
                  hint: 'Rosa Dela Cruz',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _emergencyRelationship,
                  label: 'Relationship',
                  hint: 'Mother',
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _emergencyPhone,
                  label: 'Mobile number',
                  hint: '09171234567',
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 24),
                const _SectionHeading('Identity document'),
                const SizedBox(height: 4),
                Text(
                  'Any valid ID. Your landlord sees this only while you hold a '
                  'lease with them.',
                  style: LizmoType.rowSub,
                ),
                const SizedBox(height: 10),
                _IdTypePicker(
                  value: _idType,
                  onChanged: (next) => setState(() => _idType = next),
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _idNumber,
                  label: 'ID number',
                  hint: '1234-5678-9012',
                ),

                if (_error != null) ...[
                  const SizedBox(height: 18),
                  _ErrorBanner(message: _error!),
                ],

                const SizedBox(height: 28),
                _saving
                    ? const _SavingButton()
                    : PrimaryActionButton(
                        label: 'Save profile',
                        onPressed: _save,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What is still missing before a lease can be signed.
///
/// Not a validation error — nothing here blocks saving. It answers the question
/// the tenant actually has, which is whether they are done.
class _ReadinessBanner extends StatelessWidget {
  const _ReadinessBanner({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ready ? LizmoColors.tealBg : LizmoColors.amberBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ready ? Icons.check_circle_outline : Icons.info_outline,
            size: 18,
            color: ready ? LizmoColors.teal900 : LizmoColors.amberText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ready
                  ? 'Your profile is ready for a lease.'
                  : 'Add an emergency contact and an ID before signing a lease. '
                        'Everything else can wait.',
              style: LizmoType.rowSub.copyWith(
                color: ready ? LizmoColors.teal900 : LizmoColors.amberText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: LizmoType.sectionHeading);
}

/// A labelled text field on a card, matching the rest of the app.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: LizmoType.rowName.copyWith(fontSize: 13)),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            // No validator: every field is optional by design, and the banner
            // above says what a lease will still need.
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: LizmoType.rowSub,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tapping opens a calendar rather than asking anyone to type a date.
class _BirthdateField extends StatelessWidget {
  const _BirthdateField({required this.value, required this.onTap});

  final DateTime? value;
  final VoidCallback onTap;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LizmoColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Birthdate',
                      style: LizmoType.rowName.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // Not set reads as a dash, never as a date.
                      value == null
                          ? '—'
                          : '${_months[value!.month - 1]} ${value!.day}, ${value!.year}',
                      style: LizmoType.rowSub,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: LizmoColors.slate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The IDs a Philippine tenant is likely to carry, in the words they know them
/// by. OTHER exists so that carrying something unusual does not stop someone
/// renting a bed.
class _IdTypePicker extends StatelessWidget {
  const _IdTypePicker({required this.value, required this.onChanged});

  final TenantProfileRequestIdTypeEnum? value;
  final ValueChanged<TenantProfileRequestIdTypeEnum?> onChanged;

  static const _labels = {
    'PHILSYS': 'PhilSys (National ID)',
    'UMID': 'UMID',
    'SSS': 'SSS',
    'GSIS': 'GSIS',
    'DRIVERS_LICENSE': 'Driving licence',
    'PASSPORT': 'Passport',
    'PHILHEALTH': 'PhilHealth',
    'POSTAL': 'Postal ID',
    'VOTERS': 'Voter ID',
    'TIN': 'TIN',
    'PRC': 'PRC',
    'OTHER': 'Other',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ID type', style: LizmoType.rowName.copyWith(fontSize: 13)),
          DropdownButtonHideUnderline(
            child: DropdownButton<TenantProfileRequestIdTypeEnum?>(
              value: value,
              isExpanded: true,
              hint: Text('Choose an ID', style: LizmoType.rowSub),
              items: [
                for (final option in TenantProfileRequestIdTypeEnum.values)
                  DropdownMenuItem(
                    value: option,
                    child: Text(
                      _labels[option.toJson()] ?? option.toJson(),
                      style: LizmoType.rowSub,
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LizmoColors.redBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: LizmoColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: LizmoType.rowSub.copyWith(color: LizmoColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingButton extends StatelessWidget {
  const _SavingButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: LizmoColors.coral.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(LizmoColors.white),
        ),
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(LizmoColors.teal900),
          ),
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.failure});

  final ApiFailure failure;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: SafeArea(
        child: LizmoMessageState(
          tone: LizmoMessageTone.problem,
          icon: failure.isNetwork
              ? Icons.wifi_off_outlined
              : Icons.error_outline,
          title: failure.isNetwork
              ? "Can't reach Lizmo"
              : "Can't open your profile",
          detail: failure.message,
          actionLabel: 'Go back',
          onAction: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
