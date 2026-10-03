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
///
/// And which builds of the mobile app are still allowed in, with the links an
/// app that is not sends people to.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _versionKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _instructions = TextEditingController();
  final _minimumBuild = TextEditingController();
  final _android = TextEditingController();
  final _ios = TextEditingController();

  bool _seeded = false;
  bool _saving = false;
  String? _error;
  bool _saved = false;

  @override
  void dispose() {
    _email.dispose();
    _instructions.dispose();
    _minimumBuild.dispose();
    _android.dispose();
    _ios.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Both cards are checked whichever Save was pressed, because one save
    // carries the whole lot: a bad update link cannot be let through because
    // the operator happened to press Save beside the support address.
    final address = _formKey.currentState?.validate() ?? false;
    final version = _versionKey.currentState?.validate() ?? false;
    if (!address || !version) return;

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
              // Blank is zero: the field is seeded from the server, so an
              // operator who empties it means the check off, not untouched.
              minimumAppBuild: int.tryParse(_minimumBuild.text.trim()) ?? 0,
              androidUpdateUrl: _android.text.trim(),
              iosUpdateUrl: _ios.text.trim(),
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
          _minimumBuild.text = '${value?.minimumAppBuild ?? 0}';
          _android.text = value?.androidUpdateUrl ?? '';
          _ios.text = value?.iosUpdateUrl ?? '';
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
          const SizedBox(height: 16),
          _card(
            key: const ValueKey('app-version-card'),
            child: Form(
              key: _versionKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Which app builds are allowed in',
                      style: LizmoType.sectionHeading),
                  const SizedBox(height: 4),
                  Text(
                    'The app asks for this when it opens. Anybody on an older '
                    'build is stopped at the splash screen and sent to update, '
                    'so raising this locks out everybody who has not updated '
                    'yet \u2014 including people mid-payment. Zero lets '
                    'everybody in.',
                    style: LizmoType.rowSub,
                  ),
                  const SizedBox(height: 16),
                  Text('Oldest build allowed', style: LizmoType.rowName),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 170,
                    child: TextFormField(
                      key: const ValueKey('minimum-app-build'),
                      controller: _minimumBuild,
                      keyboardType: TextInputType.number,
                      autocorrect: false,
                      style: LizmoType.rowName,
                      decoration: _field('0'),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return null;
                        final build = int.tryParse(text);
                        if (build == null) {
                          return 'Enter a build number, like 7';
                        }
                        if (build < 0) return 'A build number cannot be negative';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'The build number, not the version name: it only ever goes '
                    'up, and 1.10 against 1.9 is a comparison somebody has to '
                    'get right.',
                    style: LizmoType.rowSub,
                  ),
                  const SizedBox(height: 16),
                  Text('Where an app that is too old goes',
                      style: LizmoType.rowName),
                  const SizedBox(height: 10),
                  _link('Android', const ValueKey('android-update-url'), _android,
                      'https://play.google.com/store/apps/details?id=app.lizmo'),
                  const SizedBox(height: 12),
                  _link('iOS', const ValueKey('ios-update-url'), _ios,
                      'https://apps.apple.com/app/lizmo'),
                  if (_nowhereToSend.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      key: const ValueKey('nowhere-to-send'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LizmoColors.amberBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Nothing to send $_nowhereToSend to. Somebody stopped '
                        'on that phone is told to update with nowhere to go, so '
                        'add the link or put the minimum back to 0.',
                        style: LizmoType.rowSub
                            .copyWith(color: LizmoColors.amberText),
                      ),
                    ),
                  ],
                  if (_saved) ...[
                    const SizedBox(height: 12),
                    Text('Saved. The app reads it the next time it opens.',
                        style:
                            LizmoType.rowSub.copyWith(color: LizmoColors.teal900)),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
                  ],
                  const SizedBox(height: 14),
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
                              key: const ValueKey('save-app-version'),
                              label: 'Save',
                              onPressed: _save,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Which phones would be turned away with nowhere to go, if any.
  ///
  /// A minimum nobody can act on is worse than no minimum: the app stops the
  /// person and then has no button to offer them.
  String get _nowhereToSend {
    final build = int.tryParse(_minimumBuild.text.trim()) ?? 0;
    if (build <= 0) return '';
    final missing = [
      if (_android.text.trim().isEmpty) 'Android',
      if (_ios.text.trim().isEmpty) 'iOS',
    ];
    return missing.join(' or ');
  }

  Widget _card({required Widget child, Key? key}) => Container(
        key: key,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LizmoColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: child,
      );

  Widget _link(String label, Key key, TextEditingController controller,
          String hint) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Text(label, style: LizmoType.rowSub),
            ),
          ),
          Expanded(
            child: TextFormField(
              key: key,
              controller: controller,
              autocorrect: false,
              maxLength: 500,
              style: LizmoType.rowName,
              decoration: _field(hint).copyWith(counterText: ''),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return null;
                if (!text.startsWith('https://') && !text.startsWith('http://')) {
                  return 'A link has to start with https://';
                }
                return null;
              },
            ),
          ),
        ],
      );

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
