import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import 'date_field.dart';
import 'lease_term.dart';

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
    this.depositMonths,
    this.advanceMonths,
  });

  /// What the place asks up front, in months, from its details. Filled in as
  /// pesos for the room's rent until the landlord types a figure of their own.
  final int? depositMonths;
  final int? advanceMonths;

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
    int? depositMonths,
    int? advanceMonths,
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
          depositMonths: depositMonths,
          advanceMonths: advanceMonths,
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

  /// Typed by the landlord, so no longer ours to fill in.
  bool _depositOwn = false;
  bool _advanceOwn = false;

  @override
  void initState() {
    super.initState();
    _fillUpFront();
  }

  /// The place's months as pesos for this rent, where the landlord has not
  /// put a figure of their own.
  void _fillUpFront() {
    final rent = _rentNow;
    if (rent == null) return;
    final deposit = widget.depositMonths;
    if (!_depositOwn && deposit != null) {
      _deposit.text = (rent * deposit).toStringAsFixed(0);
    }
    final advance = widget.advanceMonths;
    if (!_advanceOwn && advance != null) {
      _advance.text = (rent * advance).toStringAsFixed(0);
    }
  }

  /// Said under a figure that came from the place's details.
  String? _fromDetails(int? months, bool own) =>
      months == null || own ? null : 'From your place details: ${_monthWord(months)}.';

  static String _monthWord(int months) => switch (months) {
        0 => 'none',
        1 => '1 month',
        _ => '$months months',
      };

  /// How long it is for. Month to month unless they agreed a term.
  String _term = 'none';
  DateTime? _ownEnd;

  /// Recomputed from the start, so "1 year" follows a start date changed
  /// after it was picked.
  List<TermChoice> get _terms => [
        const TermChoice('none', 'No end date', null),
        TermChoice('six', '6 months', termEnd(_start, 6)),
        TermChoice('year', '1 year', termEnd(_start, 12)),
      ];

  DateTime? get _endsOn => _term == LeaseTermChoices.own
      ? _ownEnd
      : _terms.firstWhere((choice) => choice.key == _term).date;

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
      _fillUpFront();
    });
  }

  /// Whether the landlord has said everything this acceptance needs.
  ///
  /// A room, when the tenant named none: the server refuses it otherwise, and
  /// a button that fails after the tap reads as the app being broken.
  bool get _ready =>
      (widget.rooms == null || _room != null) &&
      // A date of their own, once they have said they want one.
      (_term != LeaseTermChoices.own || _ownEnd != null);

  /// Their first name, as the rest of the app says it to the landlord.
  String get _firstName {
    final name = widget.tenantName.trim();
    if (name.isEmpty || name == 'this tenant') return 'Your tenant';
    return name.split(' ').first;
  }

  /// What the Start button is waiting for, or null when nothing.
  String? get _waitingFor {
    if (widget.rooms != null && _room == null) {
      return widget.rooms!.isEmpty ? 'No room to give' : 'Choose a room first';
    }
    if (_term == LeaseTermChoices.own && _ownEnd == null) {
      return 'Choose the end date first';
    }
    return null;
  }

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
      endsOn: switch (_endsOn) {
        final end? => DateTime.utc(end.year, end.month, end.day),
        null => null,
      },
    ));
  }

  /// Why an advance cannot be taken as it stands, or null when it can.
  ///
  /// Whole months only: P3000 on P2500 rent would pay one month and leave
  /// P500 recorded nowhere. Said here, before saving, in the server's words.
  String? _wholeMonths(num advance) {
    final rent = _rentNow;
    if (rent == null || rent <= 0 || advance <= 0) return null;
    if (advance % rent == 0) return null;
    return 'An advance pays for whole months: '
        '${LizmoMoney.peso(rent)} or ${LizmoMoney.peso(rent * 2)}';
  }

  /// "P5,000 covers October and November": which months, from the start
  /// date, so a landlord typing an amount sees what it buys.
  String _advanceSays() {
    final advance = num.tryParse(_advance.text.trim());
    final rent = _rentNow;
    if (advance == null || advance <= 0 || rent == null || rent <= 0) {
      return 'Rent paid up front, due when they move in, like the months it '
          'pays for.';
    }
    final problem = _wholeMonths(advance);
    if (problem != null) return '$problem.';

    const names = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December',
    ];
    final count = (advance ~/ rent).clamp(1, 24);
    final months = [
      for (var i = 0; i < count; i++)
        names[(_start.month - 1 + i) % 12],
    ];
    final listed = months.length == 1
        ? months.first
        : '${months.sublist(0, months.length - 1).join(', ')} and ${months.last}';
    return '${LizmoMoney.peso(advance)} covers $listed.';
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
                // The same words as the button that opened it. "Accept" was
                // left over from requests, which conversations replaced.
                'A lease for ${widget.tenantName}',
                // LizmoType.screenTitle is white, because it is drawn on the
                // teal header. This sheet is canvas-coloured, so the title was
                // white on almost-white -- the same fault the tenant page had.
                style: LizmoType.screenTitle
                    .copyWith(fontSize: 20, color: LizmoColors.teal900),
              ),
              const SizedBox(height: 4),
              Text(
                // What happens, and who sees it. It used to promise that
                // anybody else waiting on the room would be told it had gone
                // -- from when people asked about rooms. They ask about a
                // place now, so nobody else loses anything, and nobody is
                // told anything.
                widget.rooms == null
                    ? 'For ${widget.slot}. Set what you agreed. $_firstName '
                        'sees these terms in the app once the lease starts.'
                    : 'At ${widget.slot}. Choose the room and set what you '
                        'agreed. $_firstName sees these terms in the app once '
                        'the lease starts.',
                key: const ValueKey('lease-sheet-intro'),
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
                      'Nothing is vacant here right now. Free a room first, or '
                      'let $_firstName know in the conversation.',
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
                // The deposit and advance follow it, until typed over.
                onChanged: (_) => setState(_fillUpFront),
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

              const SizedBox(height: 18),
              _Label('How long'),
              const SizedBox(height: 6),
              LeaseTermChoices(
                choices: _terms,
                picked: _term,
                onPick: (key) => setState(() => _term = key),
                ownDate: _ownEnd,
                onOwnDate: (date) => setState(() => _ownEnd = date),
                firstDate: _start.add(const Duration(days: 1)),
                lastDate: _start.add(const Duration(days: 365 * 10)),
              ),
              Text(
                // What an end date does, and what it does not: nobody is
                // put out on the day.
                _endsOn == null
                    ? 'Month to month, until one of you ends it.'
                    : 'You will both be told a month before it ends, and '
                        'again in the last week. Nothing ends on its own.',
                key: const ValueKey('term-says'),
                style: LizmoType.rowSub,
              ),

              const SizedBox(height: 22),
              Text('Before they move in', style: LizmoType.sectionHeading),
              const SizedBox(height: 4),
              Text(
                // What changed: these used to be noted as already taken.
                // They are owed now, and only count once confirmed.
                'Both are due on move-in day. They mark them paid in the app, '
                'and you confirm them, the same as rent. Leave either blank '
                'if you have not agreed it.',
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
                onMonths: (value) => setState(() {
                  _depositOwn = true;
                  _deposit.text = value;
                }),
                onChanged: (_) => setState(() => _depositOwn = true),
              ),
              if (_fromDetails(widget.depositMonths, _depositOwn) case final said?) ...[
                const SizedBox(height: 4),
                Text(said,
                    key: const ValueKey('deposit-from-details'),
                    style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900)),
              ],
              const SizedBox(height: 6),
              Text(
                // Said plainly, because the two are constantly muddled and the
                // difference only matters at the end, when it matters a lot.
                'Held against damage, and given back when they move out. '
                'Kept apart from rent in your figures.',
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
                onMonths: (value) => setState(() {
                  _advanceOwn = true;
                  _advance.text = value;
                }),
                onChanged: (_) => setState(() => _advanceOwn = true),
                check: _wholeMonths,
              ),
              if (_fromDetails(widget.advanceMonths, _advanceOwn) case final said?) ...[
                const SizedBox(height: 4),
                Text(said,
                    key: const ValueKey('advance-from-details'),
                    style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900)),
              ],
              const SizedBox(height: 6),
              Text(
                _advanceSays(),
                key: const ValueKey('advance-says'),
                style: LizmoType.rowSub.copyWith(
                  color: _wholeMonths(num.tryParse(_advance.text.trim()) ?? 0) == null
                      ? null
                      : LizmoColors.amberText,
                ),
              ),

              const SizedBox(height: 22),
              PrimaryActionButton(
                key: const ValueKey('accept-and-create'),
                // A button that is off says what it is waiting for, rather
                // than leaving the landlord to guess.
                label: _waitingFor ?? 'Start the lease',
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
    this.onChanged,
    this.check,
  });

  final TextEditingController controller;
  final String hint;
  final num? rent;
  final ValueChanged<String> onMonths;
  final ValueChanged<String>? onChanged;

  /// A further reason the amount cannot be taken, or null.
  final String? Function(num amount)? check;

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
          onChanged: onChanged,
          validator: (value) {
            final text = (value ?? '').trim();
            // Blank is a real answer: not agreed, or not yet recorded.
            if (text.isEmpty) return null;
            final amount = num.tryParse(text);
            if (amount == null) return 'Enter an amount';
            if (amount < 0) return 'That cannot be less than nothing';
            return check?.call(amount);
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
