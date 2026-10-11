import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import 'date_field.dart';

/// The terms a landlord is accepting on, settled before the lease exists.
///
/// Accepting used to be a yes/no dialog that said "at the asking rent" — words,
/// not a number, because the request carried no price. It then created a lease
/// with a rent and a start date the landlord had never seen, let alone chosen.
///
/// Now both are on screen and both are editable. The rent is filled in from
/// what the tenant was looking at, because agreeing to the advertised price is
/// the ordinary case and retyping it would be a chore that invites mistakes.
class AcceptTermsSheet extends StatefulWidget {
  const AcceptTermsSheet({
    super.key,
    required this.tenantName,
    required this.slot,
    required this.askingRent,
    this.rooms,
  });

  final String tenantName;
  final String slot;
  final num? askingRent;

  /// The rooms to choose from, when the tenant asked about the place and named
  /// none. Null when the request already names one, and the picker is not
  /// shown at all.
  final List<FreeRoom>? rooms;

  /// Returns the terms, or null if the landlord backed out.
  static Future<AcceptRequest?> show(
    BuildContext context, {
    required String tenantName,
    required String slot,
    required num? askingRent,
    List<FreeRoom>? rooms,
  }) {
    return showModalBottomSheet<AcceptRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LizmoColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        // Above the keyboard: the rent field is the first thing tapped.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AcceptTermsSheet(
          tenantName: tenantName,
          slot: slot,
          askingRent: askingRent,
          rooms: rooms,
        ),
      ),
    );
  }

  @override
  State<AcceptTermsSheet> createState() => _AcceptTermsSheetState();
}

class _AcceptTermsSheetState extends State<AcceptTermsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rent = TextEditingController(
    text: widget.askingRent == null
        ? ''
        : widget.askingRent!.toStringAsFixed(0),
  );

  late DateTime _start = DateTime.now();

  /// Chosen by the landlord when the tenant named no room. Null until they do,
  /// which is what keeps Accept off.
  FreeRoom? _room;

  final _deposit = TextEditingController();
  final _advance = TextEditingController();

  @override
  void dispose() {
    _rent.dispose();
    _deposit.dispose();
    _advance.dispose();
    super.dispose();
  }

  /// The rent as typed, for the "x months" buttons to multiply.
  ///
  /// Read live rather than from askingRent: a landlord who changed the rent
  /// means the new figure when they tap "2 months".
  num? get _rentNow {
    final amount = num.tryParse(_rent.text.trim());
    return amount == null || amount <= 0 ? null : amount;
  }


  /// The room, and the rent that comes with it.
  ///
  /// The rent follows the room rather than being retyped: a landlord moving
  /// from a 2,500 bed to a 7,500 unit means the unit's price, and leaving the
  /// old figure there is how the wrong rent gets written into a lease.
  void _chooseRoom(FreeRoom? room) {
    setState(() {
      _room = room;
      if (room?.rent != null) {
        _rent.text = room!.rent!.toStringAsFixed(0);
      }
    });
  }

  /// Whether the landlord has said everything this acceptance needs.
  ///
  /// A room, when the tenant named none: the server refuses it otherwise, and
  /// a button that fails after the tap reads as the app being broken.
  bool get _ready => widget.rooms == null || _room != null;

  void _accept() {
    if (!_ready) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(AcceptRequest(
      unitId: _room?.unitId,
      bedId: _room?.bedId,
      rentAmount: num.parse(_rent.text.trim()),
      startDate: DateTime.utc(_start.year, _start.month, _start.day),
      // Left null when untouched. A landlord who took no deposit and one who
      // has not recorded it are different facts, and only null says the
      // second -- which is what lets both apps show a dash rather than "P0".
      depositAmount: _amountOrNull(_deposit),
      advanceAmount: _amountOrNull(_advance),
    ));
  }

  static num? _amountOrNull(TextEditingController field) {
    final text = field.text.trim();
    if (text.isEmpty) return null;
    return num.tryParse(text);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // Scrollable since the deposit and advance fields were added: the sheet
      // is now taller than a small phone, and a bottom sheet whose action
      // button is below the fold is a sheet nobody can complete.
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Form(
          key: _formKey,
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
              Text(
                'Accept ${widget.tenantName}',
                // LizmoType.screenTitle is white, because it is drawn on the
                // teal header. This sheet is canvas-coloured, so the title was
                // white on almost-white -- the same fault the tenant page had.
                style: LizmoType.screenTitle
                    .copyWith(fontSize: 20, color: LizmoColors.teal900),
              ),
              const SizedBox(height: 4),
              Text(
                widget.rooms == null
                    ? 'They will hold ${widget.slot}. Anyone else waiting on '
                        'it will be told it has gone.'
                    : 'They asked about the place rather than a room, so '
                        'choose which one they get.',
                style: LizmoType.rowSub,
              ),
              const SizedBox(height: 20),

              if (widget.rooms case final rooms?) ...[
                _Label('Which room'),
                const SizedBox(height: 6),
                if (rooms.isEmpty)
                  Container(
                    key: const ValueKey('no-free-rooms'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: LizmoColors.amberBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Nothing is vacant here now. Decline, or free a room first.',
                      style:
                          LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
                    ),
                  )
                else
                  for (final room in rooms)
                    _RoomChoice(
                      room: room,
                      chosen: identical(room, _room),
                      onTap: () => _chooseRoom(room),
                    ),
                const SizedBox(height: 18),
              ],

              _Label('Monthly rent'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _rent,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: _decoration('2500').copyWith(prefixText: '₱ '),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'Set the rent for this tenancy';
                  final amount = num.tryParse(text);
                  if (amount == null) return 'Enter an amount';
                  // Zero would read as free for the life of the lease.
                  if (amount <= 0) return 'The rent has to be more than nothing';
                  return null;
                },
              ),
              if (widget.askingRent != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Advertised at ${LizmoMoney.peso(widget.askingRent!)}. '
                  'Change it here if you agreed something else.',
                  style: LizmoType.rowSub,
                ),
              ],

              const SizedBox(height: 18),
              _Label('Tenancy starts'),
              const SizedBox(height: 6),
              LizmoDateField(
                fieldKey: const ValueKey('start-date'),
                value: _start,
                // A half-typed date leaves the old one standing: the rent day
                // below reads from it, and it must not flicker to today.
                onChanged: (date) => setState(() => _start = date ?? _start),
                // A tenancy can start a little in the past — somebody who
                // moved in on Saturday and is being written up on Monday —
                // and a long way ahead.
                firstDate: DateTime.now().subtract(const Duration(days: 60)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              ),
              const SizedBox(height: 6),
              Text(
                // Said out loud because the landlord does not choose it here,
                // and a rent day nobody mentioned is one they discover later.
                'Rent will fall due on the ${_ordinal(_start.day)} of each month.',
                style: LizmoType.rowSub,
              ),

              const SizedBox(height: 22),
              Text('Before they move in', style: LizmoType.sectionHeading),
              const SizedBox(height: 4),
              Text(
                'Optional, and you can leave either blank if you have not '
                'agreed it yet.',
                style: LizmoType.rowSub,
              ),

              const SizedBox(height: 14),
              _Label('Security deposit'),
              const SizedBox(height: 6),
              _MoneyField(
                key: const ValueKey('deposit-amount'),
                controller: _deposit,
                hint: '5000',
                rent: _rentNow,
                onMonths: (value) => setState(() => _deposit.text = value),
              ),
              const SizedBox(height: 6),
              Text(
                // Said plainly, because the two are constantly muddled and the
                // difference only matters at the end, when it matters a lot.
                'Held against damage, and given back when they move out.',
                style: LizmoType.rowSub,
              ),

              const SizedBox(height: 16),
              _Label('Advance rent'),
              const SizedBox(height: 6),
              _MoneyField(
                key: const ValueKey('advance-amount'),
                controller: _advance,
                hint: '2500',
                rent: _rentNow,
                onMonths: (value) => setState(() => _advance.text = value),
              ),
              const SizedBox(height: 6),
              Text(
                'Rent paid up front. It pays for the first month.',
                style: LizmoType.rowSub,
              ),

              const SizedBox(height: 22),
              PrimaryActionButton(
                key: const ValueKey('accept-and-create'),
                label: 'Accept and create the lease',
                // Off until a room is chosen, when one is needed.
                onPressed: _ready ? _accept : null,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Not yet', style: LizmoType.rowSub),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }

}

/// Top level rather than a method on the state, so the money fields below can
/// share it instead of growing a second copy that drifts from this one.
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: LizmoType.rowName.copyWith(fontSize: 13));
}

