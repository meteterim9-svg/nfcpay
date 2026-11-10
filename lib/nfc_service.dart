import 'dart:async';

import 'package:nfc_manager/nfc_manager.dart';

/// A card/tag identifier returned by the NFC reader.
class NfcCardData {
  final String id;
  const NfcCardData({required this.id});
}

/// Owns exactly one NFC session at a time.
class NfcService {
  static bool _sessionOn = false;
  static Completer<String?>? _activeCompleter;

  static Future<bool> supported() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Reads one tag. The NFC session is always closed, including on timeout.
  static Future<NfcCardData?> read({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_sessionOn || !await supported()) return null;

    final completer = Completer<String?>();
    _activeCompleter = completer;
    Timer? timer;
    _sessionOn = true;

    Future<void> closeSession() async {
      if (!_sessionOn) return;
      _sessionOn = false;
      try {
        await NfcManager.instance.stopSession();
      } catch (_) {
        // The platform may already have closed the session.
      }
    }

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (tag) async {
          if (completer.isCompleted) return;
          final id = _identifier(tag);
          // Any discovered NFC tag triggers the local payment flow.
          completer.complete(id.isEmpty ? 'NFC etiketi algılandı' : id);
          await closeSession();
        },
      );

      timer = Timer(timeout, () {
        if (!completer.isCompleted) completer.complete(null);
        closeSession();
      });

      final id = await completer.future;
      return id == null || id.isEmpty ? null : NfcCardData(id: id);
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
      await closeSession();
      return null;
    } finally {
      timer?.cancel();
      if (identical(_activeCompleter, completer)) _activeCompleter = null;
      await closeSession();
    }
  }

  static Future<void> stop() async {
    final pending = _activeCompleter;
    if (pending != null && !pending.isCompleted) pending.complete(null);
    _activeCompleter = null;
    if (!_sessionOn) return;
    _sessionOn = false;
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  static String _identifier(NfcTag tag) {
    for (final key in const [
      'nfca',
      'nfcb',
      'isodep',
      'mifareultralight',
      'nfcv',
      'nfcf',
    ]) {
      final value = tag.data[key];
      if (value is! Map) continue;
      final raw = value['identifier'];
      if (raw is! List) continue;
      final bytes = raw.whereType<int>().toList(growable: false);
      if (bytes.isEmpty) continue;
      return bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();
    }
    return '';
  }
}
