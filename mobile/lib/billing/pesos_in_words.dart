/// An amount written out, the way a receipt says it under the figure:
/// "Two thousand five hundred pesos".
///
/// Written out because that is what makes a receipt hard to alter -- a
/// figure gains a zero more easily than a sentence gains a word -- and it
/// is what people here expect to see on one.
String pesosInWords(num amount) {
  final cents = (amount * 100).round();
  final pesos = cents ~/ 100;
  final centavos = cents % 100;

  final words = pesos == 0 ? 'Zero' : _capitalised(_spell(pesos));
  final unit = pesos == 1 ? 'peso' : 'pesos';
  if (centavos == 0) return '$words $unit';
  return '$words $unit and ${_spell(centavos)} '
      '${centavos == 1 ? 'centavo' : 'centavos'}';
}

const _ones = [
  '', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
  'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen',
  'seventeen', 'eighteen', 'nineteen',
];

const _tens = [
  '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty',
  'ninety',
];

const _scales = [(1000000000, 'billion'), (1000000, 'million'), (1000, 'thousand')];

String _spell(int number) {
  final parts = <String>[];
  var rest = number;
  for (final (size, name) in _scales) {
    if (rest >= size) {
      parts.add('${_belowThousand(rest ~/ size)} $name');
      rest %= size;
    }
  }
  if (rest > 0) parts.add(_belowThousand(rest));
  return parts.join(' ');
}

String _belowThousand(int number) {
  final parts = <String>[];
  if (number >= 100) {
    parts.add('${_ones[number ~/ 100]} hundred');
    number %= 100;
  }
  if (number >= 20) {
    final ten = _tens[number ~/ 10];
    final one = _ones[number % 10];
    parts.add(one.isEmpty ? ten : '$ten-$one');
  } else if (number > 0) {
    parts.add(_ones[number]);
  }
  return parts.join(' ');
}

String _capitalised(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