/// An amount, with buttons for the way landlords actually say it.
///
/// A landlord thinks "two months deposit", not "ten thousand pesos", but the
/// ledger has to hold pesos — a lease whose deposit is stored as a multiple of
/// a rent that later changes would quietly restate what somebody handed over.
/// So the buttons do the arithmetic once, here, and what gets saved is money.
class _MoneyField extends StatelessWidget {
  const _MoneyField({
    super.key,
    required this.controller,
    required this.hint,
    required this.rent,
    required this.onMonths,
  });

  final TextEditingController controller;
  final String hint;
  final num? rent;
  final ValueChanged<String> onMonths;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: _decoration(hint).copyWith(prefixText: '₱ '),
          validator: (value) {
            final text = (value ?? '').trim();
            // Blank is a real answer: not agreed, or not yet recorded.
            if (text.isEmpty) return null;
            final amount = num.tryParse(text);
            if (amount == null) return 'Enter an amount';
            if (amount < 0) return 'That cannot be less than nothing';
            return null;
          },
        ),
        if (rent != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final months in const [1, 2, 3])
                OutlinedButton(
                  key: ValueKey('months-$months-$hint'),
                  onPressed: () =>
                      onMonths((rent! * months).toStringAsFixed(0)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Color(0xFFE3E8E6)),
                  ),
                  child: Text(
                    months == 1 ? '1 month' : '$months months',
                    style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// One room on offer, and whether it is the one chosen.
class _RoomChoice extends StatelessWidget {
  const _RoomChoice({
    required this.room,
    required this.chosen,
    required this.onTap,
  });

  final FreeRoom room;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey('room-${room.bedId ?? room.unitId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: chosen ? LizmoColors.tealBg : LizmoColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: chosen ? LizmoColors.teal900 : const Color(0xFFE3E8E6),
            ),
          ),
          child: Row(
            children: [
              Icon(
                chosen ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 18,
                color: chosen ? LizmoColors.teal900 : LizmoColors.slate,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  room.label,
                  style: LizmoType.rowName.copyWith(
                    color: chosen ? LizmoColors.teal900 : LizmoColors.ink,
                  ),
                ),
              ),
              Text(
                room.rent == null
                    ? 'No price set'
                    : LizmoMoney.peso(room.rent!),
                style: LizmoType.rowSub.copyWith(
                  color: chosen ? LizmoColors.teal900 : LizmoColors.slate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
