/// Turkish lira amount formatting and keypad input helpers.

String formatAmount(double value) {
  final parts = value.toStringAsFixed(2).split('.');
  final digits = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '$buffer,${parts[1]}';
}

class AmountInputFormatter {
  /// Keeps digits and one decimal separator, with up to two decimal places.
  static String normalize(String raw) {
    var value = raw.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
    final firstDot = value.indexOf('.');
    if (firstDot >= 0) {
      value = value.substring(0, firstDot + 1) +
          value.substring(firstDot + 1).replaceAll('.', '');
      if (value.length - firstDot - 1 > 2) {
        value = value.substring(0, firstDot + 3);
      }
    } else if (value.length > 9) {
      value = value.substring(0, 9);
    }
    return value;
  }

  static double? parse(String raw) {
    final value = double.tryParse(normalize(raw).replaceAll(',', '.'));
    if (value == null || value <= 0) return null;
    return value;
  }
}
