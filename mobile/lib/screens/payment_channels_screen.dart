import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../billing/payment_channel_providers.dart';
import '../property/property_providers.dart';
import '../widgets/channel_properties_sheet.dart';
import '../widgets/payment_channel_sheet.dart';

/// Where a landlord's tenants send rent: GCash, Maya, bank, each with an
/// optional QR, and a note for anything that is not an account.
///
/// Tenants see the channels switched on, in this order, when they pay. One
/// list covers every property. Switching one off keeps it for later -- a
/// wallet at its limit for the month -- while Delete is for good, and asks.
class PaymentChannelsScreen extends ConsumerStatefulWidget {
  const PaymentChannelsScreen({super.key});

  @override
  ConsumerState<PaymentChannelsScreen> createState() => _PaymentChannelsScreenState();
}

class _PaymentChannelsScreenState extends ConsumerState<PaymentChannelsScreen> {
  final _note = TextEditingController();
  bool _noteSeeded = false;
  bool _busy = false;
  bool _savingNote = false;

  /// An account just added, waiting to be asked where it is used.
  PaymentChannelResponse? _askWhere;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  PaymentChannelsApi get _api => ref.read(paymentChannelsApiProvider);

  /// Runs a change, says how it went, and reads the list again either way.
  Future<void> _run(Future<String> Function() call) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final done = await call();
      if (done.isNotEmpty) messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(ApiFailure.from(error).message)));
    } finally {
      ref.invalidate(myPaymentChannelsProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([PaymentChannelResponse? existing]) async {
    final draft = await PaymentChannelSheet.show(
      context,
      existing: existing,
      pick: ref.read(pickGalleryImageProvider),
    );
    if (draft == null || !mounted) return;

    await _run(() async {
      final request = PaymentChannelRequest(
        channel: draft.channel,
        accountName: draft.accountName,
        accountNumber: draft.accountNumber,
      );
      final saved = existing == null
          ? await _api.addMyPaymentChannel(request)
          : await _api.updateMyPaymentChannel(existing.id!, request);
      final id = saved?.id ?? existing?.id;
      // Nothing said for a new one: the sheet asking where it is used opens on
      // top of this, and a snackbar would sit over its Save button.
      final done = existing == null ? '' : 'Saved.';
      if (id == null) return done;

      // The details are saved by now. A QR that fails to upload should say so
      // without making it look as though nothing was kept.
      try {
        if (draft.image case final image?) {
          await _api.uploadMyPaymentChannelQr(
            id,
            http.MultipartFile.fromBytes('qr', image.bytes, filename: image.name),
          );
        } else if (draft.removeQr && existing?.qrUrl != null) {
          await _api.removeMyPaymentChannelQr(id);
        }
      } catch (error) {
        return 'Saved, but the QR did not upload. Edit it to try again.';
      }
      // A new account applies nowhere, so it reaches no tenant until this is
      // answered. Asked here rather than left for the landlord to find.
      if (existing == null) _askWhere = saved;
      return done;
    });

    if (_askWhere case final added?) {
      _askWhere = null;
      if (mounted) await _useFor(added);
    }
  }

  /// Which properties an account is used for.
  Future<void> _useFor(PaymentChannelResponse channel) async {
    final properties = await ref.read(propertiesProvider.future);
    if (!mounted) return;

    final chosen = await ChannelPropertiesSheet.show(
      context,
      channel: channel.channel ?? 'this account',
      properties: properties,
      chosen: [...channel.propertyIds],
    );
    if (chosen == null || !mounted) return;

    await _run(() async {
      await _api.setMyPaymentChannelProperties(
        channel.id!,
        ChannelProperties(propertyIds: chosen),
      );
      return chosen.isEmpty ? 'No tenants see this account now.' : 'Saved.';
    });
  }

  Future<void> _show(PaymentChannelResponse channel, bool shown) => _run(() async {
        await _api.updateMyPaymentChannel(
          channel.id!,
          // The details go back unchanged: the endpoint takes the whole channel.
          PaymentChannelRequest(
            channel: channel.channel ?? '',
            accountName: channel.accountName ?? '',
            accountNumber: channel.accountNumber ?? '',
            visible: shown,
          ),
        );
        return shown ? 'Shown to tenants.' : 'Hidden from tenants.';
      });

  Future<void> _move(List<PaymentChannelResponse> rows, int from, int to) {
    final ids = [for (final row in rows) row.id!];
    ids.insert(to, ids.removeAt(from));
    return _run(() async {
      await _api.reorderMyPaymentChannels(PaymentChannelOrder(ids: ids));
      return '';
    });
  }

  Future<void> _delete(PaymentChannelResponse channel) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${channel.channel}?', style: LizmoType.sectionHeading),
        content: Text(
          'Tenants stop seeing it straight away, and its QR is deleted too. '
          'To keep it for later, switch it off instead.',
          style: LizmoType.rowSub,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('confirm-delete-channel'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete', style: TextStyle(color: LizmoColors.red)),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    await _run(() async {
      await _api.deleteMyPaymentChannel(channel.id!);
      return 'Deleted.';
    });
  }

  Future<void> _saveNote() async {
    setState(() => _savingNote = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.updateMyPaymentNote(PaymentNote(note: _note.text.trim()));
      ref.invalidate(myPaymentNoteProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Note saved.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(ApiFailure.from(error).message)));
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(myPaymentChannelsProvider);
    final note = ref.watch(myPaymentNoteProvider);
    // Filled once, when it first arrives, so a note being typed is not
    // overwritten by a refresh.
    if (!_noteSeeded) {
      if (note case AsyncData(:final value)) {
        _note.text = value ?? '';
        _noteSeeded = true;
      }
    }

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(
          'How tenants pay me',
          style: LizmoType.screenTitle.copyWith(fontSize: 18),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myPaymentChannelsProvider);
          ref.invalidate(myPaymentNoteProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              'Your tenants see these when they pay rent, in this order. Each '
              'one is shown only at the properties you use it for. Switch one '
              'off to keep it for later.',
              style: LizmoType.rowSub,
            ),
            const SizedBox(height: 14),
            const _PropertiesWithNoWayToPay(),
            ...switch (channels) {
              AsyncError(:final error) => [
                  LizmoMessageState(
                    tone: LizmoMessageTone.problem,
                    icon: Icons.error_outline,
                    title: 'Could not load your payment details',
                    detail: ApiFailure.from(error).message,
                  ),
                ],
              AsyncData(:final value) when value.isEmpty => [
                  const LizmoMessageState(
                    tone: LizmoMessageTone.neutral,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No ways to pay yet',
                    detail: 'Until you add one, your tenants are told to ask '
                        'you how to pay.',
                  ),
                ],
              AsyncData(:final value) => [
                  for (final (index, channel) in value.indexed)
                    _ChannelRow(
                      channel: channel,
                      first: index == 0,
                      last: index == value.length - 1,
                      busy: _busy,
                      onShow: (shown) => _show(channel, shown),
                      onUp: () => _move(value, index, index - 1),
                      onDown: () => _move(value, index, index + 1),
                      onEdit: () => _edit(channel),
                      onUseFor: () => _useFor(channel),
                      onDelete: () => _delete(channel),
                    ),
                ],
              _ => [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
            },
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: PrimaryActionButton(
                key: const ValueKey('add-payment-channel'),
                label: 'Add a way to pay',
                onPressed: _busy ? null : () => _edit(),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              key: const ValueKey('payment-note-card'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: LizmoColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE3E8E6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Note for tenants', style: LizmoType.rowName),
                  const SizedBox(height: 2),
                  Text(
                    'Optional. Shown under your channels, for anything that is '
                    'not an account.',
                    style: LizmoType.rowSub.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const ValueKey('payment-note-field'),
                    controller: _note,
                    maxLines: 3,
                    maxLength: 500,
                    style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
                    decoration: InputDecoration(
                      hintText: 'Anything tenants should know before paying',
                      hintStyle: LizmoType.rowSub,
                      counterText: '',
                      filled: true,
                      fillColor: LizmoColors.canvas,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _savingNote
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : TextButton(
                            key: const ValueKey('save-payment-note'),
                            onPressed: _saveNote,
                            child: Text('Save note',
                                style: LizmoType.rowName
                                    .copyWith(color: LizmoColors.teal900)),
                          ),
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

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.channel,
    required this.first,
    required this.last,
    required this.busy,
    required this.onShow,
    required this.onUp,
    required this.onDown,
    required this.onEdit,
    required this.onUseFor,
    required this.onDelete,
  });

  final PaymentChannelResponse channel;
  final bool first;
  final bool last;
  final bool busy;
  final ValueChanged<bool> onShow;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onEdit;
  final VoidCallback onUseFor;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final id = channel.id;
    final shown = channel.visible ?? true;
    final qr = channel.qrUrl;

    return Container(
      key: ValueKey('payment-channel-$id'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 4),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 48,
                  height: 48,
                  color: LizmoColors.canvas,
                  child: qr == null
                      ? const Icon(Icons.qr_code_2, color: LizmoColors.slate)
                      : Image.network(qr,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.qr_code_2, color: LizmoColors.slate)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(channel.channel ?? '',
                              style: LizmoType.rowName.copyWith(color: LizmoColors.ink)),
                        ),
                        if (!shown) ...[
                          const SizedBox(width: 8),
                          const StatusChip(status: LizmoStatus.vacant, label: 'Hidden'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${channel.accountName ?? ''} · ${channel.accountNumber ?? ''}',
                        style: LizmoType.rowSub.copyWith(fontSize: 12)),
                    const SizedBox(height: 4),
                    _UsedAt(channel: channel, busy: busy, onTap: onUseFor),
                  ],
                ),
              ),
              Switch(
                key: ValueKey('channel-visible-$id'),
                value: shown,
                activeThumbColor: LizmoColors.white,
                activeTrackColor: LizmoColors.teal900,
                onChanged: busy ? null : onShow,
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                key: ValueKey('channel-up-$id'),
                tooltip: 'Move up',
                icon: const Icon(Icons.arrow_upward, size: 18),
                onPressed: busy || first ? null : onUp,
              ),
              IconButton(
                key: ValueKey('channel-down-$id'),
                tooltip: 'Move down',
                icon: const Icon(Icons.arrow_downward, size: 18),
                onPressed: busy || last ? null : onDown,
              ),
              const Spacer(),
              TextButton(
                key: ValueKey('edit-channel-$id'),
                onPressed: busy ? null : onEdit,
                child: Text('Edit',
                    style: LizmoType.rowName.copyWith(fontSize: 13, color: LizmoColors.teal900)),
              ),
              TextButton(
                key: ValueKey('delete-channel-$id'),
                onPressed: busy ? null : onDelete,
                child: Text('Delete',
                    style: LizmoType.rowName.copyWith(fontSize: 13, color: LizmoColors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Where an account is used, and the way to change it.
///
/// Named rather than counted when there is one: "Sunrise Apartments" is what a
/// landlord recognises, and a count only helps once there are several.
class _UsedAt extends ConsumerWidget {
  const _UsedAt({required this.channel, required this.busy, required this.onTap});

  final PaymentChannelResponse channel;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = channel.propertyIds;
    final mine = ref.watch(propertiesProvider).valueOrNull;
    final none = chosen.isEmpty;

    String where() {
      if (none) return 'Not used anywhere yet';
      if (mine == null) {
        return chosen.length == 1 ? 'Used at 1 property' : 'Used at ${chosen.length} properties';
      }
      if (mine.length > 1 && chosen.length == mine.length) {
        return 'Used at all ${mine.length} properties';
      }
      final names = [
        for (final property in mine)
          if (chosen.contains(property.id)) property.name ?? 'A property',
      ];
      if (names.isEmpty) return 'Used at ${chosen.length} properties';
      return names.length == 1
          ? 'Used at ${names.first}'
          : 'Used at ${names.first} +${names.length - 1}';
    }

    return InkWell(
      key: ValueKey('channel-properties-${channel.id}'),
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_work_outlined,
                size: 14,
                color: none ? LizmoColors.amberText : LizmoColors.teal900),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                where(),
                style: LizmoType.rowSub.copyWith(
                  fontSize: 12,
                  color: none ? LizmoColors.amberText : LizmoColors.teal900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.edit_outlined,
                size: 13,
                color: none ? LizmoColors.amberText : LizmoColors.teal900),
          ],
        ),
      ),
    );
  }
}

/// The properties whose tenants have no way to pay.
///
/// The landlord cannot see this from the list itself: an account switched off,
/// or used somewhere else, leaves a property with nothing, and the first they
/// would hear of it is a tenant asking where to send rent.
class _PropertiesWithNoWayToPay extends ConsumerWidget {
  const _PropertiesWithNoWayToPay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(myPaymentChannelsProvider).valueOrNull;
    final properties = ref.watch(propertiesProvider).valueOrNull;
    if (channels == null || properties == null || properties.isEmpty) {
      return const SizedBox.shrink();
    }

    final covered = {
      for (final channel in channels)
        if (channel.visible ?? true) ...channel.propertyIds,
    };
    final missing = [
      for (final property in properties)
        if (!covered.contains(property.id)) property.name ?? 'A property',
    ];
    if (missing.isEmpty) return const SizedBox.shrink();

    return Container(
      key: const ValueKey('properties-without-payment'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LizmoColors.amberBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: LizmoColors.amberText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  missing.length == 1
                      ? 'Tenants at ${missing.first} have no way to pay you'
                      : 'Tenants at ${missing.length} properties have no way to pay you',
                  style: LizmoType.rowName
                      .copyWith(fontSize: 13, color: LizmoColors.amberText),
                ),
                const SizedBox(height: 2),
                Text(
                  missing.length == 1
                      ? 'Use one of your accounts there, and they will see it '
                          'when rent is due.'
                      : '${missing.join(', ')}. Use an account at each, and '
                          'their tenants will see it when rent is due.',
                  style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
