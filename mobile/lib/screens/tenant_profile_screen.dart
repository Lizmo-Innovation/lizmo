import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../tenant/id_labels.dart';
import '../widgets/date_field.dart';
import '../tenant/tenant_providers.dart';

/// What a tenant tells a landlord before signing a lease.
///
/// Nothing here is required to save. A tenant fills this in on a phone, often
/// standing in the doorway of the room they are about to rent, and a form that
/// refuses the lot because the ID number is not to hand would leave nothing
/// saved at all. The banner at the top says what is still missing instead.
///
/// The name at the top is the account's own, not a field of this form. A page
/// called "My profile" that never says who you are reads as broken, and a
/// tenant who has just been asked for an ID number wants to see that they are
/// filling it in as themselves. Everything below it is what a landlord asks a
/// *tenant*: who to call in an emergency, what ID they carry, where they are
/// from.
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
  final _contactPhone = TextEditingController();

  /// Seeded once from the API. A rebuild must never overwrite what is typed.
  bool _seeded = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _permanentAddress.dispose();
    _occupation.dispose();
    _contactPhone.dispose();
    _emergencyName.dispose();
    _emergencyRelationship.dispose();
    _emergencyPhone.dispose();
    _idNumber.dispose();
    super.dispose();
  }

  void _seed(TenantProfileResponse profile) {
    _permanentAddress.text = profile.permanentAddress ?? '';
    _occupation.text = profile.occupation ?? '';
    _contactPhone.text = profile.contactPhone ?? '';
    _emergencyName.text = profile.emergencyContactName ?? '';
    _emergencyRelationship.text = profile.emergencyContactRelationship ?? '';
    _emergencyPhone.text = profile.emergencyContactPhone ?? '';
    _idNumber.text = profile.idNumber ?? '';
    _birthdate = profile.birthdate;
    _idType = TenantProfileRequestIdTypeEnum.fromJson(profile.idType?.toJson());
    _seeded = true;
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
              contactPhone: _trimToNull(_contactPhone.text),
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

  /// What a lease still needs, in the order the form asks for it. Named
  /// rather than counted: "2 things missing" makes a tenant hunt for them.
  ///
  /// The number is not here: it is not for signing, it is for being answered,
  /// and it is the only thing asked before a tenant may ask about a room.
  List<String> _whatIsMissing(List<TenantDocumentResponse> documents) {
    bool uploaded(TenantDocumentResponseDocTypeEnum kind) =>
        documents.any((document) => document.docType == kind);

    return [
      if (_emergencyName.text.trim().isEmpty ||
          _emergencyPhone.text.trim().isEmpty)
        'an emergency contact',
      if (_idType == null || _idNumber.text.trim().isEmpty) 'your ID details',
      if (!uploaded(TenantDocumentResponseDocTypeEnum.VALID_ID))
        'a photo of your ID',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myTenantProfileProvider);
    // Loading counts as nothing uploaded rather than as ready: the banner may
    // say "add a photo" for a moment, but it must never say "you are done" to
    // someone who is not.
    final documents = ref.watch(myTenantDocumentsProvider).valueOrNull ??
        const <TenantDocumentResponse>[];
    final missing = _whatIsMissing(documents);

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
                _WhoYouAre(
                  name: switch (ref.watch(authControllerProvider)) {
                    AuthSignedIn(:final session) => session.name,
                    _ => '',
                  },
                ),
                const SizedBox(height: 14),
                _ReadinessBanner(
                  missing: missing,
                  hasPhone: _contactPhone.text.trim().isNotEmpty,
                ),
                const SizedBox(height: 20),

                const _SectionHeading('How landlords reach you'),
                const SizedBox(height: 4),
                Text(
                  'Your own number. A landlord rings this to answer a room you '
                  'asked about.',
                  style: LizmoType.rowSub,
                ),
                const SizedBox(height: 10),
                _Field(
                  key: const ValueKey('contact-phone'),
                  controller: _contactPhone,
                  label: 'Mobile number',
                  hint: '09171234567',
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 24),
                const _SectionHeading('About you'),
                const SizedBox(height: 10),
                Text('Birthdate',
                    style: LizmoType.rowName.copyWith(fontSize: 13)),
                const SizedBox(height: 6),
                LizmoDateField(
                  fieldKey: const ValueKey('birthdate-field'),
                  value: _birthdate,
                  // Held as UTC midnight. The generated client formats this
                  // through toUtc(), and local midnight in Manila is the
                  // previous day in UTC — which would quietly save everyone a
                  // day older than they are.
                  onChanged: (date) => setState(() => _birthdate = date),
                  firstDate: DateTime.utc(1900, 1, 2),
                  // The API refuses a birthdate in the future.
                  lastDate: DateTime.utc(
                      DateTime.now().year, DateTime.now().month, DateTime.now().day),
                ),
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

                const SizedBox(height: 24),
                const _SectionHeading('Photographs'),
                const SizedBox(height: 4),
                Text(
                  'Location and camera details are removed before anything is '
                  'stored.',
                  style: LizmoType.rowSub,
                ),
                const SizedBox(height: 10),
                const _PhotographTile(
                  kind: TenantDocumentResponseDocTypeEnum.VALID_ID,
                  label: 'Photo of your ID',
                  hint: 'The ID you named above',
                ),
                const SizedBox(height: 12),
                const _PhotographTile(
                  kind: TenantDocumentResponseDocTypeEnum.TENANT_PHOTO,
                  label: '1x1 or selfie',
                  hint: 'So your landlord knows who to expect',
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

/// Who the tenant is signed in as.
///
/// Read from the session rather than fetched: the name arrives with the tokens
/// at sign-in, and a request to render something the app already knows is a
/// spinner for no reason.
///
/// Not a field. There is no endpoint that changes a name, so showing it in a
/// box that looks typeable would promise something that does not work.
class _WhoYouAre extends StatelessWidget {
  const _WhoYouAre({required this.name});

  final String name;

  /// One letter, from the first word that has one. Falls back to nothing
  /// rather than to a question mark, which reads as an error.
  String get _initial {
    for (final word in name.trim().split(RegExp(r'\s+'))) {
      if (word.isNotEmpty) return word.characters.first.toUpperCase();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Row(
        children: [
          Container(
            width: context.lizmoSize(46),
            height: context.lizmoSize(46),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: LizmoColors.tealBg,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initial,
              style: LizmoType.screenTitle.copyWith(
                fontSize: context.lizmoSize(20),
                color: LizmoColors.teal900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Signed in' : name,
                  style: LizmoType.rowName.copyWith(
                    fontSize: context.lizmoSize(17),
                    color: LizmoColors.teal900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'The name your landlord sees',
                  style: LizmoType.rowSub.copyWith(
                    fontSize: context.lizmoSize(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What is still missing before a lease can be signed.
///
/// Not a validation error — nothing here blocks saving. It answers the question
/// the tenant actually has, which is whether they are done, and names the gaps
/// rather than counting them: "2 things missing" only makes someone hunt.
///
/// The typed half moves as the form is typed in; the photographs move as they
/// are uploaded. Both mirror what the server decides, so the screen and the
/// API cannot disagree about whether a lease may be signed.
class _ReadinessBanner extends StatelessWidget {
  const _ReadinessBanner({required this.missing, required this.hasPhone});

  final List<String> missing;

  /// Without it a tenant cannot even ask about a room, which is the more
  /// urgent of the two and so the one the banner leads with.
  final bool hasPhone;

  @override
  Widget build(BuildContext context) {
    final ready = missing.isEmpty && hasPhone;
    final colour = ready ? LizmoColors.teal900 : LizmoColors.amberText;

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
            color: colour,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              !hasPhone
                  ? 'Add your mobile number so you can ask about a room.'
                  : ready
                      ? 'Your profile is ready for a lease.'
                      : 'Before signing a lease you still need '
                            '${_asAList(missing)}.',
              style: LizmoType.rowSub.copyWith(color: colour),
            ),
          ),
        ],
      ),
    );
  }

  /// "a and b", "a, b and c" — a comma before "and" reads as a fourth item to
  /// somebody skimming.
  static String _asAList(List<String> items) {
    if (items.length == 1) return items.single;
    return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
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
    super.key,
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

/// The IDs a Philippine tenant is likely to carry, in the words they know them
/// by. OTHER exists so that carrying something unusual does not stop someone
/// renting a bed.
class _IdTypePicker extends StatelessWidget {
  const _IdTypePicker({required this.value, required this.onChanged});

  final TenantProfileRequestIdTypeEnum? value;
  final ValueChanged<TenantProfileRequestIdTypeEnum?> onChanged;


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
                      idTypeLabel(option.toJson() as String?),
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

/// One photograph: what is there, or an invitation to add it.
///
/// Its own ConsumerStatefulWidget rather than more state on the form, so an
/// upload in progress rebuilds one tile instead of the whole screen — and a
/// tenant who backs out mid-upload does not take the form's unsaved text with
/// them.
class _PhotographTile extends ConsumerStatefulWidget {
  const _PhotographTile({
    required this.kind,
    required this.label,
    required this.hint,
  });

  final TenantDocumentResponseDocTypeEnum kind;
  final String label;
  final String hint;

  @override
  ConsumerState<_PhotographTile> createState() => _PhotographTileState();
}

class _PhotographTileState extends ConsumerState<_PhotographTile> {
  bool _uploading = false;
  String? _error;

  Future<void> _choose() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: LizmoColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: LizmoColors.teal900),
              title: Text('Take a photo', style: LizmoType.rowName),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: LizmoColors.teal900),
              // Gallery as well as camera: a 1x1 is something people already
              // have photographed, and an ID is usually shot once and kept.
              title: Text('Choose from photos', style: LizmoType.rowName),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;
    await _upload(source);
  }

  Future<void> _upload(ImageSource source) async {
    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        // A first pass at the size, so a 12MP photo is not pushed over mobile
        // data only for the server to shrink it. The server still normalises:
        // this is a courtesy to the connection, not the rule.
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );
      // Cancelling the camera is not an error.
      if (picked == null) {
        if (mounted) setState(() => _uploading = false);
        return;
      }

      final bytes = await picked.readAsBytes();
      await ref.read(tenantDocumentsApiProvider).uploadMyTenantDocument(
            widget.kind.toJson(),
            http.MultipartFile.fromBytes('file', bytes, filename: picked.name),
          );

      ref.invalidate(myTenantDocumentsProvider);
      // Readiness moves with the upload, and it lives on the profile.
      ref.invalidate(myTenantProfileProvider);
    } catch (error) {
      final failure = ApiFailure.from(error);
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(myTenantDocumentsProvider);
    final existing = documents.valueOrNull
        ?.where((document) => document.docType == widget.kind)
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Thumbnail(url: existing?.url, uploading: _uploading),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.label, style: LizmoType.rowName),
                    const SizedBox(height: 2),
                    Text(
                      existing == null ? widget.hint : 'Uploaded',
                      style: LizmoType.rowSub.copyWith(
                        color: existing == null
                            ? LizmoColors.slate
                            : LizmoColors.teal900,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _uploading ? null : _choose,
                child: Text(
                  // "Replace" rather than "Upload" once there is one: the
                  // second upload supersedes the first rather than adding to it,
                  // and the button should say so.
                  existing == null ? 'Add' : 'Replace',
                  style: LizmoType.rowName.copyWith(
                    color: _uploading ? LizmoColors.slate : LizmoColors.teal900,
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: LizmoType.rowSub.copyWith(color: LizmoColors.red),
            ),
          ],
        ],
      ),
    );
  }
}

/// The photograph itself, or a placeholder in its shape.
///
/// A fixed box either way, so a tile does not jump in height when an upload
/// lands.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, required this.uploading});

  final String? url;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 56,
        height: 56,
        color: LizmoColors.tealTint,
        child: _content(),
      ),
    );
  }

  Widget _content() {
    if (uploading) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(LizmoColors.teal900),
          ),
        ),
      );
    }
    if (url == null) {
      return const Icon(Icons.add_a_photo_outlined,
          size: 20, color: LizmoColors.teal900);
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      // The URL expires, so a failure here is expected eventually rather than
      // exceptional. A broken-image glyph would read as "your upload is gone".
      errorBuilder: (_, _, _) => const Icon(
        Icons.image_outlined,
        size: 20,
        color: LizmoColors.teal900,
      ),
    );
  }
}
