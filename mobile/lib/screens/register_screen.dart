import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../router.dart';
import '../widgets/auth_form.dart';

/// Signing up, in three steps: the address, the code sent to it, then a name
/// and a password.
///
/// One route rather than three. The steps only make sense in order and only
/// with what the previous one produced — a code screen reached by URL, with no
/// address behind it, is a screen with nothing to submit. Holding the flow in
/// one place also means the code lives in memory here and nowhere else.
///
/// There is no "I'm a landlord" box any more. Everybody who signs up this way
/// is a tenant; a landlord is invited by Lizmo, and self-declaring was only
/// ever going to be ticked by whoever wanted the extra buttons.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

enum _Step { address, code, details }

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  _Step _step = _Step.address;

  String _email = '';
  String _code = '';

  /// Surfaced on the code step. Set when finishing fails on the code itself,
  /// which can only happen on the last step but belongs to this one.
  String? _codeError;

  /// Seconds until another code may be asked for, straight from the server so
  /// the button counts down rather than guessing.
  int _resendAfterSeconds = 60;

  void _codeSent(String email, int resendAfterSeconds) {
    setState(() {
      _email = email;
      _resendAfterSeconds = resendAfterSeconds;
      _codeError = null;
      _step = _Step.code;
    });
  }

  void _codeEntered(String code) {
    setState(() {
      _code = code;
      _codeError = null;
      _step = _Step.details;
    });
  }

  /// Sends the user back to the code step when the code turns out to be the
  /// problem.
  ///
  /// The code is only ever checked by the call that finishes signing up —
  /// there is no endpoint that checks one without spending it, on purpose, or
  /// a guesser could burn attempts for free. So a wrong or expired code
  /// surfaces one screen late, and the honest thing is to return to the screen
  /// it belongs to rather than report it under the password field.
  void _codeRejected(String message) {
    setState(() {
      _codeError = message;
      _step = _Step.code;
    });
  }

  void _back() {
    setState(() {
      _step = _step == _Step.details ? _Step.code : _Step.address;
      _codeError = null;
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
                _Step.address => _AddressStep(
                    email: _email,
                    onSent: _codeSent,
                  ),
                _Step.code => _CodeStep(
                    email: _email,
                    error: _codeError,
                    resendAfterSeconds: _resendAfterSeconds,
                    onEntered: _codeEntered,
                    onResent: (seconds) =>
                        setState(() => _resendAfterSeconds = seconds),
                    onBack: _back,
                  ),
                _Step.details => _DetailsStep(
                    email: _email,
                    code: _code,
                    onCodeRejected: _codeRejected,
                    onBack: _back,
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
// Step one: where should the code go
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
      final seconds =
          await ref.read(authControllerProvider.notifier).startRegistration(address);
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
          AuthTitle('Create your account'),
          const SizedBox(height: 8),
          AuthBlurb(
            'We will email you a six-digit code to make sure the address is '
            'yours. Nothing is saved until you finish.',
          ),
          const SizedBox(height: 24),

          AuthFieldLabel('Email address'),
          const SizedBox(height: 6),
          TextFormField(
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
              // Deliberately loose. The server has the real rule and a code
              // that never arrives is the honest test of an address; refusing
              // valid but unusual addresses here would be worse than sending
              // one email that bounces.
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
              : PrimaryActionButton(label: 'Send me a code', onPressed: _submit),

          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go(Routes.login),
            child: Text(
              'I already have an account',
              style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step two: the code
// ---------------------------------------------------------------------------

class _CodeStep extends ConsumerStatefulWidget {
  const _CodeStep({
    required this.email,
    required this.error,
    required this.resendAfterSeconds,
    required this.onEntered,
    required this.onResent,
    required this.onBack,
  });

  final String email;
  final String? error;
  final int resendAfterSeconds;
  final ValueChanged<String> onEntered;
  final ValueChanged<int> onResent;
  final VoidCallback onBack;

  @override
  ConsumerState<_CodeStep> createState() => _CodeStepState();
}

class _CodeStepState extends ConsumerState<_CodeStep> {
  static const _digits = 6;

  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();

  Timer? _ticker;
  int _secondsLeft = 0;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.error;
    _startCountdown(widget.resendAfterSeconds);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
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
          .startRegistration(widget.email);
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

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onEntered(_code.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthBackLink(label: 'Use a different address', onTap: widget.onBack),
          const SizedBox(height: 16),
          AuthTitle('Check your email'),
          const SizedBox(height: 8),
          AuthBlurb('We sent a six-digit code to ${widget.email}. '
              'It is good for ten minutes.'),
          const SizedBox(height: 24),

          AuthFieldLabel('The code'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: _digits,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onFieldSubmitted: (_) => _continue(),
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

          if (_error != null) ...[
            const SizedBox(height: 8),
            AuthErrorBanner(message: _error!),
          ],

          const SizedBox(height: 20),
          PrimaryActionButton(label: 'Continue', onPressed: _continue),

          const SizedBox(height: 12),
          Center(
            child: _resending
                ? Text('Sending…', style: LizmoType.rowSub)
                : TextButton(
                    // Disabled until the server would accept another, rather
                    // than letting somebody tap and be told off. Every tap is
                    // an email that someone has to receive.
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

// ---------------------------------------------------------------------------
// Step three: who you are, and a password
// ---------------------------------------------------------------------------

class _DetailsStep extends ConsumerStatefulWidget {
  const _DetailsStep({
    required this.email,
    required this.code,
    required this.onCodeRejected,
    required this.onBack,
  });

  final String email;
  final String code;
  final ValueChanged<String> onCodeRejected;
  final VoidCallback onBack;

  @override
  ConsumerState<_DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends ConsumerState<_DetailsStep> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _password = TextEditingController();

  bool _submitting = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).completeRegistration(
            email: widget.email,
            code: widget.code,
            name: _name.text,
            password: _password.text,
          );
      // No navigation: finishing signs the user in, and the router reacts.
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      if (failure.code == 'OTP_INCORRECT' ||
          failure.code == 'OTP_EXPIRED' ||
          failure.code == 'OTP_ATTEMPTS_EXHAUSTED' ||
          failure.code == 'OTP_NOT_FOUND') {
        widget.onCodeRejected(failure.message);
        return;
      }
      setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final missing = PasswordRules.whatIsMissing(_password.text);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthBackLink(label: 'Back to the code', onTap: widget.onBack),
          const SizedBox(height: 16),
          AuthTitle('Almost there'),
          const SizedBox(height: 8),
          AuthBlurb('${widget.email} is confirmed. Now a name and a password.'),
          const SizedBox(height: 24),

          AuthFieldLabel('Full name'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: authFieldDecoration('Juan Dela Cruz'),
            validator: (value) => (value ?? '').trim().isEmpty
                // A landlord deciding who to let a room to sees this name, not
                // an email address.
                ? 'Enter your name'
                : null,
          ),
          const SizedBox(height: 16),

          AuthFieldLabel('Password'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onFieldSubmitted: (_) => _submitting ? null : _submit(),
            decoration: authFieldDecoration('Choose a password').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: LizmoColors.slate,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
                tooltip: _obscure ? 'Show password' : 'Hide password',
              ),
            ),
            validator: (value) {
              if ((value ?? '').isEmpty) return 'Choose a password';
              // The list below already says what is missing, in full. Repeating
              // it here in red would say the same thing twice.
              return PasswordRules.isAcceptable(value!)
                  ? null
                  : 'Your password is missing something below';
            },
          ),
          const SizedBox(height: 12),
          PasswordChecklist(
            password: _password.text,
            missing: missing,
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            AuthErrorBanner(message: _error!),
          ],

          const SizedBox(height: 24),
          _submitting
              ? const AuthSubmittingButton()
              : PrimaryActionButton(
                  label: 'Create account', onPressed: _submit),
        ],
      ),
    );
  }
}

/// The password rules, ticked off as they are met.
///
/// Shown from the start rather than after a refusal: somebody choosing a
/// password can see what is wanted while they type, instead of guessing and
/// being corrected. The same rules the server enforces, kept in
/// [PasswordRules] so there is one list rather than two.
