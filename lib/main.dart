import 'package:flutter/material.dart';

import 'screens.dart';
import 'theme.dart';

void main() => runApp(const NfcPayApp());

class NfcPayApp extends StatelessWidget {
  const NfcPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC Pay',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const Gate(),
    );
  }
}
