import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../push/push_providers.dart';
import '../tenant/tenant_providers.dart';

/// Closing the account, from inside the app.
///
/// Required by Google Play, and written to be honest rather than obstructive:
/// it says what goes, what stays and why, before asking anybody to confirm.
///
/// The one thing it does not do is bury the button. An app that makes leaving
/// hard is an app people leave badly — by uninstalling, which deletes nothing.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmation = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(myAccountApiProvider).deleteMyAccount();
      // Signing out locally as well: the server has ended every session, and
      // leaving a dead token in storage would show a signed-in shell that
      // fails on its first request.
      await ref.read(signOutProvider).afterClosingTheAccount();
    } on Object catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Asked before the button is offered, so somebody renting is told why not
    // while they can still do something about it — rather than after they have
    // typed DELETE.
    final deletable = ref.watch(canDeleteMyAccountProvider);

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text('Delete my account',
            style: LizmoType.screenTitle.copyWith(fontSize: 18)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Text('What happens', style: LizmoType.sectionHeading),
            const SizedBox(height: 10),
            const _Bullet(
              icon: Icons.delete_outline,
              text: 'Your name, phone number and profile details are removed — '
                  'your birthday, address, occupation, ID number and emergency '
                  'contact.',
            ),
            const _Bullet(
              icon: Icons.hide_image_outlined,
              text: 'The photographs of your ID and your 1×1 are deleted for '
                  'good, from storage as well as from Lizmo.',
            ),
            const _Bullet(
              icon: Icons.logout,
              text: 'You are signed out everywhere, on every device.',
            ),
            const _Bullet(
              icon: Icons.mail_outline,
              text: 'Your email address is released, so you can sign up again '
                  'with it later if you want to.',
            ),

            const SizedBox(height: 20),
            Text('What stays', style: LizmoType.sectionHeading),
            const SizedBox(height: 10),
            const _Bullet(
              icon: Icons.history,
              text: 'The record of any tenancy you have had — its dates, its '
                  "rent, which room. It is your landlord's record of their own "
                  'property as much as yours, so it stays until they close '
                  'their account. It no longer carries your name.',
            ),

            const SizedBox(height: 24),
            deletable.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, _) => _Blocked(failure: ApiFailure.from(error)),
              data: (_) => _Confirm(
                controller: _confirmation,
                submitting: _submitting,
                error: _error,
                onChanged: () => setState(() {}),
                onDelete: _delete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Why it cannot be done yet, and what would change that.
class _Blocked extends StatelessWidget {
  const _Blocked({required this.failure});

  final ApiFailure failure;

  @override
  Widget build(BuildContext context) {
    final tenancy = failure.code == 'ACCOUNT_HAS_ACTIVE_LEASE';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tenancy ? LizmoColors.amberBg : LizmoColors.redBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tenancy ? Icons.info_outline : Icons.error_outline,
              size: 18,
              color: tenancy ? LizmoColors.amberText : LizmoColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              failure.message,
              style: LizmoType.rowSub.copyWith(
                color: tenancy ? LizmoColors.amberText : LizmoColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The deliberate step.
///
/// Typing the word rather than tapping a red button: this cannot be undone,
/// and a confirmation somebody can complete by accident is not one.
class _Confirm extends StatelessWidget {
  const _Confirm({
    required this.controller,
    required this.submitting,
    required this.error,
    required this.onChanged,
    required this.onDelete,
  });

  final TextEditingController controller;
  final bool submitting;
  final String? error;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  static const _word = 'DELETE';

  @override
  Widget build(BuildContext context) {
    final ready = controller.text.trim().toUpperCase() == _word;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Type $_word to confirm', style: LizmoType.rowName.copyWith(fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: _word,
            hintStyle: LizmoType.rowSub,
            filled: true,
            fillColor: LizmoColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE3E8E6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: LizmoColors.red),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
        ],
        const SizedBox(height: 16),
        if (submitting)
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: LizmoColors.red.withValues(alpha: 0.6),
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
        else
          Material(
            color: ready
                ? LizmoColors.red
                : LizmoColors.red.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: ready ? onDelete : null,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Delete my account',
                  textAlign: TextAlign.center,
                  style: LizmoType.buttonLabel,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: LizmoColors.slate),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: LizmoType.rowSub)),
        ],
      ),
    );
  }
}
