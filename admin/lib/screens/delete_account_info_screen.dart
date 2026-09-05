import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../admin_providers.dart';

/// How to delete a Lizmo account, for somebody not holding the app.
///
/// Google Play requires an account-deletion route reachable without installing
/// anything: somebody who has already uninstalled must still be able to ask,
/// and so must a person deciding whether to install at all.
///
/// Public, and outside every gate — the reader is not staff, may have no
/// account at all, and must never be shown the console sign-in.
///
/// It says the same things as the screen inside the app, deliberately. Two
/// descriptions of what deletion does is one description and one lie waiting
/// to happen, so both are written from the same list.
class DeleteAccountInfoScreen extends ConsumerWidget {
  const DeleteAccountInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final support = ref.watch(supportContactProvider);

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lizmo', style: LizmoType.wordmark.copyWith(
                    color: LizmoColors.teal900, fontSize: 30)),
                  const SizedBox(height: 6),
                  Text(
                    'Deleting your account',
                    style: LizmoType.screenTitle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 20),

                  _Section(
                    title: 'In the app',
                    body: 'Open Lizmo, tap the account button in the top right, '
                        'then "Delete my account". You will be shown what is '
                        'removed and asked to confirm.',
                  ),

                  _Section(
                    title: 'If you no longer have the app',
                    body: switch (support) {
                      AsyncData(:final value) =>
                        'Write to ${value ?? 'Lizmo'} from the email address on '
                            'your account. Requests are acted on within 30 days.',
                      AsyncError() =>
                        'Write to Lizmo from the email address on your account. '
                            'Requests are acted on within 30 days.',
                      _ => 'Loading…',
                    },
                  ),

                  _Section(
                    title: 'What is deleted',
                    bullets: [
                      'Your name, phone number and email address. The address '
                          'is released, so you can sign up again with it later.',
                      'Your profile: birthday, permanent address, occupation, '
                          'ID type and number, and your emergency contact.',
                      'The photographs of your ID and your 1×1 — deleted for '
                          'good, from file storage as well as from the '
                          'database.',
                      'Every signed-in session, on every device.',
                    ],
                  ),

                  _Section(
                    title: 'What is kept, and for how long',
                    bullets: [
                      'The record of any tenancy you have had: its dates, its '
                          'rent, and which unit or bed. This is your landlord’s '
                          'record of their own property as much as it is yours, '
                          'so deleting it would erase their history too.',
                      'It no longer carries your name or any way to identify '
                          'you, and it is kept until your landlord closes their '
                          'own Lizmo account, at which point it goes with it.',
                    ],
                  ),

                  _Section(
                    title: 'When you cannot delete yet',
                    body: 'While a tenancy is running. If you are renting, your '
                        'landlord has to end the tenancy in Lizmo first; if you '
                        'are a landlord with tenants, those tenancies have to '
                        'end first. This is so that neither side loses a record '
                        'of an arrangement the other is still relying on.',
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'Lizmo · rental management for Philippine landlords and '
                    'their tenants.',
                    style: LizmoType.rowSub,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.body, this.bullets});

  final String title;
  final String? body;
  final List<String>? bullets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LizmoType.sectionHeading),
          const SizedBox(height: 8),
          if (body != null)
            Text(body!, style: LizmoType.rowSub.copyWith(fontSize: 14, height: 1.55)),
          for (final bullet in bullets ?? const <String>[])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 10),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: LizmoColors.teal900,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      bullet,
                      style: LizmoType.rowSub.copyWith(fontSize: 14, height: 1.55),
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
