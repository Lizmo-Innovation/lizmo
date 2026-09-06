import 'package:flutter/material.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// The pieces every auth form is made of.
///
/// Pulled out of the sign-up screen when password reset needed the same ones.
/// They were private to that file, and a second copy would have drifted the
/// first time a field's corner radius or an error banner's wording changed --
/// on the two screens a person is most likely to see side by side, one after
/// a failed login.

class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.password, required this.missing});

  final String password;
  final List<PasswordRule> missing;

  @override
  Widget build(BuildContext context) {
    final missingLabels = missing.map((rule) => rule.label).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in PasswordRules.all)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  missingLabels.contains(rule.label)
                      ? Icons.circle_outlined
                      : Icons.check_circle,
                  size: context.lizmoSize(15),
                  color: missingLabels.contains(rule.label)
                      ? LizmoColors.slate
                      : LizmoColors.teal900,
                ),
                const SizedBox(width: 8),
                Text(
                  rule.label,
                  style: LizmoType.rowSub.copyWith(
                    fontSize: context.lizmoSize(13),
                    color: missingLabels.contains(rule.label)
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


InputDecoration authFieldDecoration(String hint) {
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

class AuthTitle extends StatelessWidget {
  const AuthTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: LizmoType.screenTitle.copyWith(
          color: LizmoColors.teal900,
          fontSize: context.lizmoSize(28),
        ),
      );
}

class AuthBlurb extends StatelessWidget {
  const AuthBlurb(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: LizmoType.rowSub.copyWith(fontSize: context.lizmoSize(14)),
      );
}

class AuthBackLink extends StatelessWidget {
  const AuthBackLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.arrow_back, size: 18, color: LizmoColors.teal900),
        label: Text(
          label,
          style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
        ),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: LizmoType.rowName.copyWith(fontSize: context.lizmoSize(13)),
      );
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

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

class AuthSubmittingButton extends StatelessWidget {
  const AuthSubmittingButton({super.key});

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
