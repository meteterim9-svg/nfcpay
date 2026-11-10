import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'payment.dart';
import 'theme.dart';
import 'vault.dart';
import 'widgets.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Acilista PIN durumuna gore dogru ekrani gosterir ve
/// arka plandan donuste uygulamayi tekrar kilitler.
class Gate extends StatefulWidget {
  const Gate({super.key});

  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> with WidgetsBindingObserver {
  bool? _hasPin;
  bool _unlocked = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  Future<void> _boot() async {
    await ScreenSecurity.set(await Vault.getSecure());
    final v = await Vault.hasPin();
    if (mounted) setState(() => _hasPin = v);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _checkLock();
    }
  }

  Future<void> _checkLock() async {
    final p = _pausedAt;
    _pausedAt = null;
    if (p == null || !_unlocked) return;
    if (DateTime.now().difference(p).inSeconds >= 30) {
      navigatorKey.currentState?.popUntil((r) => r.isFirst);
      if (mounted) setState(() => _unlocked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPin == null) {
      return const Scaffold(body: Center(child: GradientSpinner()));
    }
    if (_unlocked) return const PaymentScreen();
    return PinScreen(
      key: ValueKey('pin-${_hasPin!}'),
      setup: !_hasPin!,
      onDone: () => setState(() {
        _hasPin = true;
        _unlocked = true;
      }),
    );
  }
}

class PinScreen extends StatefulWidget {
  final bool setup;
  final VoidCallback onDone;
  const PinScreen({super.key, required this.setup, required this.onDone});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String? _first;
  String? _error;
  bool _busy = false;
  bool _errorFlash = false;

  String get _title {
    if (widget.setup) {
      return _first == null ? 'PIN oluştur' : 'PIN\'i tekrar gir';
    }
    return 'Kilidi aç';
  }

  Future<void> _press(String key) async {
    if (_busy) return;
    if (key == 'del') {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
      return;
    }
    if (_pin.length >= 4) return;
    setState(() => _pin += key);
    if (_pin.length == 4) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    if (widget.setup) {
      if (_first == null) {
        setState(() {
          _first = _pin;
          _pin = '';
          _error = null;
          _busy = false;
        });
        return;
      }
      if (_first != _pin) {
        setState(() {
          _first = null;
          _pin = '';
          _error = 'PIN\'ler uyuşmadı, baştan dene';
          _busy = false;
        });
        _flash();
        return;
      }
      await Vault.setPin(_pin);
      widget.onDone();
      return;
    }

    final ok = await Vault.verifyPin(_pin);
    if (!mounted) return;
    if (ok) {
      widget.onDone();
      return;
    }
    final wait = await Vault.lockRemaining();
    setState(() {
      _pin = '';
      _busy = false;
      _error = wait <= 0
          ? 'Yanlış PIN'
          : (wait < 60
              ? 'Çok fazla deneme. $wait sn bekle.'
              : 'Çok fazla deneme. ${(wait / 60).ceil()} dk bekle.');
    });
    _flash();
  }

  void _flash() {
    setState(() => _errorFlash = true);
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _errorFlash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const GradientHeader(
              title: 'NFC Pay',
              subtitle: 'İnternetsiz ödeme',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(),
                    const GlowIcon(Icons.lock_outline, size: 30),
                    const SizedBox(height: 22),
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 22),
                    PinDots(filled: _pin.length, error: _errorFlash),
                    SizedBox(
                      height: 40,
                      child: _error == null
                          ? null
                          : Center(
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: kPink),
                              ),
                            ),
                    ),
                    for (final row in const [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                    ])
                      Row(
                        children: [
                          for (final k in row)
                            KeypadKey(label: k, onTap: () => _press(k)),
                        ],
                      ),
                    Row(
                      children: [
                        const Spacer(),
                        KeypadKey(
                          label: '',
                          icon: Icons.backspace_outlined,
                          onTap: () => _press('del'),
                        ),
                        KeypadKey(label: '0', onTap: () => _press('0')),
                        const Spacer(),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
