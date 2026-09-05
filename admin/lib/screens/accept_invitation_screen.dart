import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../admin_providers.dart';

/// Where an invited landlord sets their password.
///
/// A public page on the console's host, because that is where the link in the
/// email already points — and a browser needs no app install, no domain and no
/// deep link to open it.
///
/// It deliberately looks nothing like the staff console: no rail, no "Lizmo
/// admin". Somebody setting their own password should not be wondering what
/// they have been given access to.
///
/// Nothing is signed in here. Accepting returns tokens, and storing them would
/// drop a landlord into a console that would immediately tell them they have no
/// access. The page ends by sending them to the app, which is where they will
/// actually work.
class AcceptInvitationScreen extends ConsumerStatefulWidget {
  const AcceptInvitationScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<AcceptInvitationScreen> createState() =>
      _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState
    extends ConsumerState<AcceptInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _password = TextEditingController();

  bool _submitting = false;
  bool _obscure = true;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _accept(InvitationDetailsResponse invitation) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(signingUpApiProvider).acceptInvitation(
            AcceptInvitationRequest(
              token: widget.token,
              name: _name.text.trim(),
              password: _password.text,
            ),
          );
      if (mounted) setState(() => _done = true);
    } on Object catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitation = ref.watch(invitationDetailsProvider(widget.token));

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _done
                  ? const _ThankYou()
                  : invitation.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (error, _) => _Unusable(failure: ApiFailure.from(error)),
                      data: (value) => value == null
                          ? const _Unusable(failure: ApiFailure(
                              code: 'INVITATION_INVALID',
                              message: 'This invitation link is not valid.',
                            ))
                          : _Form(
                              invitation: value,
                              formKey: _formKey,
                              name: _name,
                              password: _password,
                              obscure: _obscure,
                              submitting: _submitting,
                              error: _error,
                              onToggleObscure: () =>
                                  setState(() => _obscure = !_obscure),
                              onChanged: () => setState(() {}),
                              onSubmit: () => _accept(value),
                            ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.invitation,
    required this.formKey,
    required this.name,
    required this.password,
    required this.obscure,
    required this.submitting,
    required this.error,
    required this.onToggleObscure,
    required this.onChanged,
    required this.onSubmit,
  });

  final InvitationDetailsResponse invitation;
  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController password;
  final bool obscure;
  final bool submitting;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    // Whether the address already signs in to Lizmo decides the whole screen.
    // Somebody new is choosing a password; somebody who already rents through
    // Lizmo is proving the account is theirs, so a forwarded link cannot hand
    // a stranger their tenancies.
    final existing = invitation.hasAccount == true;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Lizmo', style: LizmoType.wordmark.copyWith(
            color: LizmoColors.teal900, fontSize: 30)),
          const SizedBox(height: 6),
          Text(
            existing
                ? 'You have been invited to manage rentals on Lizmo.'
                : 'You have been invited to manage your rentals with Lizmo.',
            style: LizmoType.rowSub.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: LizmoColors.tealBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.mail_outline, size: 18, color: LizmoColors.teal900),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    invitation.email ?? '',
                    style: LizmoType.rowName.copyWith(color: LizmoColors.teal900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          if (!existing) ...[
            _Label('Your name'),
            const SizedBox(height: 6),
            TextFormField(
              controller: name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration('Elena Bautista'),
              validator: (value) => (value ?? '').trim().isEmpty
                  // Their tenants see this name, not an email address.
                  ? 'Enter your name'
                  : null,
            ),
            const SizedBox(height: 16),
          ],

          _Label(existing ? 'Your Lizmo password' : 'Choose a password'),
          const SizedBox(height: 6),
          TextFormField(
            controller: password,
            obscureText: obscure,
            autofocus: existing,
            onChanged: (_) => onChanged(),
            onFieldSubmitted: (_) => submitting ? null : onSubmit(),
            decoration: _decoration(
              existing ? 'The password you already use' : 'Choose a password',
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: LizmoColors.slate,
                ),
                onPressed: onToggleObscure,
                tooltip: obscure ? 'Show password' : 'Hide password',
              ),
            ),
            validator: (value) {
              if ((value ?? '').isEmpty) {
                return existing ? 'Enter your password' : 'Choose a password';
              }
              if (!existing && !PasswordRules.isAcceptable(value!)) {
                return 'Your password is missing something below';
              }
              return null;
            },
          ),

          if (existing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'This address already has a Lizmo account. Enter its password '
                'and the landlord side will be added to it — you keep '
                'everything you already have.',
                style: LizmoType.rowSub,
              ),
            )
          else ...[
            const SizedBox(height: 12),
            _PasswordRules(password: password.text),
          ],

          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
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
                    child: Text(error!,
                        style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 22),
          submitting
              ? Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: LizmoColors.coral.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(LizmoColors.white),
                    ),
                  ),
                )
              : PrimaryActionButton(
                  label: existing ? 'Add the landlord side' : 'Create my account',
                  onPressed: onSubmit,
                ),
        ],
      ),
    );
  }
}

