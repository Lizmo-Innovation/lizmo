import 'package:lizmo_api/api.dart';

/// Rent for a month, or the security deposit.
///
/// Both are owed, paid and confirmed the same way, so the same rows, sheets
/// and buttons carry them. They differ in what they are called, and in that
/// a deposit is held rather than earned -- so the screens that add up rent
/// leave it out, and the ones that list what is owed put it first.
extension PeriodKind on BillingPeriodResponse {
  bool get isDeposit => kind == BillingPeriodResponseKindEnum.DEPOSIT;

  /// Paid ahead at move-in, from a lease charged that way.
  bool get isAdvance => !isDeposit && (label ?? '').endsWith(' · advance');

  /// "Rent for October 2026", or "Your security deposit": what a sentence
  /// says the money is for.
  String get whatFor => isDeposit ? 'Your security deposit' : 'Rent for $label';

  /// "October 2026", or "The security deposit", at the start of a sentence.
  String get named => isDeposit ? 'The security deposit' : (label ?? 'This month');
}
