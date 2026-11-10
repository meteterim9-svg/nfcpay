import 'package:flutter/material.dart';

import 'cardinfo.dart';
import 'nfc_service.dart';
import 'theme.dart';

/// Odeme akisinin adimlari.
enum PayStep { amount, confirm, checkNfc, waiting, processing, success }

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _raw = '';
  PayStep _step = PayStep.amount;
  double _amount = 0;
  CardInfo? _card;
  String? _nfcMessage;
  int _receiptSeed = 0;

  @override
  void dispose() {
    NfcService.stop();
    super.dispose();
  }

  Future<void> _confirmAmount() async {
    final v = AmountInputFormatter.parse(_raw);
    if (v == null) {
      _say('Geçerli bir tutar gir');
      return;
    }
    if (v > 100000) {
      _say('Tek seferde en fazla 100.000,00 ödeyebilirsin');
      return;
    }
    setState(() {
      _amount = v;
      _step = PayStep.confirm;
    });
  }

  /// 1) Cihazda NFC var mi, acik mi?
  Future<void> _pay() async {
    setState(() {
      _step = PayStep.checkNfc;
      _nfcMessage = 'Telefonda NFC kontrol ediliyor…';
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final ok = await NfcService.supported();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _step = PayStep.confirm;
        _nfcMessage = 'NFC kapalı ya da cihazda yok. Açıp tekrar dene.';
      });
      return;
    }
    await _waitCard();
  }

  /// 2) "Karti okut" ekrani.
  Future<void> _waitCard() async {
    setState(() => _step = PayStep.waiting);
    final res = await NfcService.read();
    if (!mounted) return;

    if (res == null) {
      setState(() {
        _step = PayStep.confirm;
        _nfcMessage = 'Kart okunamadı. Tekrar dene.';
      });
      _say('Kart okunamadı. Tekrar dene.');
      return;
    }
    await _finish(res.id);
  }

  /// 3) Islem animasyonu (4-5 sn) ve basarili ekrani.
  Future<void> _finish(String nfcId) async {
    setState(() => _step = PayStep.processing);
    await Future<void>.delayed(const Duration(milliseconds: 4500));
    if (!mounted) return;

    var digits = nfcId.replaceAll(RegExp(r'[^0-9]'), '');
    var seed = 0;
    for (final c in nfcId.codeUnits) {
      seed = (seed * 31 + c) & 0x7fffffff;
    }
    if (digits.length < 16) {
      var x = seed == 0 ? 1 : seed;
      while (digits.length < 16) {
        x = (x * 1103515245 + 12345) & 0x7fffffff;
        digits += (x % 10).toString();
      }
    }
    setState(() {
      _card = CardInfo.fromNumber(digits.substring(0, 16));
      _receiptSeed = seed;
      _step = PayStep.success;
    });
  }

  void _reset() {
    NfcService.stop();
    setState(() {
      _raw = '';
      _step = PayStep.amount;
      _amount = 0;
      _card = null;
      _nfcMessage = null;
      _receiptSeed = 0;
    });
  }

  void _say(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String get _receiptNo {
    final n = (_receiptSeed % 900000) + 100000;
    return 'NF$n';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GradientHeader(
              title: 'NFC Ödeme',
              subtitle: _step == PayStep.amount
                  ? 'İnternetsiz çalışır'
                  : 'İşlem ekranı',
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case PayStep.amount:
        return _amountBody();
      case PayStep.confirm:
        return _confirmBody();
      case PayStep.checkNfc:
        return _statusBody(Icons.nfc, 'NFC kontrol ediliyor', _nfcMessage);
      case PayStep.waiting:
        return _waitingBody();
      case PayStep.processing:
        return _processingBody();
      case PayStep.success:
        return _successBody();
    }
  }

  Widget _pad(String label, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: SizedBox(
              height: 62,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _press(String key) {
    if (key == 'del') {
      if (_raw.isNotEmpty) {
        _raw = _raw.substring(0, _raw.length - 1);
      }
      return;
    }
    _raw = AmountInputFormatter.normalize(_raw + key);
  }

  Widget _amountBody() {
    final amount = AmountInputFormatter.parse(_raw);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 6),
          const Text('Ödenecek tutar', style: TextStyle(color: kMuted)),
          const SizedBox(height: 6),
          Text(
            amount == null ? '0,00 ₺' : '${formatAmount(amount)} ₺',
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(
              children: [
                for (final k in row)
                  _pad(k, () => setState(() => _press(k))),
              ],
            ),
          Row(
            children: [
              _pad(',', () => setState(() => _press(','))),
              _pad('0', () => setState(() => _press('0'))),
              _pad('⌫', () => setState(() => _press('del'))),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _confirmAmount,
            child: const Text('Ödeme yap'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Demo uygulamasıdır, gerçek para transferi yapmaz.',
            style: TextStyle(fontSize: 12, color: kMuted),
          ),
        ],
      ),
    );
  }

  Widget _confirmBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),
          const GlowIcon(Icons.credit_card, size: 30),
          const SizedBox(height: 20),
          const Text('Ödeme onayı', style: TextStyle(color: kMuted)),
          const SizedBox(height: 6),
          Text(
            '${formatAmount(_amount)} ₺',
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          if (_nfcMessage != null) ...[
            Text(
              _nfcMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kPink),
            ),
            const SizedBox(height: 16),
          ],
          const Spacer(),
          FilledButton.icon(
            onPressed: _pay,
            icon: const Icon(Icons.nfc),
            label: const Text('Ödemeyi başlat'),
          ),
          TextButton(onPressed: _reset, child: const Text('Tutarı değiştir')),
        ],
      ),
    );
  }

  Widget _statusBody(IconData icon, String title, String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlowIcon(icon, size: 32),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted),
            ),
          ],
          const SizedBox(height: 24),
          const GradientSpinner(size: 44),
        ],
      ),
    );
  }

  Widget _waitingBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),
          const GlowIcon(Icons.nfc, size: 40),
          const SizedBox(height: 28),
          const Text(
            'Kartı okut',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Text(
            'Telefonun arkasını karta yaklaştır.\n'
            'NFC alanı genelde kameranın yanındadır.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted),
          ),
          const SizedBox(height: 28),
          const GradientSpinner(size: 56),
          const Spacer(),
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.close),
            label: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  Widget _processingBody() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlowIcon(Icons.sync, size: 36),
          SizedBox(height: 28),
          Text(
            'Ödeme işleniyor…',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 24),
          GradientSpinner(size: 60),
          SizedBox(height: 16),
          Text(
            'Bu işlem internet gerektirmez.',
            style: TextStyle(fontSize: 12, color: kMuted),
          ),
        ],
      ),
    );
  }

  Widget _successBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              gradient: kGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: kGreen, blurRadius: 30, spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.check, size: 58, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ödeme başarılı',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatAmount(_amount)} ₺',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _row('Kart', _card!.maskedTail),
                _row('Kart sahibi', _card!.name),
                _row('Banka', _card!.bank),
                _row('Son kullanma', _card!.expiry),
                _row('İşlem no', _receiptNo),
                _row('Durum', 'Onaylandı', color: kGreen),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _reset, child: const Text('Yeni ödeme')),
          const SizedBox(height: 8),
          const Text(
            'Demo — gerçek para transferi yapılmamıştır.',
            style: TextStyle(fontSize: 12, color: kMuted),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kMuted)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
