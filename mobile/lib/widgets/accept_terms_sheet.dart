import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

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
  });

  final String tenantName;
  final String slot;
  final num? askingRent;

  /// Returns the terms, or null if the landlord backed out.
  static Future<AcceptRequest?> show(
    BuildContext context, {
    required String tenantName,
    required String slot,
    required num? askingRent,
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

  @override
  void dispose() {
    _rent.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      // A tenancy can start a little in the past — somebody who moved in on
      // Saturday and is being written up on Monday — and a long way ahead.
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _start = picked);
  }

  void _accept() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(AcceptRequest(
      rentAmount: num.parse(_rent.text.trim()),
      startDate: DateTime.utc(_start.year, _start.month, _start.day),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
              Text('Accept ${widget.tenantName}',
                  style: LizmoType.screenTitle.copyWith(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                'They will hold ${widget.slot}. Anyone else waiting on it will '
                'be told it has gone.',
                style: LizmoType.rowSub,
              ),
              const SizedBox(height: 20),

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
                  'Advertised at ₱${widget.askingRent!.toStringAsFixed(0)}. '
                  'Change it here if you agreed something else.',
                  style: LizmoType.rowSub,
                ),
              ],

              const SizedBox(height: 18),
              _Label('Tenancy starts'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickStart,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  decoration: BoxDecoration(
                    color: LizmoColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE3E8E6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_outlined,
                          size: 18, color: LizmoColors.slate),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_readable(_start), style: LizmoType.rowName)),
                      const Icon(Icons.arrow_drop_down, color: LizmoColors.slate),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                // Said out loud because the landlord does not choose it here,
                // and a rent day nobody mentioned is one they discover later.
                'Rent will fall due on the ${_ordinal(_start.day)} of each month.',
                style: LizmoType.rowSub,
              ),

              const SizedBox(height: 22),
              PrimaryActionButton(label: 'Accept and create the lease', onPressed: _accept),
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

  static String _readable(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: LizmoType.rowName.copyWith(fontSize: 13));
}
