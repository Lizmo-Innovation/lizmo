import 'package:flutter/material.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../billing/payment_channel_providers.dart';

/// What the landlord entered for a way to be paid.
class ChannelDraft {
  const ChannelDraft({
    required this.channel,
    required this.accountName,
    required this.accountNumber,
    this.image,
    this.removeQr = false,
  });

  final String channel;
  final String accountName;
  final String accountNumber;

  /// A new QR to upload. Null leaves the QR as it is, unless [removeQr].
  final PickedImage? image;

  /// Take the saved QR away.
  final bool removeQr;
}

/// Adding a way to be paid, or changing one.
///
/// Returns what was entered and does no saving itself, so the screen behind
/// can report what happened in one place.
class PaymentChannelSheet extends StatefulWidget {
  const PaymentChannelSheet({super.key, this.existing, required this.pick});

  /// Null when adding.
  final PaymentChannelResponse? existing;

  final Future<PickedImage?> Function() pick;

  static Future<ChannelDraft?> show(
    BuildContext context, {
    PaymentChannelResponse? existing,
    required Future<PickedImage?> Function() pick,
  }) {
    return showModalBottomSheet<ChannelDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LizmoColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PaymentChannelSheet(existing: existing, pick: pick),
    );
  }

  @override
  State<PaymentChannelSheet> createState() => _PaymentChannelSheetState();
}

class _PaymentChannelSheetState extends State<PaymentChannelSheet> {
  final _form = GlobalKey<FormState>();
  late final _channel = TextEditingController(text: widget.existing?.channel ?? '');
  late final _name = TextEditingController(text: widget.existing?.accountName ?? '');
  late final _number = TextEditingController(text: widget.existing?.accountNumber ?? '');

  PickedImage? _image;
  bool _removeQr = false;

  String? get _savedQr => _removeQr ? null : widget.existing?.qrUrl;

  bool get _hasQr => _image != null || _savedQr != null;

  @override
  void dispose() {
    _channel.dispose();
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await widget.pick();
    if (picked == null || !mounted) return;
    setState(() {
      _image = picked;
      _removeQr = false;
    });
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(ChannelDraft(
      channel: _channel.text.trim(),
      accountName: _name.text.trim(),
      accountNumber: _number.text.trim(),
      image: _image,
      removeQr: _removeQr,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final picked = _image;
    final saved = _savedQr;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E8E6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                editing ? 'Edit a way to pay' : 'Add a way to pay',
                style: LizmoType.screenTitle
                    .copyWith(fontSize: 20, color: LizmoColors.teal900),
              ),
              const SizedBox(height: 4),
              Text(
                'Write the account name exactly as the account shows it. '
                'Tenants check it before sending money.',
                style: LizmoType.rowSub,
              ),
              const SizedBox(height: 18),
              _Field(
                fieldKey: const ValueKey('channel-field'),
                label: 'Channel',
                controller: _channel,
                hint: 'GCash, Maya, BPI…',
                maxLength: 40,
                missing: 'Enter the channel',
              ),
              _Field(
                fieldKey: const ValueKey('account-name-field'),
                label: 'Account name',
                controller: _name,
                hint: 'Elena Reyes',
                maxLength: 120,
                missing: 'Enter the account name',
              ),
              _Field(
                fieldKey: const ValueKey('account-number-field'),
                label: 'Account number',
                controller: _number,
                hint: '0917 111 2222',
                maxLength: 60,
                missing: 'Enter the account number',
              ),
              Text('QR (optional)', style: LizmoType.rowName.copyWith(fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: LizmoColors.white,
                      child: picked != null
                          ? Image.memory(picked.bytes,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const _NoQr())
                          : saved != null
                              ? Image.network(saved,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const _NoQr())
                              : const _NoQr(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton(
                          key: const ValueKey('pick-qr'),
                          onPressed: _pick,
                          child: Text(_hasQr ? 'Replace' : 'Choose from gallery',
                              style: LizmoType.rowName
                                  .copyWith(fontSize: 13, color: LizmoColors.teal900)),
                        ),
                        if (_hasQr)
                          TextButton(
                            key: const ValueKey('remove-qr'),
                            onPressed: () => setState(() {
                              _image = null;
                              _removeQr = true;
                            }),
                            child: Text('Remove QR',
                                style: LizmoType.rowName
                                    .copyWith(fontSize: 13, color: LizmoColors.red)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              PrimaryActionButton(
                key: const ValueKey('save-channel'),
                label: 'Save',
                onPressed: _submit,
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: LizmoType.rowSub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoQr extends StatelessWidget {
  const _NoQr();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Icon(Icons.qr_code_2, color: LizmoColors.slate));
}

class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.hint,
    required this.maxLength,
    required this.missing,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final String missing;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color colour) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colour),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: LizmoType.rowName.copyWith(fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            key: fieldKey,
            controller: controller,
            maxLength: maxLength,
            autocorrect: false,
            style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
            validator: (value) => (value ?? '').trim().isEmpty ? missing : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: LizmoType.rowSub,
              counterText: '',
              filled: true,
              fillColor: LizmoColors.white,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: border(const Color(0xFFE3E8E6)),
              focusedBorder: border(LizmoColors.teal900),
              errorBorder: border(LizmoColors.red),
              focusedErrorBorder: border(LizmoColors.red),
              errorStyle: LizmoType.rowSub.copyWith(color: LizmoColors.red),
            ),
          ),
        ],
      ),
    );
  }
}
