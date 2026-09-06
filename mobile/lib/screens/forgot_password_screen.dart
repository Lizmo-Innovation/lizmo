import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../router.dart';
import '../widgets/auth_form.dart';

/// Getting back in after forgetting a password.
///
/// Two steps rather than sign-up's three: the address, then the code and the
/// new password together. There is nothing to ask in between — the account
/// already has a name — and splitting a code from the password it unlocks
/// would put a screen between somebody and the thing they came to do.
///
/// A code is only ever checked by the call that spends it, on purpose, so a
/// wrong or expired one surfaces under the code field where it belongs.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

enum _Step { address, reset }

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  _Step _step = _Step.address;

  String _email = '';
  int _resendAfterSeconds = 60;

  void _codeSent(String email, int seconds) {
    setState(() {
      _email = email;
      _resendAfterSeconds = seconds;
      _step = _Step.reset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: switch (_step) {
                _Step.address => _AddressStep(email: _email, onSent: _codeSent),
                _Step.reset => _ResetStep(
                    email: _email,
                    resendAfterSeconds: _resendAfterSeconds,
                    onResent: (seconds) =>
                        setState(() => _resendAfterSeconds = seconds),
                    onBack: () => setState(() => _step = _Step.address),
                  ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step one: which address
// ---------------------------------------------------------------------------

class _AddressStep extends ConsumerStatefulWidget {
  const _AddressStep({required this.email, required this.onSent});

  final String email;
  final void Function(String email, int resendAfterSeconds) onSent;

  @override
  ConsumerState<_AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends ConsumerState<_AddressStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email =
      TextEditingController(text: widget.email);

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final address = _email.text.trim();
    try {
      final seconds = await ref
          .read(authControllerProvider.notifier)
          .startPasswordReset(address);
      // Moves on whether or not that address has an account. The server
      // answers identically either way, and a screen that behaved differently
      // would leak exactly what the server refuses to.
      if (mounted) widget.onSent(address, seconds);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthBackLink(
            label: 'Back to sign in',
            onTap: () => context.go(Routes.login),
          ),
          const SizedBox(height: 16),
          AuthTitle('Forgotten your password?'),
          const SizedBox(height: 8),
          AuthBlurb(
            'Tell us the address you signed up with and we will email you a '
            'six-digit code to set a new password.',
          ),
          const SizedBox(height: 24),

          AuthFieldLabel('Email address'),
          const SizedBox(height: 6),
          TextFormField(
            key: const ValueKey('reset-email'),
            controller: _email,
            autocorrect: false,
            autofocus: true,
            enableSuggestions: false,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitting ? null : _submit(),
            decoration: authFieldDecoration('ana@example.com'),
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) return 'Enter your email address';
              if (!text.contains('@') || text.endsWith('@')) {
                return 'That does not look like an email address';
              }
              return null;
            },
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            AuthErrorBanner(message: _error!),
          ],

          const SizedBox(height: 24),
          _submitting
              ? const AuthSubmittingButton()
              : PrimaryActionButton(
                  label: 'Send me a code', onPressed: _submit),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step two: the code, and the new password
// ---------------------------------------------------------------------------

class _ResetStep extends ConsumerStatefulWidget {
  const _ResetStep({
    required this.email,
    required this.resendAfterSeconds,
    required this.onResent,
    required this.onBack,
  });

  final String email;
  final int resendAfterSeconds;
  final ValueChanged<int> onResent;
  final VoidCallback onBack;

  @override
  ConsumerState<_ResetStep> createState() => _ResetStepState();
}

class _ResetStepState extends ConsumerState<_ResetStep> {
  static const _digits = 6;

  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();

  Timer? _ticker;
  int _secondsLeft = 0;
  bool _submitting = false;
  bool _resending = false;
  bool _obscured = true;
  String? _error;

  List<PasswordRule> _missing = PasswordRules.all;

  @override
  void initState() {
    super.initState();
    _startCountdown(widget.resendAfterSeconds);
    _password.addListener(() {
      setState(() => _missing = PasswordRules.whatIsMissing(_password.text));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _ticker?.cancel();
    setState(() => _secondsLeft = seconds);
    if (seconds <= 0) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft -= 1);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });

    try {
      final seconds = await ref
          .read(authControllerProvider.notifier)
          .startPasswordReset(widget.email);
      if (!mounted) return;
      // Whatever was typed belongs to the code that just died.
      _code.clear();
      widget.onResent(seconds);
      _startCountdown(seconds);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).completePasswordReset(
            email: widget.email,
            code: _code.text.trim(),
            password: _password.text,
          );
      // Signed in by the call itself, so the router takes it from here. No
      // trip back to the login screen to type a password chosen a second ago.
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthBackLink(
            label: 'Use a different address',
            onTap: widget.onBack,
          ),
          const SizedBox(height: 16),
          AuthTitle('Check your email'),
          const SizedBox(height: 8),
          // Carefully worded. The server does not say whether the address has
          // an account, so neither can this: "we sent you a code" would be a
          // claim the app cannot stand behind.
          AuthBlurb('If ${widget.email} has a Lizmo account, a six-digit code '
              'is on its way. It is good for fifteen minutes.'),
          const SizedBox(height: 24),

          AuthFieldLabel('The code'),
          const SizedBox(height: 6),
          TextFormField(
            key: const ValueKey('reset-code'),
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            maxLength: _digits,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: LizmoType.screenTitle.copyWith(
              fontSize: context.lizmoSize(24),
              letterSpacing: 8,
              color: LizmoColors.teal900,
            ),
            textAlign: TextAlign.center,
            decoration: authFieldDecoration('000000').copyWith(
              counterText: '',
              hintStyle: LizmoType.screenTitle.copyWith(
                fontSize: context.lizmoSize(24),
                letterSpacing: 8,
                color: const Color(0xFFC9D2CF),
              ),
            ),
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.length != _digits) return 'Enter the six digits';
              return null;
            },
          ),

          const SizedBox(height: 16),
          AuthFieldLabel('New password'),
          const SizedBox(height: 6),
          TextFormField(
            key: const ValueKey('reset-password'),
            controller: _password,
            obscureText: _obscured,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitting ? null : _submit(),
            decoration: authFieldDecoration('Choose a password').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: LizmoColors.slate,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              ),
            ),
            validator: (value) {
              final missing = PasswordRules.whatIsMissing(value ?? '');
              // The checklist below already names each rule, so this only has
              // to stop the submit rather than repeat all of them.
              if (missing.isNotEmpty) return 'Your password needs a little more';
              return null;
            },
          ),

          const SizedBox(height: 12),
          PasswordChecklist(password: _password.text, missing: _missing),

          if (_error != null) ...[
            const SizedBox(height: 16),
            AuthErrorBanner(message: _error!),
          ],

          const SizedBox(height: 20),
          _submitting
              ? const AuthSubmittingButton()
              : PrimaryActionButton(
                  label: 'Set my password', onPressed: _submit),

          const SizedBox(height: 12),
          Center(
            child: _resending
                ? Text('Sending…', style: LizmoType.rowSub)
                : TextButton(
                    onPressed: _secondsLeft > 0 ? null : _resend,
                    child: Text(
                      _secondsLeft > 0
                          ? 'Send another in ${_secondsLeft}s'
                          : 'Send another code',
                      style: LizmoType.rowSub.copyWith(
                        color: _secondsLeft > 0
                            ? LizmoColors.slate
                            : LizmoColors.teal900,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
