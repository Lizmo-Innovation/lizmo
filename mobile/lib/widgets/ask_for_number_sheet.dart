import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../tenant/tenant_providers.dart';

/// The one thing asked before a tenant may ask about a room.
///
/// Asked here, on the room they are looking at, rather than by sending them to
/// a profile form: somebody who came to ask about a bed should not have to
/// leave, fill in a screen of details, and find their way back.
///
/// Saves the rest of the profile untouched — the endpoint takes the whole
/// thing, so what is already there is sent back with the number.
class AskForNumberSheet extends ConsumerStatefulWidget {
  const AskForNumberSheet({super.key, required this.profile});

  final TenantProfileResponse profile;

  /// True when a number was saved, so the caller can ask again straight away.
  static Future<bool> show(BuildContext context, TenantProfileResponse profile) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LizmoColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => AskForNumberSheet(profile: profile),
    );
    return saved ?? false;
  }

  @override
  ConsumerState<AskForNumberSheet> createState() => _AskForNumberSheetState();
}

class _AskForNumberSheetState extends ConsumerState<AskForNumberSheet> {
  final _number = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final was = widget.profile;
    try {
      await ref.read(tenantProfileApiProvider).updateMyTenantProfile(
            TenantProfileRequest(
              contactPhone: _number.text.trim(),
              // Everything else as it was: this endpoint replaces the profile,
              // so anything left out would be wiped by asking for a room.
              birthdate: was.birthdate,
              permanentAddress: was.permanentAddress,
              occupation: was.occupation,
              emergencyContactName: was.emergencyContactName,
              emergencyContactRelationship: was.emergencyContactRelationship,
              emergencyContactPhone: was.emergencyContactPhone,
              idType: TenantProfileRequestIdTypeEnum.fromJson(was.idType?.toJson()),
              idNumber: was.idNumber,
            ),
          );
      ref.invalidate(myTenantProfileProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DEDC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('What number can the landlord ring?',
                  style: LizmoType.sectionHeading.copyWith(fontSize: 17)),
              const SizedBox(height: 4),
              Text(
                'They answer room requests by calling or texting. Nothing else '
                'is needed to ask.',
                style: LizmoType.rowSub,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const ValueKey('ask-phone-field'),
                controller: _number,
                keyboardType: TextInputType.phone,
                autofocus: true,
                style: LizmoType.rowName,
                decoration: InputDecoration(
                  hintText: '09171234567',
                  hintStyle: LizmoType.rowSub,
                  filled: true,
                  fillColor: LizmoColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3E8E6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3E8E6)),
                  ),
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Enter the number you answer on.'
                    : null,
              ),
              if (_error case final message?) ...[
                const SizedBox(height: 10),
                Text(message,
                    style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
              ],
              const SizedBox(height: 16),
              PrimaryActionButton(
                key: const ValueKey('save-ask-phone'),
                label: _saving ? 'Saving…' : 'Save and ask',
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
