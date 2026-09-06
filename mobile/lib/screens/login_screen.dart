import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../router.dart';


/// Sign-in screen.
///
/// Accepts an email address or a phone number in one field, because many
/// Philippine tenants have a mobile number and no email — making the user pick
/// which kind of identifier they hold adds a decision for no benefit. The
/// backend routes on whether the value contains "@".
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();

  bool _submitting = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
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
      await ref.read(authControllerProvider.notifier).login(
            identifier: _identifier.text,
            password: _password.text,
          );
      // No navigation here: the shell watches auth state and swaps the screen.
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Lizmo', style: LizmoType.screenTitle.copyWith(
                      color: LizmoColors.teal900,
                      fontSize: 34,
                    )),
                    const SizedBox(height: 6),
                    Text(
                      'Zero-hassle ang lease mo!',
                      style: LizmoType.rowSub.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 32),

                    _FieldLabel('Email or phone'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _identifier,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration('ana@example.com or 09171234567'),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Enter your email or phone number'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel('Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitting ? null : _submit(),
                      decoration: _fieldDecoration('Your password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: LizmoColors.slate,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Enter your password'
                          : null,
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _error!),
                    ],

                    const SizedBox(height: 24),
                    _submitting
                        ? const _SubmittingButton()
                        : PrimaryActionButton(label: 'Sign in', onPressed: _submit),

                    const SizedBox(height: 16),
                    TextButton(
                      key: const ValueKey('forgot-password'),
                      onPressed: () => context.go(Routes.forgotPassword),
                      child: Text(
                        'I have forgotten my password',
                        style: LizmoType.rowSub
                            .copyWith(color: LizmoColors.teal900),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(Routes.register),
                      child: Text(
                        'New to Lizmo? Create an account',
                        style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
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
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: LizmoType.rowName.copyWith(fontSize: 13));
}

/// Failures use the red status colour, not coral — coral is the action accent,
/// and reusing it for errors would blur both meanings.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Text(
              message,
              style: LizmoType.rowSub.copyWith(color: LizmoColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps the button's footprint identical while submitting, so the layout does
/// not shift under the user's finger.
class _SubmittingButton extends StatelessWidget {
  const _SubmittingButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: LizmoColors.coral.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(LizmoColors.white),
        ),
      ),
    );
  }
}
