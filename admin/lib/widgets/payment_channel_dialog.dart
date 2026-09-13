import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../admin_providers.dart';

/// Adding a way to pay Lizmo, or changing one.
///
/// Saves the details first and the QR after, because the QR is uploaded
/// against a channel that has to exist. If the details save and the QR does
/// not, the dialog stays open with the error and a second Save retries the QR
/// against the channel already made -- rather than adding it twice.
class PaymentChannelDialog extends ConsumerStatefulWidget {
  const PaymentChannelDialog({super.key, this.existing});

  /// Null when adding.
  final PaymentChannelResponse? existing;

  /// True when something was saved, so the list should be read again.
  static Future<bool?> show(BuildContext context, {PaymentChannelResponse? existing}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentChannelDialog(existing: existing),
    );
  }

  @override
  ConsumerState<PaymentChannelDialog> createState() => _PaymentChannelDialogState();
}

class _PaymentChannelDialogState extends ConsumerState<PaymentChannelDialog> {
  final _form = GlobalKey<FormState>();
  late final _channel = TextEditingController(text: widget.existing?.channel ?? '');
  late final _name = TextEditingController(text: widget.existing?.accountName ?? '');
  late final _number = TextEditingController(text: widget.existing?.accountNumber ?? '');

  PickedImage? _picked;
  bool _removeQr = false;
  bool _saving = false;
  String? _error;

  /// A channel this dialog added before its QR failed to upload.
  String? _createdId;

  @override
  void dispose() {
    _channel.dispose();
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  String? get _savedQrUrl => _removeQr ? null : widget.existing?.qrUrl;

  bool get _hasQr => _picked != null || _savedQrUrl != null;

  Future<void> _pick() async {
    final picked = await ref.read(pickImageProvider)();
    if (picked == null || !mounted) return;
    setState(() {
      _picked = picked;
      _removeQr = false;
    });
  }

  void _clearQr() => setState(() {
        _picked = null;
        _removeQr = true;
      });

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final api = ref.read(adminApiProvider);
    final request = PaymentChannelRequest(
      channel: _channel.text.trim(),
      accountName: _name.text.trim(),
      accountNumber: _number.text.trim(),
    );

    try {
      var id = widget.existing?.id ?? _createdId;
      if (id == null) {
        id = (await api.addPaymentChannel(request))?.id;
        _createdId = id;
      } else {
        await api.updatePaymentChannel(id, request);
      }

      final picked = _picked;
      if (id != null && picked != null) {
        await api.uploadPaymentChannelQr(
          id,
          http.MultipartFile.fromBytes('qr', picked.bytes, filename: picked.name),
        );
      } else if (id != null && _removeQr && widget.existing?.qrUrl != null) {
        await api.removePaymentChannelQr(id);
      }

      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(editing ? 'Edit channel' : 'Add channel',
                    style: LizmoType.sectionHeading),
                const SizedBox(height: 4),
                Text(
                  'A landlord checks the account name before sending money, so '
                  'write it exactly as the account shows it.',
                  style: LizmoType.rowSub,
                ),
                const SizedBox(height: 16),
                _Label('Channel'),
                _Field(
                  fieldKey: const ValueKey('channel-field'),
                  controller: _channel,
                  hint: 'GCash, Maya, BPI…',
                  maxLength: 40,
                  missing: 'Enter the channel',
                ),
                _Label('Account name'),
                _Field(
                  fieldKey: const ValueKey('account-name-field'),
                  controller: _name,
                  hint: 'Ariel Asebias',
                  maxLength: 120,
                  missing: 'Enter the account name',
                ),
                _Label('Account number'),
                _Field(
                  fieldKey: const ValueKey('account-number-field'),
                  controller: _number,
                  hint: '09771231234',
                  maxLength: 60,
                  missing: 'Enter the account number',
                ),
                _Label('QR (optional)'),
                Row(
                  children: [
                    QrThumbnail(url: _savedQrUrl, bytes: _picked?.bytes, size: 96),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton(
                            key: const ValueKey('pick-qr'),
                            onPressed: _saving ? null : _pick,
                            child: Text(_hasQr ? 'Replace image' : 'Choose image',
                                style: LizmoType.rowName
                                    .copyWith(fontSize: 13, color: LizmoColors.teal900)),
                          ),
                          if (_hasQr)
                            TextButton(
                              key: const ValueKey('remove-qr'),
                              onPressed: _saving ? null : _clearQr,
                              child: Text('Remove QR',
                                  style: LizmoType.rowName
                                      .copyWith(fontSize: 13, color: LizmoColors.red)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      key: const ValueKey('cancel-channel'),
                      // True if a channel was added before its QR failed, so
                      // the list behind still picks it up.
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(_createdId != null),
                      child: Text('Cancel', style: LizmoType.rowName.copyWith(fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      height: 46,
                      child: _saving
                          ? const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : PrimaryActionButton(
                              key: const ValueKey('save-channel'),
                              label: 'Save',
                              onPressed: _save,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A QR, or a square saying there is none.
///
/// Picked bytes win over a saved URL, so the dialog previews what Save will
/// upload rather than what is there now.
class QrThumbnail extends StatelessWidget {
  const QrThumbnail({super.key, this.url, this.bytes, this.size = 52});

  final String? url;
  final Uint8List? bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final picked = bytes;
    final saved = url;
    final Widget image = picked != null
        ? Image.memory(picked, fit: BoxFit.cover, errorBuilder: (_, _, _) => _none(Icons.broken_image_outlined))
        : saved != null
            ? Image.network(saved,
                fit: BoxFit.cover,
                // The link lasts ten minutes; reloading the page gets a new one.
                errorBuilder: (_, _, _) => _none(Icons.broken_image_outlined))
            : _none(Icons.qr_code_2);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        color: LizmoColors.canvas,
        child: image,
      ),
    );
  }

  static Widget _none(IconData icon) =>
      Center(child: Icon(icon, color: const Color(0xFF9AA5A1)));
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(text, style: LizmoType.rowName.copyWith(fontSize: 13)),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.controller,
    required this.hint,
    required this.maxLength,
    required this.missing,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final String missing;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color colour) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colour),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        maxLength: maxLength,
        autocorrect: false,
        style: LizmoType.rowName,
        validator: (value) => (value ?? '').trim().isEmpty ? missing : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: LizmoType.rowSub,
          counterText: '',
          filled: true,
          fillColor: LizmoColors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          enabledBorder: border(const Color(0xFFE3E8E6)),
          focusedBorder: border(LizmoColors.teal900),
          errorBorder: border(LizmoColors.red),
          focusedErrorBorder: border(LizmoColors.red),
          errorStyle: LizmoType.rowSub.copyWith(color: LizmoColors.red),
        ),
      ),
    );
  }
}
