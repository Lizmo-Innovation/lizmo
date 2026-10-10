import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// A date somebody can type, with the calendar still a tap away.
///
/// Every date in Lizmo used to be the calendar and nothing else. For a date
/// near today that is quicker than typing; for a birthday it means scrolling
/// a calendar back twenty-seven years. Material's picker does offer a keyboard
/// mode, but it inserts nothing as you type and refuses anything that is not
/// already MM/DD/YYYY — so the fastest way in was also the one that failed.
///
/// Here the slashes appear as the digits do, and the calendar button opens the
/// same picker as before for anybody who would rather point at it.
class LizmoDateField extends StatefulWidget {
  const LizmoDateField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.fieldKey,
    this.hint = 'MM/DD/YYYY',
  });

  final DateTime? value;

  /// Null while what has been typed is not yet a date, so a half-typed
  /// 10/1 does not read as the first of October.
  final ValueChanged<DateTime?> onChanged;

  final DateTime firstDate;
  final DateTime lastDate;
  final Key? fieldKey;
  final String hint;

  @override
  State<LizmoDateField> createState() => _LizmoDateFieldState();
}

class _LizmoDateFieldState extends State<LizmoDateField> {
  final _text = TextEditingController();
  String? _problem;

  @override
  void initState() {
    super.initState();
    if (widget.value != null) _text.text = _written(widget.value!);
  }

  @override
  void didUpdateWidget(LizmoDateField old) {
    super.didUpdateWidget(old);
    // A value set from elsewhere — the calendar, or a form being reset —
    // without clobbering what somebody is in the middle of typing.
    if (widget.value != old.value &&
        widget.value != null &&
        _parsed(_text.text) != widget.value) {
      _text.text = _written(widget.value!);
      _problem = null;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  static String _written(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.year.toString().padLeft(4, '0')}';

  /// Null until all eight digits are there and they name a real date.
  ///
  /// Real, not merely in range: 02/31 is four digits of nonsense that
  /// DateTime would happily turn into the 3rd of March.
  static DateTime? _parsed(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;

    final month = int.parse(digits.substring(0, 2));
    final day = int.parse(digits.substring(2, 4));
    final year = int.parse(digits.substring(4));
    if (month < 1 || month > 12 || day < 1) return null;

    final date = DateTime.utc(year, month, day);
    if (date.month != month || date.day != day) return null;
    return date;
  }

  void _typed(String text) {
    final date = _parsed(text);
    final digits = text.replaceAll(RegExp(r'\D'), '');

    setState(() {
      if (digits.length < 8) {
        // Half-typed is not wrong yet. Nobody should be told off mid-date.
        _problem = null;
      } else if (date == null) {
        _problem = 'There is no such date';
      } else if (date.isBefore(widget.firstDate)) {
        _problem = 'That is too far back';
      } else if (date.isAfter(widget.lastDate)) {
        _problem = 'That is too far ahead';
      } else {
        _problem = null;
      }
    });

    widget.onChanged(_problem == null ? date : null);
  }

  Future<void> _pick() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value ?? _initial(),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      // Calendar only: the typed path is the field itself now, and the
      // picker's own keyboard mode is the one that rejects what it is given.
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null) return;

    final date = DateTime.utc(picked.year, picked.month, picked.day);
    _text.text = _written(date);
    setState(() => _problem = null);
    widget.onChanged(date);
  }

  /// Where the calendar opens when nothing is set: today if it is allowed,
  /// otherwise the nearest end of what is.
  DateTime _initial() {
    final now = DateTime.now();
    if (now.isBefore(widget.firstDate)) return widget.firstDate;
    if (now.isAfter(widget.lastDate)) return widget.lastDate;
    return now;
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: _problem == null ? const Color(0xFFE3E8E6) : LizmoColors.red,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: widget.fieldKey,
          controller: _text,
          keyboardType: TextInputType.number,
          inputFormatters: [_SlashesAsYouType()],
          style: LizmoType.rowName,
          onChanged: _typed,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: LizmoType.rowSub,
            filled: true,
            fillColor: LizmoColors.white,
            prefixIcon: const Icon(Icons.event_outlined,
                size: 18, color: LizmoColors.slate),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 40, minHeight: 20),
            suffixIcon: IconButton(
              key: const ValueKey('open-calendar'),
              tooltip: 'Pick from a calendar',
              icon: const Icon(Icons.calendar_month_outlined,
                  size: 20, color: LizmoColors.teal900),
              onPressed: _pick,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _problem == null ? LizmoColors.teal900 : LizmoColors.red,
              ),
            ),
          ),
        ),
        if (_problem != null) ...[
          const SizedBox(height: 6),
          Text(_problem!,
              style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
        ],
      ],
    );
  }
}

/// Puts the slashes in while somebody types the digits.
///
/// Digits only, eight of them, with separators at the two places they belong.
/// Typing over or deleting works because the whole thing is rebuilt from the
/// digits each time rather than patched.
class _SlashesAsYouType extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue before, TextEditingValue after) {
    final digits = after.text.replaceAll(RegExp(r'\D'), '');
    final kept = digits.length > 8 ? digits.substring(0, 8) : digits;

    final written = StringBuffer();
    for (var i = 0; i < kept.length; i++) {
      if (i == 2 || i == 4) written.write('/');
      written.write(kept[i]);
    }

    // Deleting a slash should take the digit before it with it, rather than
    // the slash reappearing under the cursor and nothing seeming to happen.
    final text = written.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
