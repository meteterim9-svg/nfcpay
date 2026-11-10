import 'dart:convert';
import 'dart:math';

/// Kart bilgisi ve tutar bicimlendirme yardimcilari.
class CardInfo {
  final String number;
  final String name;
  final String bank;
  final String expiry;

  const CardInfo({
    required this.number,
    required this.name,
    required this.bank,
    required this.expiry,
  });

  static const _names = [
    'AHMET YILMAZ',
    'ELIF DEMIR',
    'MEHMET KAYA',
    'ZEYNEP ARSLAN',
    'MURAT CELIK',
    'SELIN DOGAN',
    'BURAK SAHIN',
    'AYSE KOC',
  ];

  static const _banks = [
    'ZIRAAT BANKASI',
    'IS BANKASI',
    'GARANTI BBVA',
    'YAPI KREDI',
    'AKBANK',
    'QNB FINANSBANK',
  ];

  /// Kart numarasindan gosterilecek bilgileri turetir.
  /// Bu bilgiler kurgudur; gercek bir karta karsilik gelmez.
  factory CardInfo.fromNumber(String number) {
    final seed = stableSeed(number);
    final rnd = Random(seed);
    return CardInfo(
      number: number,
      name: _names[rnd.nextInt(_names.length)],
      bank: _banks[rnd.nextInt(_banks.length)],
      expiry: _expiry(rnd),
    );
  }

  /// Son 4 hane: **** 3456
  String get maskedTail => number.length < 4
      ? number
      : '**** ${number.substring(number.length - 4)}';

  String _expiry(Random rnd) {
    final month = rnd.nextInt(12) + 1;
    final year = DateTime.now().year + 1 + rnd.nextInt(4);
    return '${month.toString().padLeft(2, '0')}/${year % 100}';
  }
}

/// Metinden her zaman ayni sayiyi ureten basit karma (FNV-1a).
int stableSeed(String s) {
  var h = 2166136261;
  for (final c in utf8.encode(s)) {
    h ^= c;
    h = (h * 16777619) & 0x7fffffff;
  }
  return h == 0 ? 1 : h;
}

/// 1234.5 -> "1.234,50"
String formatAmount(double v) {
  final s = v.toStringAsFixed(2);
  final parts = s.split('.');
  final digits = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return '$buf,${parts[1]}';
}

/// Tutar alaninin girisi icin kurallar.
class AmountInputFormatter {
  /// Sadece sayi ve tek bir ayrac birakir, en fazla 2 ondalik basamak.
  static String normalize(String raw) {
    var s = raw.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
    final firstDot = s.indexOf('.');
    if (firstDot >= 0) {
      s = s.substring(0, firstDot + 1) +
          s.substring(firstDot + 1).replaceAll('.', '');
      if (s.length - firstDot - 1 > 2) {
        s = s.substring(0, firstDot + 3);
      }
    } else if (s.length > 9) {
      s = s.substring(0, 9);
    }
    return s;
  }

  static double? parse(String raw) {
    final v = double.tryParse(normalize(raw).replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }
}
