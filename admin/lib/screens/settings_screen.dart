import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../admin_providers.dart';
import '../widgets/admin_shell.dart';
import '../widgets/payment_channels_card.dart';

/// The handful of things an operator changes without a deploy.
///
/// The address a stranger is told to write to when they want their account
/// deleted and cannot use the app. It appears on a public page, which is
/// exactly why it must be changeable here — a published address that can only
/// be corrected by rebuilding and redeploying stays wrong for a week.
///
/// And where landlords send money to Lizmo: a list of channels, each with an
/// optional QR, and a note shown under them.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _instructions = TextEditingController();

  bool _seeded = false;
  bool _saving = false;
  String? _error;
  bool _saved = false;

  @override
  void dispose() {
    _email.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
      _saved = false;
    });

    try {
      await ref.read(adminApiProvider).updatePlatformSettings(
            PlatformSettings(
              supportEmail: _email.text.trim(),
              paymentInstructions: _instructions.text.trim(),
            ),
          );
      ref.invalidate(platformSettingsProvider);
      ref.invalidate(supportContactProvider);
      if (mounted) setState(() => _saved = true);
    } on Object catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(platformSettingsProvider);

    if (!_seeded) {
      switch (settings) {
        case AsyncData(:final value):
          _email.text = value?.supportEmail ?? '';
          _instructions.text = value?.paymentInstructions ?? '';
          _seeded = true;
        case AsyncError(:final error):
          return AdminShell(
            title: 'Settings',
            child: LizmoMessageState(
              icon: Icons.cloud_off_outlined,
              tone: LizmoMessageTone.problem,
              title: 'Could not load settings',
              detail: ApiFailure.from(error).message,
              actionLabel: 'Try again',
              onAction: () => ref.invalidate(platformSettingsProvider),
            ),
          );
        default:
          return const AdminShell(
            title: 'Settings',
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
      }
    }

    return AdminShell(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LizmoColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE3E8E6)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Where people write to Lizmo',
                      style: LizmoType.sectionHeading),
                  const SizedBox(height: 4),
                  Text(
                    'Shown on the public account deletion page, which anybody '
                    'can open without the app. Somebody who has uninstalled '
                    'Lizmo writes here to have their account closed, so it has '
                    'to be an address you actually read.',
                    style: LizmoType.rowSub,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _email,
                          autocorrect: false,
                          style: LizmoType.rowName,
                          decoration: _field('lizmodev@gmail.com'),
                          validator: (value) {
                            final text = (value ?? '').trim();
                            if (text.isEmpty) return 'Enter an email address';
                            if (!text.contains('@') || text.endsWith('@')) {
                              return 'That does not look like an email address';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            : PrimaryActionButton(label: 'Save', onPressed: _save),
                      ),
                    ],
                  ),
                  if (_saved) ...[
                    const SizedBox(height: 12),
                    Text('Saved. The public page shows it now.',
                        style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900)),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const PaymentChannelsCard(),
          const SizedBox(height: 16),
          Container(
            key: const ValueKey('payment-instructions-card'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LizmoColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE3E8E6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Note under the channels', style: LizmoType.sectionHeading),
                const SizedBox(height: 4),
                Text(
                  'Optional. Shown to landlords under the channels, for anything '
                  'that is not an account — what to put in the reference, when '
                  'a payment is checked.',
                  style: LizmoType.rowSub,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey('payment-instructions'),
                  controller: _instructions,
                  maxLines: 3,
                  maxLength: 1000,
                  style: LizmoType.rowName,
                  decoration: _field('Anything a landlord should know before paying')
                      .copyWith(counterText: ''),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
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
                            key: const ValueKey('save-payment-instructions'),
                            label: 'Save',
                            onPressed: _save,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _field(String hint) {
    OutlineInputBorder border(Color colour) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colour),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: LizmoType.rowSub,
      filled: true,
      fillColor: LizmoColors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      enabledBorder: border(const Color(0xFFE3E8E6)),
      focusedBorder: border(LizmoColors.teal900),
      errorBorder: border(LizmoColors.red),
      focusedErrorBorder: border(LizmoColors.red),
      errorStyle: LizmoType.rowSub.copyWith(color: LizmoColors.red),
    );
  }
}
