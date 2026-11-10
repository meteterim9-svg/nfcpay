import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart' as pc;

/// PIN'i sifreli depoda tutar, yanlis denemeleri sayar.
class Vault {
  static const _storage = FlutterSecureStorage();
  static const _kHash = 'pin_hash';
  static const _kSalt = 'pin_salt';
  static const _kFails = 'pin_fails';
  static const _kLockUntil = 'pin_lock_until';
  static const _kSecure = 'secure_screen';

  static String _hash(String salt, String pin) {
    final kd = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
      ..init(pc.Pbkdf2Parameters(
        Uint8List.fromList(utf8.encode(salt)),
        20000,
        32,
      ));
    return base64Url.encode(kd.process(Uint8List.fromList(utf8.encode(pin))));
  }

  /// Zamanlama saldirisina karsi sabit zamanli karsilastirma.
  static bool _eq(String a, String b) {
    if (a.length != b.length) return false;
    var r = 0;
    for (var i = 0; i < a.length; i++) {
      r |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return r == 0;
  }

  static Future<bool> hasPin() async =>
      (await _storage.read(key: _kHash)) != null;

  static Future<void> setPin(String pin) async {
    final rnd = Random.secure();
    final salt =
        base64Url.encode(List<int>.generate(16, (_) => rnd.nextInt(256)));
    await _storage.write(key: _kSalt, value: salt);
    await _storage.write(key: _kHash, value: _hash(salt, pin));
    await _resetFails();
  }

  /// Kilit suresi bittiyse 0, bitmediyse kalan saniye.
  static Future<int> lockRemaining() async {
    final until =
        int.tryParse(await _storage.read(key: _kLockUntil) ?? '') ?? 0;
    final ms = until - DateTime.now().millisecondsSinceEpoch;
    return ms > 0 ? (ms / 1000).ceil() : 0;
  }

  static Future<void> _registerFail() async {
    final fails =
        (int.tryParse(await _storage.read(key: _kFails) ?? '') ?? 0) + 1;
    await _storage.write(key: _kFails, value: '$fails');
    if (fails >= 5) {
      final sec = min(3600, 30 * pow(2, fails - 5).toInt());
      final until = DateTime.now().millisecondsSinceEpoch + sec * 1000;
      await _storage.write(key: _kLockUntil, value: '$until');
    }
  }

  static Future<void> _resetFails() async {
    await _storage.delete(key: _kFails);
    await _storage.delete(key: _kLockUntil);
  }

  static Future<bool> verifyPin(String pin) async {
    if (await lockRemaining() > 0) return false;
    final salt = await _storage.read(key: _kSalt);
    final stored = await _storage.read(key: _kHash);
    if (salt == null || stored == null) return false;
    final ok = _eq(_hash(salt, pin), stored);
    if (ok) {
      await _resetFails();
    } else {
      await _registerFail();
    }
    return ok;
  }

  static Future<bool> getSecure() async =>
      (await _storage.read(key: _kSecure)) != '0';
  static Future<void> setSecure(bool on) =>
      _storage.write(key: _kSecure, value: on ? '1' : '0');
}
