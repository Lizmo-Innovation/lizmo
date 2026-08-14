import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../router.dart';

/// Account creation.
///
/// One identifier field, as on the login screen: many Philippine tenants have a
/// mobile number and no email address, and asking them to classify which they
/// hold adds a decision for no benefit. Which one was given is inferred from
/// whether it contains "@".
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _identifier = TextEditingController();
  final _password = TextEditingController();

  bool _asLandlord = false;
  bool _submitting = false;
  bool _obscure = true;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _name.dispose();
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _looksLikeEmail => _identifier.text.contains('@');

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
      _fieldErrors = const {};
    });

    try {
      final identifier = _identifier.text.trim();
      await ref.read(authControllerProvider.notifier).register(
            name: _name.text,
            password: _password.text,
            email: _looksLikeEmail ? identifier : null,
            phone: _looksLikeEmail ? null : identifier,
            asLandlord: _asLandlord,
          );
      // No navigation: registering signs the user in, and the router reacts.
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _error = failure.message;
        // Server-side validation is shown against the field it belongs to,
        // rather than as a banner the user has to map back themselves.
        _fieldErrors = failure.fields;
      });
      _formKey.currentState?.validate();
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
                    Text(
                      'Create your account',
                      style: LizmoType.screenTitle.copyWith(
                        color: LizmoColors.teal900,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _Label('Full name'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration('Ana Reyes'),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Enter your name'
                          : _fieldErrors['name'],
                    ),
                    const SizedBox(height: 16),

                    _Label('Email or phone'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _identifier,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration('ana@example.com or 09171234567'),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter an email address or phone number';
                        }
                        return _fieldErrors['email'] ?? _fieldErrors['phone'];
                      },
                    ),
                    const SizedBox(height: 16),

                    _Label('Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitting ? null : _submit(),
                      decoration: _decoration('At least 8 characters').copyWith(
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
                        if (value == null || value.isEmpty) {
                          return 'Choose a password';
                        }
                        // Matched to the server's rule so the user is told here
                        // rather than after a round trip.
                        if (value.length < 8) {
                          return 'Use at least 8 characters';
                        }
                        return _fieldErrors['password'];
                      },
                    ),

                    const SizedBox(height: 20),
                    _LandlordToggle(
                      value: _asLandlord,
                      onChanged: (value) => setState(() => _asLandlord = value),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _error!),
                    ],

                    const SizedBox(height: 24),
                    _submitting
                        ? const _SubmittingButton()
                        : PrimaryActionButton(
                            label: 'Create account', onPressed: _submit),

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
              ),
            ),
          ),
        ),
      ),
    );
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
}

/// Asks whether the new account also manages rentals.
///
/// "Also" is doing real work: every account gets a tenant profile, and landlord
/// is added on top rather than instead. Someone who ticks this can still rent a
/// bedspace elsewhere, which is a normal case here — the role switcher exists
/// for exactly those people.
class _LandlordToggle extends StatelessWidget {
  const _LandlordToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value ? LizmoColors.tealBg : LizmoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? LizmoColors.teal900 : const Color(0xFFE3E8E6),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (next) => onChanged(next ?? false),
              activeColor: LizmoColors.teal900,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('I am also a landlord', style: LizmoType.rowName),
                  const SizedBox(height: 2),
                  Text(
                    'Adds tools for managing units, tenants and rent.',
                    style: LizmoType.rowSub,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            child: Text(message,
                style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
          ),
        ],
      ),
    );
  }
}

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
