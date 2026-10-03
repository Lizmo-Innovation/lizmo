import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// Ending a tenancy, and settling up in the same breath.
///
/// Nothing in the app could do this before. The endpoint existed and was
/// tested; no screen called it — so a landlord could let a bed and then never
/// free it, and a bed once let could never be let again.
///
/// Ended and terminated are asked as a real question rather than assumed. A
/// tenancy that ran its course and one stopped early are different things to
/// look back on, and the app has no way to tell which happened.
class EndTenancySheet extends StatefulWidget {
  const EndTenancySheet({
    super.key,
    required this.tenantName,
    required this.slot,
    required this.depositAmount,
  });

  final String tenantName;
  final String slot;

  /// What was taken, so the settlement can be checked against it and the
  /// "all of it" shortcut has a figure to fill in.
  final num? depositAmount;

  static Future<EndLeaseRequest?> show(
    BuildContext context, {
    required String tenantName,
    required String slot,
    required num? depositAmount,
  }) {
    return showModalBottomSheet<EndLeaseRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LizmoColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EndTenancySheet(
        tenantName: tenantName,
        slot: slot,
        depositAmount: depositAmount,
      ),
    );
  }

  @override
  State<EndTenancySheet> createState() => _EndTenancySheetState();
}

class _EndTenancySheetState extends State<EndTenancySheet> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _returned = TextEditingController();
  final _settlement = TextEditingController();

  DateTime _end = DateTime.now();
  bool _terminated = false;

  bool get _hasDeposit => widget.depositAmount != null;

  @override
  void dispose() {
    _reason.dispose();
    _returned.dispose();
    _settlement.dispose();
    super.dispose();
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      // A move-out is usually recorded after it happened, sometimes weeks
      // after, and occasionally booked a little ahead.
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _end = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(EndLeaseRequest(
      endDate: DateTime.utc(_end.year, _end.month, _end.day),
      terminated: _terminated,
      reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
      // Null when untouched: a landlord who has not settled yet has not
      // settled, and zero would claim the tenant got nothing back.
      depositReturned: _returned.text.trim().isEmpty
          ? null
          : num.tryParse(_returned.text.trim()),
      depositSettlement:
          _settlement.text.trim().isEmpty ? null : _settlement.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                'End ${widget.tenantName}’s tenancy',
                style: LizmoType.screenTitle
                    .copyWith(fontSize: 20, color: LizmoColors.teal900),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.slot} goes back on the market straight away, and '
                '${widget.tenantName} is told.',
                style: LizmoType.rowSub,
              ),

              const SizedBox(height: 20),
              _Label('Last day'),
              const SizedBox(height: 6),
              InkWell(
                key: const ValueKey('end-date'),
                onTap: _pickEnd,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
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
                      Expanded(
                          child:
                              Text(_readable(_end), style: LizmoType.rowName)),
                      const Icon(Icons.arrow_drop_down,
                          color: LizmoColors.slate),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              _Label('How did it end?'),
              const SizedBox(height: 6),
              // Asked, not assumed. Flattening the two would lose the only
              // record of which happened.
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Ran its course'),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Stopped early'),
                  ),
                ],
                selected: {_terminated},
                onSelectionChanged: (choice) =>
                    setState(() => _terminated = choice.first),
              ),

              const SizedBox(height: 14),
              _Label('Note for your records'),
              const SizedBox(height: 6),
              TextFormField(
                key: const ValueKey('end-reason'),
                controller: _reason,
                maxLength: 500,
                decoration: _field('Moved back to the province').copyWith(
                  counterText: '',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                // Said plainly because it is currently write-only: nothing
                // lists past tenancies yet, so this is kept for the screen
                // that will. Not saying so would leave somebody hunting for a
                // note they typed.
                '${widget.tenantName} does not see this. Kept for when past '
                'tenancies get a screen of their own.',
                style: LizmoType.rowSub.copyWith(fontSize: 11),
              ),

              if (_hasDeposit) ...[
                const SizedBox(height: 14),
                Text('Settling the deposit', style: LizmoType.sectionHeading),
                const SizedBox(height: 4),
                Text(
                  'You took ${LizmoMoney.peso(widget.depositAmount!)}. '
                  'Leave this blank if you have not settled it yet.',
                  style: LizmoType.rowSub,
                ),

                const SizedBox(height: 12),
                _Label('Returned'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const ValueKey('deposit-returned'),
                  controller: _returned,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: _field('4500').copyWith(prefixText: '₱ '),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    final amount = num.tryParse(text);
                    if (amount == null) return 'Enter an amount';
                    if (amount < 0) return 'That cannot be less than nothing';
                    // Checked here as well as on the server, so a typo is
                    // caught before it costs a round trip.
                    if (amount > widget.depositAmount!) {
                      return 'That is more than the '
                          '${LizmoMoney.peso(widget.depositAmount)} you took';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    key: const ValueKey('return-all'),
                    onPressed: () => setState(() => _returned.text =
                        widget.depositAmount!.toStringAsFixed(0)),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: Color(0xFFE3E8E6)),
                    ),
                    child: Text('All of it',
                        style: LizmoType.rowSub
                            .copyWith(color: LizmoColors.teal900)),
                  ),
                ),

                const SizedBox(height: 14),
                _Label('What you withheld, and why'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const ValueKey('deposit-settlement'),
                  controller: _settlement,
                  maxLines: 3,
                  maxLength: 2000,
                  decoration: _field(
                    'Withheld ₱500 for the broken window latch.',
                  ).copyWith(counterText: ''),
                ),
                const SizedBox(height: 4),
                Text(
                  // The tenant reads this months later, and it is the whole of
                  // what stops a disagreement being one word against nobody's.
                  '${widget.tenantName} will see this, and keep it after '
                  'moving out.',
                  style: LizmoType.rowSub.copyWith(fontSize: 11),
                ),
              ],

              const SizedBox(height: 22),
              PrimaryActionButton(
                  label: 'End the tenancy', onPressed: _submit),
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
}

InputDecoration _field(String hint) {
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
  Widget build(BuildContext context) => Text(
        text,
        style: LizmoType.rowName.copyWith(fontSize: 13),
      );
}
