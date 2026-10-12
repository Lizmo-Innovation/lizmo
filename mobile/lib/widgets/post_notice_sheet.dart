import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../notice/notice_providers.dart';
import '../property/property_providers.dart';
import '../tenant/tenant_providers.dart';
import 'lease_term.dart';

/// Writing an announcement: what to say, to whom, and for how long.
///
/// The button names how many people it goes to -- "Send to 6 tenants" --
/// because a landlord should know before sending, not after, that it is
/// going to everybody in the building and not just the one they had in mind.
class PostNoticeSheet extends ConsumerStatefulWidget {
  const PostNoticeSheet({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  final String propertyId;
  final String propertyName;

  /// True once something was sent.
  static Future<bool> show(
    BuildContext context, {
    required String propertyId,
    required String propertyName,
  }) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LizmoColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: PostNoticeSheet(propertyId: propertyId, propertyName: propertyName),
      ),
    );
    return sent ?? false;
  }

  @override
  ConsumerState<PostNoticeSheet> createState() => _PostNoticeSheetState();
}

class _PostNoticeSheetState extends ConsumerState<PostNoticeSheet> {
  final _title = TextEditingController();
  final _message = TextEditingController();

  /// Null for everybody in the building.
  String? _unitId;

  String _until = 'none';
  DateTime? _lastDay;

  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  /// Who lives where, now: the same rows the server counts from.
  List<LeaseResponse> get _living =>
      ref.watch(propertyLeasesProvider(widget.propertyId)).valueOrNull ?? const [];

  int _countIn(String? unitId) => {
        for (final lease in _living)
          if (unitId == null || lease.unitId == unitId) lease.tenantId,
      }.length;

  static String _people(int count) => count == 1 ? '1 tenant' : '$count tenants';

  bool get _written =>
      _title.text.trim().isNotEmpty && _message.text.trim().isNotEmpty;

  /// What the Send button is waiting for, or null when it can go.
  String? _waitingFor(int audience) {
    if (audience == 0) {
      return _unitId == null ? 'Nobody lives here yet' : 'Nobody lives in that unit';
    }
    if (!_written) return 'Write a title and a message';
    if (_until == LeaseTermChoices.own && _lastDay == null) {
      return 'Choose the last day';
    }
    return null;
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final last = _until == LeaseTermChoices.own ? _lastDay : null;
    try {
      await ref.read(announcementsApiProvider).postNotice(
            widget.propertyId,
            PostNotice(
              title: _title.text.trim(),
              message: _message.text.trim(),
              unitId: _unitId,
              until: last == null ? null : DateTime.utc(last.year, last.month, last.day),
            ),
          );
      ref.invalidate(propertyNoticesProvider(widget.propertyId));
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(unitsProvider(widget.propertyId)).valueOrNull ?? const [];
    final audience = _countIn(_unitId);
    final waitingFor = _waitingFor(audience);
    final today = ref.watch(todayProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E8E6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('An announcement',
                style: LizmoType.sectionHeading.copyWith(fontSize: 17)),
            const SizedBox(height: 4),
            Text(
              'Everybody it is for is told in the app straight away. It cannot '
              'be edited once sent, only taken down.',
              style: LizmoType.rowSub,
            ),
            const SizedBox(height: 16),

            _Label('Title'),
            const SizedBox(height: 6),
            TextField(
              key: const ValueKey('notice-title'),
              controller: _title,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: _decoration('Water off on Saturday'),
            ),
            const SizedBox(height: 4),
            _Label('Message'),
            const SizedBox(height: 6),
            TextField(
              key: const ValueKey('notice-message'),
              controller: _message,
              maxLength: 2000,
              minLines: 3,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: _decoration(
                  'Maynilad is working on the main line, 9am to noon. Fill a '
                  'bucket the night before.'),
            ),
            const SizedBox(height: 10),

            _Label('Who'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              key: const ValueKey('notice-who'),
              initialValue: _unitId,
              isExpanded: true,
              decoration: _decoration(''),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'Everyone at ${widget.propertyName} (${_people(_countIn(null))})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                for (final unit in units)
                  DropdownMenuItem<String?>(
                    value: unit.id,
                    child: Text(
                      'Unit ${unit.unitNumber} only (${_people(_countIn(unit.id))})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _unitId = value),
            ),
            const SizedBox(height: 16),

            _Label('How long'),
            const SizedBox(height: 6),
            LeaseTermChoices(
              choices: const [TermChoice('none', 'Until I take it down', null)],
              picked: _until,
              onPick: (key) => setState(() => _until = key),
              ownDate: _lastDay,
              onOwnDate: (date) => setState(() => _lastDay = date),
              firstDate: DateTime(today.year, today.month, today.day),
              lastDate: today.add(const Duration(days: 365)),
              ownLabel: 'Until a date',
              ownHint: 'The last day it is shown. After it, it is gone from '
                  'their screens.',
            ),

            if (_error case final message?) ...[
              const SizedBox(height: 8),
              Text(message, style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
            ],
            const SizedBox(height: 16),
            PrimaryActionButton(
              key: const ValueKey('send-notice'),
              label: _sending
                  ? 'Sending…'
                  : waitingFor ?? 'Send to ${_people(audience)}',
              onPressed: _sending || waitingFor != null ? null : _send,
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

InputDecoration _decoration(String hint) {
  OutlineInputBorder border(Color colour) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colour),
      );

  return InputDecoration(
    hintText: hint.isEmpty ? null : hint,
    hintStyle: LizmoType.rowSub,
    hintMaxLines: 3,
    filled: true,
    fillColor: LizmoColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: border(const Color(0xFFE3E8E6)),
    focusedBorder: border(LizmoColors.teal900),
  );
}
