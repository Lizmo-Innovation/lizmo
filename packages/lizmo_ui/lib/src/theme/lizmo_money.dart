/// Money, written the way it is read.
///
/// Rents here run from a few hundred to tens of thousands of pesos, and
/// ₱7500 against ₱75000 is a difference somebody has to count digits to see.
/// Grouping is not decoration: it is the only thing separating a bedspace from
/// a whole floor at a glance.
abstract final class LizmoMoney {
  /// `₱7,500`, or `₱7,500.50` when there are centavos.
  ///
  /// Whole pesos lose the `.00`, because a rent is agreed in whole pesos and
  /// the decimals are noise on every screen that shows one. A utility reading
  /// keeps them, because that is a meter's figure and rounding it is a
  /// different number from the one being charged.
  static String peso(num? amount) => amount == null ? '—' : '₱${plain(amount)}';

  /// The same figure without the sign, for a field a currency already labels.
  static String plain(num amount) {
    final negative = amount < 0;
    final value = amount.abs();

    final whole = value.truncate();
    final centavos = value - whole;

    final digits = whole.toString();
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
      grouped.write(digits[i]);
    }

    // Rounded to centavos first: 0.005 of a peso is not money, and a repeating
    // double would otherwise print its own arithmetic.
    final rounded = (centavos * 100).round();
    final tail = rounded == 0
        ? ''
        : '.${rounded.toString().padLeft(2, '0')}';

    return '${negative ? '-' : ''}$grouped$tail';
  }
}
