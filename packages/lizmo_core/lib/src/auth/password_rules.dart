/// What Lizmo will accept as a password, said in the app's own voice.
///
/// A copy of the server's `PasswordPolicy`, and deliberately so. The server is
/// the one that decides — this is here to say the same thing without a round
/// trip, so the rules can be shown as they are met rather than as a refusal
/// after the fact. Both are written as a list of rules rather than as one
/// pattern, for the same reason: a password that breaks three rules should be
/// told all three.
class PasswordRules {
  const PasswordRules._();

  static const int minLength = 8;

  /// Letters and digits in any script, matching what the server counts.
  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);
  static final RegExp _digit = RegExp(r'\p{Nd}', unicode: true);
  static final RegExp _upper = RegExp(r'\p{Lu}', unicode: true);
  static final RegExp _lower = RegExp(r'\p{Ll}', unicode: true);

  /// Every rule, in the order they are shown under the field.
  static final List<PasswordRule> all = [
    PasswordRule('At least $minLength characters', (v) => v.length >= minLength),
    PasswordRule('A capital letter', _upper.hasMatch),
    PasswordRule('A small letter', _lower.hasMatch),
    PasswordRule('A number', _digit.hasMatch),
    PasswordRule('A symbol like ! or @', _hasSymbol),
  ];

  /// Empty when the password would be accepted.
  static List<PasswordRule> whatIsMissing(String password) =>
      all.where((rule) => !rule.isMetBy(password)).toList(growable: false);

  static bool isAcceptable(String password) =>
      all.every((rule) => rule.isMetBy(password));

  /// Anything that is not a letter, a digit or whitespace — matching the
  /// server, which takes a peso sign as happily as an exclamation mark rather
  /// than holding a list of approved punctuation.
  static bool _hasSymbol(String value) => value.runes.any((rune) {
        final char = String.fromCharCode(rune);
        if (char.trim().isEmpty) return false;
        return !_letter.hasMatch(char) && !_digit.hasMatch(char);
      });
}

/// One rule, and whether a password keeps it.
class PasswordRule {
  const PasswordRule(this.label, this._test);

  final String label;
  final bool Function(String) _test;

  bool isMetBy(String password) => _test(password);
}
