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
  final _minimumAndroid = TextEditingController();
  final _minimumIos = TextEditingController();
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
    _minimumAndroid.dispose();
    _minimumIos.dispose();
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
              // Blank is sent, not omitted: the fields are seeded from the
              // server, so an operator who empties one means that platform
              // unchecked, rather than left alone.
              minimumAndroidVersion: _minimumAndroid.text.trim(),
              minimumIosVersion: _minimumIos.text.trim(),
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
          _minimumAndroid.text = value?.minimumAndroidVersion ?? '';
          _minimumIos.text = value?.minimumIosVersion ?? '';
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
                  Text('Which app versions are allowed in',
                      style: LizmoType.sectionHeading),
                  const SizedBox(height: 4),
                  Text(
                    'The app asks for this when it opens. Anybody on an older '
                    'version is stopped at the splash screen and sent to '
                    'update, so raising one locks out everybody who has not '
                    'updated yet \u2014 including people mid-payment. Leave a '
                    'version empty and that platform is not checked at all.',
                    style: LizmoType.rowSub,
                  ),
                  const SizedBox(height: 18),
                  _platform(
                    'Android',
                    version: const ValueKey('minimum-android-version'),
                    minimum: _minimumAndroid,
                    link: const ValueKey('android-update-url'),
                    url: _android,
                    hint: 'https://play.google.com/store/apps/details?id=app.lizmo',
                  ),
                  const SizedBox(height: 18),
                  _platform(
                    'iOS',
                    version: const ValueKey('minimum-ios-version'),
                    minimum: _minimumIos,
                    link: const ValueKey('ios-update-url'),
                    url: _ios,
                    hint: 'https://apps.apple.com/app/lizmo',
                  ),
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

  /// One platform's pair: how old is too old, and where that phone goes.
  ///
  /// Kept apart from the other platform's because releases drift. An iOS
  /// build can sit in review for a week after the Android one has shipped,
  /// and one shared minimum would turn away every iPhone for a fix nobody
  /// can install yet.
  Widget _platform(
    String name, {
    required Key version,
    required TextEditingController minimum,
    required Key link,
    required TextEditingController url,
    required String hint,
  }) {
    // A minimum nobody can act on is worse than no minimum: the person is
    // stopped and then offered no way out.
    final nowhereToGo = minimum.text.trim().isNotEmpty && url.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: LizmoType.rowName),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: _labelled(
                'Oldest version allowed',
                TextFormField(
                  key: version,
                  controller: minimum,
                  autocorrect: false,
                  style: LizmoType.rowName,
                  decoration: _field('1.1.1'),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    // What the app can compare: digits and dots, up to three
                    // parts. Anything else would be stored and then quietly
                    // ignored by every phone that read it.
                    if (!RegExp(r'^\d{1,5}(\.\d{1,5}){0,2}$').hasMatch(text)) {
                      return 'Digits and dots, like 1.1.1';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _labelled(
                'Where to update',
                TextFormField(
                  key: link,
                  controller: url,
                  autocorrect: false,
                  maxLength: 500,
                  style: LizmoType.rowName,
                  decoration: _field(hint).copyWith(counterText: ''),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    if (!text.startsWith('https://') &&
                        !text.startsWith('http://')) {
                      return 'A link has to start with https://';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
        if (nowhereToGo) ...[
          const SizedBox(height: 10),
          Container(
            key: ValueKey('nowhere-to-send-${name.toLowerCase()}'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LizmoColors.amberBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Nothing to send $name to. Somebody stopped on that phone is '
              'told to update with nowhere to go, so add the link or clear '
              'the version.',
              style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
            ),
          ),
        ],
      ],
    );
  }

  Widget _labelled(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: LizmoType.rowSub),
          const SizedBox(height: 6),
          field,
        ],
      );

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