/// The password rules, ticked off as they are met.
class _PasswordRules extends StatelessWidget {
  const _PasswordRules({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final missing =
        PasswordRules.whatIsMissing(password).map((rule) => rule.label).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in PasswordRules.all)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  missing.contains(rule.label)
                      ? Icons.circle_outlined
                      : Icons.check_circle,
                  size: 15,
                  color: missing.contains(rule.label)
                      ? LizmoColors.slate
                      : LizmoColors.teal900,
                ),
                const SizedBox(width: 8),
                Text(
                  rule.label,
                  style: LizmoType.rowSub.copyWith(
                    color: missing.contains(rule.label)
                        ? LizmoColors.slate
                        : LizmoColors.teal900,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Done. Says what to do next, because the next thing is not on this page.
class _ThankYou extends StatelessWidget {
  const _ThankYou();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 40, color: LizmoColors.teal900),
        const SizedBox(height: 16),
        Text(
          'You are all set',
          textAlign: TextAlign.center,
          style: LizmoType.screenTitle.copyWith(
            fontSize: 24,
            color: LizmoColors.teal900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your landlord account is ready. Open the Lizmo app and sign in with '
          'this email address and the password you just chose.',
          textAlign: TextAlign.center,
          style: LizmoType.rowSub.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 18),
        Text(
          'You can close this page.',
          textAlign: TextAlign.center,
          style: LizmoType.rowSub,
        ),
      ],
    );
  }
}

/// A link that cannot be used: unknown, expired, or already taken up.
class _Unusable extends StatelessWidget {
  const _Unusable({required this.failure});

  final ApiFailure failure;

  @override
  Widget build(BuildContext context) {
    final expired = failure.code == 'INVITATION_EXPIRED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Lizmo', style: LizmoType.wordmark.copyWith(
          color: LizmoColors.teal900, fontSize: 30)),
        const SizedBox(height: 24),
        Icon(
          expired ? Icons.schedule : Icons.link_off,
          size: 36,
          color: LizmoColors.slate,
        ),
        const SizedBox(height: 14),
        Text(
          expired ? 'This invitation has expired' : 'This link cannot be used',
          textAlign: TextAlign.center,
          style: LizmoType.rowName.copyWith(fontSize: 17),
        ),
        const SizedBox(height: 8),
        Text(
          // The message from the server, which distinguishes expired from
          // already-used from never-existed. Ask Lizmo, because there is
          // nothing they can do here themselves.
          '${failure.message} Ask Lizmo to send a new invitation.',
          textAlign: TextAlign.center,
          style: LizmoType.rowSub.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: LizmoType.rowName.copyWith(fontSize: 13));
}

InputDecoration _decoration(String hint) {
  OutlineInputBorder border(Color colour) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colour),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: LizmoType.rowSub,
    filled: true,
    fillColor: LizmoColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: border(const Color(0xFFE3E8E6)),
    focusedBorder: border(LizmoColors.teal900),
    errorBorder: border(LizmoColors.red),
    focusedErrorBorder: border(LizmoColors.red),
    errorStyle: LizmoType.rowSub.copyWith(color: LizmoColors.red),
  );
}
