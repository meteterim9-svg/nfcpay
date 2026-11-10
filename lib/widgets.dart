import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pin girme ekranindaki tek tus.
class KeypadKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  const KeypadKey({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              height: 72,
              child: Center(
                child: icon != null
                    ? Icon(icon, size: 26)
                    : Text(
                        label,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Girilen haneleri gosteren renkli noktalar.
class PinDots extends StatelessWidget {
  final int filled;
  final int total;
  final bool error;
  const PinDots({
    super.key,
    required this.filled,
    this.total = 4,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: i < filled ? 20 : 16,
            height: i < filled ? 20 : 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: i < filled
                  ? LinearGradient(
                      colors: error
                          ? const [Color(0xFFFF5C7A), Color(0xFFFF5C7A)]
                          : const [
                              Color(0xFF2E6BFF),
                              Color(0xFFFF3D9A),
                              Color(0xFF16C98D),
                            ],
                    )
                  : null,
              color: i < filled ? null : Colors.white.withValues(alpha: 0.18),
            ),
          ),
      ],
    );
  }
}

/// Cihaz acikken ekran goruntusunu engeller (Android'de FLAG_SECURE).
class ScreenSecurity {
  static const _channel = MethodChannel('nfcpay/secure');

  static Future<void> set(bool on) async {
    try {
      await _channel.invokeMethod('setSecure', {'on': on});
    } catch (_) {
      // Masaustu/test ortaminda kanal yok; sessizce gec.
    }
  }
}
