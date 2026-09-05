import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../admin_providers.dart';
import '../widgets/admin_shell.dart';
import '../widgets/console_table.dart';

/// Inviting landlords, and chasing the ones who have not accepted.
///
/// The only way a landlord comes into existence: sign-up makes tenants and
/// nothing else. So this screen is where Lizmo's customers come from.
class InvitationsScreen extends ConsumerWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(invitationsProvider);

    return AdminShell(
      title: 'Invitations',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        children: [
          const _InviteForm(),
          const SizedBox(height: 26),
          Text('Waiting to be accepted', style: LizmoType.sectionHeading),
          const SizedBox(height: 10),
          invitations.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, _) => LizmoMessageState(
              icon: Icons.cloud_off_outlined,
              tone: LizmoMessageTone.problem,
              title: 'Could not load invitations',
              detail: ApiFailure.from(error).message,
              actionLabel: 'Try again',
              onAction: () => ref.invalidate(invitationsProvider),
            ),
            data: (rows) => rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Nothing outstanding. Invitations appear here until they '
                      'are accepted or withdrawn.',
                      style: LizmoType.rowSub,
                    ),
                  )
                : _InvitationTable(rows: rows),
          ),
        ],
      ),
    );
  }
}

class _InvitationTable extends ConsumerWidget {
  const _InvitationTable({required this.rows});

  final List<PendingInvitation> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConsoleTable(
      columns: const [
        ConsoleColumn('Address'),
        ConsoleColumn('Sent', width: 132),
        ConsoleColumn('Status', width: 110),
        ConsoleColumn('', width: 96),
      ],
      rows: [
        for (final invitation in rows)
          ConsoleRow(cells: [
            Text(invitation.email ?? '', style: LizmoType.rowName),
            Text(_when(invitation.sentAt), style: LizmoType.rowSub),
            StatusChip(
              status: invitation.expired == true
                  ? LizmoStatus.overdue
                  : LizmoStatus.pending,
              label: invitation.expired == true ? 'Expired' : 'Waiting',
            ),
            _RevokeButton(invitation: invitation),
          ]),
      ],
    );
  }

  /// How long ago, not a timestamp. "3 days ago" answers the question an admin
  /// is actually asking, which is whether to chase.
  static String _when(DateTime? sentAt) {
    if (sentAt == null) return '';
    final days = DateTime.now().toUtc().difference(sentAt.toUtc()).inDays;
    return switch (days) {
      0 => 'Today',
      1 => 'Yesterday',
      _ => '$days days ago',
    };
  }
}

class _RevokeButton extends ConsumerStatefulWidget {
  const _RevokeButton({required this.invitation});

  final PendingInvitation invitation;

  @override
  ConsumerState<_RevokeButton> createState() => _RevokeButtonState();
}

class _RevokeButtonState extends ConsumerState<_RevokeButton> {
  bool _working = false;

  Future<void> _revoke() async {
    setState(() => _working = true);
    try {
      await ref.read(adminApiProvider).revokeInvitation(widget.invitation.id ?? '');
      ref.invalidate(invitationsProvider);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_working) {
      return const SizedBox(
        height: 20, width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return TextButton(
      onPressed: _revoke,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Withdraw',
        style: LizmoType.rowName.copyWith(fontSize: 13, color: LizmoColors.red),
      ),
    );
  }
}

/// Sends one.
///
/// The name is optional because an admin taking a telephone call may have an
/// address and nothing else, and a greeting is not worth blocking an
/// invitation over.
class _InviteForm extends ConsumerStatefulWidget {
  const _InviteForm();

  @override
  ConsumerState<_InviteForm> createState() => _InviteFormState();
}

class _InviteFormState extends ConsumerState<_InviteForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();

  bool _sending = false;
  String? _error;
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _sending = true;
      _error = null;
      _sentTo = null;
    });

    final address = _email.text.trim();
    try {
      await ref.read(adminApiProvider).inviteLandlord(InviteLandlordRequest(
            email: address,
            name: _name.text.trim().isEmpty ? null : _name.text.trim(),
          ));
      if (!mounted) return;
      _email.clear();
      _name.clear();
      setState(() => _sentTo = address);
      ref.invalidate(invitationsProvider);
    } on Object catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Text('Invite a landlord', style: LizmoType.sectionHeading),
            const SizedBox(height: 4),
            Text(
              'Emails them a link to set up a landlord account. Good for seven '
              'days and one use.',
              style: LizmoType.rowSub,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _email,
                    autocorrect: false,
                    decoration: _field('elena@example.com', 'Email address'),
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
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: _field('Elena Bautista', 'Name (optional)'),
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: SizedBox(
                    width: 132,
                    child: _sending
                        ? const Center(
                            child: SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : PrimaryActionButton(label: 'Send invitation', onPressed: _send),
                  ),
                ),
              ],
            ),
            if (_sentTo != null) ...[
              const SizedBox(height: 12),
              Text(
                'Invitation sent to $_sentTo.',
                style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _field(String hint, String label) {
    OutlineInputBorder border(Color colour) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colour),
        );

    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: LizmoType.rowSub,
      labelStyle: LizmoType.rowSub,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: LizmoColors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: border(const Color(0xFFE3E8E6)),
      focusedBorder: border(LizmoColors.teal900),
      errorBorder: border(LizmoColors.red),
      focusedErrorBorder: border(LizmoColors.red),
      errorStyle: LizmoType.rowSub.copyWith(color: LizmoColors.red),
    );
  }
}
