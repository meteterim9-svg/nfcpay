import 'package:flutter/material.dart';

import 'cardinfo.dart';
import 'nfc_service.dart';
import 'theme.dart';

enum _ReaderState { idle, checking, scanning, processing, awaitingBankApproval, detected, success, unavailable, failed }

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _raw = '';
  double? _amount;
  _ReaderState _state = _ReaderState.idle;
  String? _tagId;
  bool _busy = false;

  @override
  void dispose() {
    NfcService.stop();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_busy) return;
    if (_amount == null || _amount! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Önce geçerli bir tutar girin.')));
      return;
    }
    setState(() {
      _busy = true;
      _state = _ReaderState.checking;
      _tagId = null;
    });

    final available = await NfcService.supported();
    if (!mounted) return;
    if (!available) {
      setState(() {
        _busy = false;
        _state = _ReaderState.unavailable;
      });
      return;
    }

    setState(() => _state = _ReaderState.scanning);
    final result = await NfcService.read();
    if (!mounted) return;

    setState(() {
      _busy = false;
      if (result == null) {
        _state = _ReaderState.failed;
      } else {
        _tagId = result.id;
        _state = _ReaderState.processing;
      }
    });
    if (result != null) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() => _state = _ReaderState.awaitingBankApproval);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() => _state = _ReaderState.success);
    }
  }

  void _cancelScan() {
    NfcService.stop();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _state = _ReaderState.idle;
      _tagId = null;
    });
  }

  void _press(String key) {
    if (key == 'del') {
      if (_raw.isNotEmpty) _raw = _raw.substring(0, _raw.length - 1);
    } else {
      _raw = AmountInputFormatter.normalize(_raw + key);
    }
    _amount = AmountInputFormatter.parse(_raw);
  }

  void _reset() {
    NfcService.stop();
    setState(() {
      _raw = '';
      _amount = null;
      _tagId = null;
      _state = _ReaderState.idle;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _content(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: const BoxDecoration(
        gradient: kGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.nfc_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NFC Pay',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 3),
                Text('Temassız kart okuyucu',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sıfırla',
            onPressed: _busy ? null : _reset,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    if (_state == _ReaderState.checking ||
        _state == _ReaderState.scanning) {
      return _scanning();
    }
    if (_state == _ReaderState.processing) return _processing();
    if (_state == _ReaderState.awaitingBankApproval) return _bankApproval();
    if (_state == _ReaderState.detected || _state == _ReaderState.success) return _success();
    if (_state == _ReaderState.unavailable) {
      return _message(
        icon: Icons.nfc_rounded,
        title: 'NFC kullanılamıyor',
        detail:
            'Bu cihazda NFC bulunmuyor veya NFC kapalı. Ayarlardan NFC’yi açıp tekrar deneyin.',
        action: 'Tekrar dene',
        onAction: _startScan,
      );
    }
    if (_state == _ReaderState.failed) {
      return _message(
        icon: Icons.error_outline_rounded,
        title: 'Kart okunamadı',
        detail:
            'Okuma süresi doldu veya kart algılanamadı. Telefonun NFC alanını kartın üzerine yaklaştırıp yeniden deneyin.',
        action: 'Yeniden tara',
        onAction: _startScan,
      );
    }
    return _home();
  }

  Widget _home() {
    return SingleChildScrollView(
      key: const ValueKey('home'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Yeni işlem',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Tutarı girin ve NFC kartını okutun.',
              style: TextStyle(color: kMuted, fontSize: 14)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(.06)),
            ),
            child: Column(
              children: [
                const Text('İşlem tutarı',
                    style: TextStyle(color: kMuted, fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  _amount == null ? '0,00 ₺' : '${formatAmount(_amount!)} ₺',
                  style: const TextStyle(
                      fontSize: 38, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            [',', '0', 'del'],
          ])
            Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Material(
                        color: kCard,
                        borderRadius: BorderRadius.circular(15),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () => setState(() => _press(key)),
                          child: SizedBox(
                            height: 54,
                            child: Center(
                              child: key == 'del'
                                  ? const Icon(Icons.backspace_outlined)
                                  : Text(key,
                                      style: const TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _amount == null ? null : _startScan,
            icon: const Icon(Icons.contactless_rounded),
            label: const Text('NFC kartını okut'),
          ),
          const SizedBox(height: 16),
          _infoPanel(),
        ],
      ),
    );
  }

  Widget _infoPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBlue.withOpacity(.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBlue.withOpacity(.22)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: kBlue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tutarı girin, herhangi bir NFC etiketi okutun ve test işlem akışını izleyin. Gerçek tahsilat yapılmaz.',
              style: TextStyle(color: kMuted, fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanning() {
    final checking = _state == _ReaderState.checking;
    return Center(
      key: const ValueKey('scanning'),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: kBlue.withOpacity(.13),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.contactless_rounded,
                  size: 58, color: kBlue),
            ),
            const SizedBox(height: 28),
            Text(
              checking ? 'NFC kontrol ediliyor' : 'Kartınızı yaklaştırın',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              checking
                  ? 'Cihazın NFC bağlantısı kontrol ediliyor.'
                  : 'Telefonun arka yüzünü NFC kartına yaklaştırın. Okuma 30 saniye içinde tamamlanır.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted, height: 1.5),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
            const SizedBox(height: 26),
            OutlinedButton.icon(
              onPressed: _cancelScan,
              icon: const Icon(Icons.close_rounded),
              label: const Text('İptal et'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _processing() {
    return Center(key: const ValueKey('processing'), child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const GradientSpinner(size: 82),
      const SizedBox(height: 28),
      const Text('Ödeme işleniyor', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Text('${formatAmount(_amount ?? 0)} ₺', style: const TextStyle(color: kGreen, fontSize: 28, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      const Text('NFC bağlantısı tamamlandı. İşlem hazırlanıyor...', textAlign: TextAlign.center, style: TextStyle(color: kMuted, height: 1.5)),
    ])));
  }

  Widget _bankApproval() {
    return Center(
      key: const ValueKey('bankApproval'),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: kBlue.withOpacity(.13),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_rounded, color: kBlue, size: 54),
            ),
            const SizedBox(height: 26),
            const Text(
              'Banka onayı bekleniyor…',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '${formatAmount(_amount ?? 0)} ₺',
              style: const TextStyle(color: kGreen, fontSize: 29, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            const CircularProgressIndicator(),
            const SizedBox(height: 22),
            const Text(
              'Test akışı: gerçek banka bağlantısı kurulmaz ve hesabınızdan para çekilmez.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, height: 1.5, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _success() {
    return Center(key: const ValueKey('success'), child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 112, height: 112, decoration: const BoxDecoration(color: Color(0xFF123B32), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: kGreen, size: 66)),
      const SizedBox(height: 24),
      const Text('Ödeme başarıyla tamamlandı', textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      const Text('Test işlemi tamamlandı · Gerçek tahsilat yapılmadı.', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
      const SizedBox(height: 26),
      Container(width: double.infinity, padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20)), child: Column(children: [
        const Text('İŞLEM TUTARI', style: TextStyle(color: kMuted, fontSize: 11, letterSpacing: 1.3, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('${formatAmount(_amount ?? 0)} ₺', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        const Divider(color: Colors.white12),
        const SizedBox(height: 8),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.verified_rounded, color: kGreen, size: 18), SizedBox(width: 8), Text('İşlem onaylandı', style: TextStyle(color: kGreen))]),
      ])),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _reset, icon: const Icon(Icons.add_rounded), label: const Text('Yeni işlem'))),
    ])));
  }
  Widget _message({
    required IconData icon,
    required String title,
    required String detail,
    required String action,
    required VoidCallback onAction,
  }) {
    return Center(
      key: ValueKey(title),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kPink, size: 64),
            const SizedBox(height: 22),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(detail,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kMuted, height: 1.5)),
            const SizedBox(height: 26),
            FilledButton(
                onPressed: onAction, child: Text(action)),
            TextButton(onPressed: _reset, child: const Text('Ana ekrana dön')),
          ],
        ),
      ),
    );
  }
}
