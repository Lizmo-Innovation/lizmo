import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo_core/lizmo_core.dart';

/// The mirror of the server's password rule.
///
/// It exists so the rules can be shown while somebody types rather than after
/// a refusal, which means the two have to agree. Every case here is one the
/// server's own tests also cover; if these ever disagree, the app promises an
/// account the server then refuses.
void main() {
  String? missingLabel(String password, String label) => PasswordRules
      .whatIsMissing(password)
      .map((rule) => rule.label)
      .where((it) => it == label)
      .firstOrNull;

  group('what a password is missing', () {
    test('a good one is missing nothing', () {
      expect(PasswordRules.whatIsMissing('Sunrise2Bed!'), isEmpty);
      expect(PasswordRules.isAcceptable('Sunrise2Bed!'), isTrue);
    });

    test('each rule is reported on its own', () {
      expect(missingLabel('Ab1!def', 'At least 8 characters'), isNotNull);
      expect(missingLabel('sunrise2bed!', 'A capital letter'), isNotNull);
      expect(missingLabel('SUNRISE2BED!', 'A small letter'), isNotNull);
      expect(missingLabel('SunriseBed!', 'A number'), isNotNull);
      expect(missingLabel('Sunrise2Bed', 'A symbol like ! or @'), isNotNull);
    });

    test('everything missing is reported at once', () {
      // Told one problem at a time, somebody fixing one problem at a time
      // tries four times.
      expect(PasswordRules.whatIsMissing('abc'), hasLength(4));
    });

    test('an unusual symbol still counts', () {
      // A password with a peso sign is a good password. The server takes it,
      // so refusing it here would be the app inventing a stricter rule.
      expect(PasswordRules.isAcceptable('Sunrise2Bed₱'), isTrue);
    });

    test('a space is not a symbol', () {
      expect(missingLabel('Sunrise2 Bed', 'A symbol like ! or @'), isNotNull);
    });

    test('a space still counts towards the length', () {
      // Length is length. A passphrase with spaces is not being punished for
      // them.
      expect(missingLabel('Ab1! cd', 'At least 8 characters'), isNotNull);
      expect(missingLabel('Ab1! cde', 'At least 8 characters'), isNull);
    });

    test('an empty password is missing everything', () {
      expect(PasswordRules.whatIsMissing(''), hasLength(PasswordRules.all.length));
    });
  });
}
