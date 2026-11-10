import 'dart:async';

import 'package:nfc_manager/nfc_manager.dart';

/// Anlik olarak okunmus kartin ham bilgisi.
class NfcCardData {
  /// Kartin kimligi (seri numarasi); ayni kart hep ayni degeri verir.
  final String id;
  const NfcCardData({required this.id});
}

/// NFC donanimini yonetir. Ag erisimi yoktur; sadece kart okunur.
class NfcService {
  static bool _sessionOn = false;

  /// Cihazda NFC acik mi?
  static Future<bool> supported() async {
    try {
      final r = await NfcManager.instance.isAvailable();
      return r is bool ? r : false;
    } catch (_) {
      return false;
    }
  }

  /// Tek bir karti okur. Kart okunana kadar bekler; sure dolunca null doner.
  static Future<NfcCardData?> read() async {
    if (!await supported()) return null;

    final done = Completer<String?>();
    try {
      _sessionOn = true;
      await NfcManager.instance.startSession(
        onDiscovered: (tag) async {
          final id = _identifier(tag);
          if (!done.isCompleted) done.complete(id);
          try {
            await NfcManager.instance.stopSession();
          } catch (_) {}
          _sessionOn = false;
        },
      );
    } catch (_) {
      _sessionOn = false;
      return null;
    }

    final id = await done.future
        .timeout(const Duration(seconds: 40), onTimeout: () => null);
    _sessionOn = false;
    return id == null ? null : NfcCardData(id: id);
  }

  /// Bekleyen oturumu kapatir (ekrandan cikildiginda).
  static Future<void> stop() async {
    if (!_sessionOn) return;
    _sessionOn = false;
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  /// Kartin seri numarasini onaltilik yaziya cevirir.
  static String _identifier(NfcTag tag) {
    for (final key in const [
      'nfca',
      'nfcb',
      'isodep',
      'mifareultralight',
      'nfcv',
      'nfcf',
    ]) {
      final v = tag.data[key];
      if (v == null) continue;
      final raw = v is Map ? v['identifier'] : null;
      if (raw is! List) continue;
      final bytes = <int>[];
      for (final b in raw) {
        if (b is int) bytes.add(b);
      }
      if (bytes.isEmpty) continue;
      return bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();
    }
    return tag.hashCode.toRadixString(16).toUpperCase().padLeft(8, '0');
  }
}
