import 'dart:async';
import 'dart:math';

import 'package:nfc_manager/nfc_manager.dart';

/// Anlik olarak okunmus kartin ham bilgisi.
class NfcCardData {
  /// Kartin kimligi (seri numarasi); ayni kart hep ayni degeri verir.
  final String id;
  const NfcCardData({required this.id});
}

/// NFC donanimini yonetir.
class NfcService {
  /// Cihazda NFC acik mi?
  static Future<bool> supported() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Kullaniciya api numarasindan okunacak kart bilgisini sorar.
  static Future<String> askCardNumber() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: navigatorKey.currentContext!,
      builder: (ctx) => AlertDialog(
        title: const Text('Kart numarasi gerekli'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 16,
          decoration: const InputDecoration(counterText: ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
    final v = ctrl.text.trim();
    return ok == true && v.length >= 4 ? v : _randomCardNumber();
  }

  /// Tek bir karti okur. Kart okunana kadar bekler; sure dolunca null doner.
  static Future<NfcCardData?> read() async {
    if (!await supported()) return null;
    NfcTag? tag;
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (t) async {
          tag = t;
          await NfcManager.instance.stopSession();
        },
      );
    } catch (_) {
      return null;
    }

    final deadline = DateTime.now().add(const Duration(seconds: 40));
    while (DateTime.now().isBefore(deadline)) {
      if (tag != null) {
        return NfcCardData(id: _identifier(tag!));
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
    return null;
  }

  static String _identifier(NfcTag tag) {
    for (final key in ['nfca', 'nfcb', 'isodep', 'mifareultralight', 'nfcv']) {
      final v = tag.data[key];
      if (v is Map && v['identifier'] is List) {
        final bytes = (v['identifier'] as List).cast<int>();
        if (bytes.isNotEmpty) {
          return bytes
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join()
              .toUpperCase();
        }
      }
    }
    return tag.hashCode.toRadixString(16).toUpperCase().padLeft(8, '0');
  }

  static String _randomCardNumber() {
    final rnd = Random();
    return List.generate(16, (_) => rnd.nextInt(10)).join();
  }
}
