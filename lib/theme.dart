import 'package:flutter/material.dart';

/// Uygulamanin renk paleti: mavi, pembe, yesil.
const kBlue = Color(0xFF2E6BFF);
const kPink = Color(0xFFFF3D9A);
const kGreen = Color(0xFF16C98D);
const kBg = Color(0xFF0B1026);
const kCard = Color(0xFF151B3B);
const kText = Color(0xFFF2F4FF);
const kMuted = Color(0xFF8B93C0);

/// Mavi -> pembe -> yesil gecisli ana renk.
const kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kBlue, kPink, kGreen],
);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kBlue,
      brightness: Brightness.dark,
    ).copyWith(primary: kBlue, secondary: kPink, tertiary: kGreen),
  );
  return base.copyWith(
    scaffoldBackgroundColor: kBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: kText,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: kText,
      displayColor: kText,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kBlue, width: 2),
      ),
    ),
  );
}

/// Uygulamanin her yerinde kullanilan renkli baslik.
class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const GradientHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: const BoxDecoration(
        gradient: kGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cevap beklerken donen renkli halka.
class GradientSpinner extends StatelessWidget {
  final double size;
  const GradientSpinner({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => kGradient.createShader(r),
      child: SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(
          strokeWidth: 6,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      ),
    );
  }
}

/// Yuvarlak, gradyanli buyuk ikon.
class GlowIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  const GlowIcon(this.icon, {super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 2.2,
      height: size * 2.2,
      decoration: BoxDecoration(
        gradient: kGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: kBlue.withOpacity(0.5), blurRadius: 24),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}
