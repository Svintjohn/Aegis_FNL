import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const navy = Color(0xFF1E3A8A);
  static const navyLight = Color(0xFF2748B0);
  static const navyDeep = Color(0xFF14245A);

  static const green = Color(0xFF10B981);
  static const greenDeep = Color(0xFF0B7A56);

  static const bg = Color(0xFFF3F4F6);
  static const card = Color(0xFFFFFFFF);
  static const red = Color(0xFFEF4444);
  static const amber = Color(0xFFF59E0B);

  static const ink = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);
  static const line = Color(0xFFE5E7EB);

  static const navyGradient = [navy, navyLight];
  static const greenGradient = [green, Color(0xFF0EA871)];
}

class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
}

class AppText {
  static TextStyle get display => GoogleFonts.manrope(
        fontSize: 28, fontWeight: FontWeight.w800, height: 1.15,
        letterSpacing: -0.5, color: AppColors.ink,
      );

  static TextStyle get heading => GoogleFonts.manrope(
        fontSize: 20, fontWeight: FontWeight.w700,
        letterSpacing: -0.2, color: AppColors.ink,
      );

  static TextStyle get title => GoogleFonts.manrope(
        fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.ink,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14.5, height: 1.45, color: AppColors.ink,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12, height: 1.35, color: AppColors.muted,
      );
}

ThemeData buildTheme() {
  final scheme = const ColorScheme.light(
    primary: AppColors.navy,
    onPrimary: Colors.white,
    secondary: AppColors.green,
    onSecondary: Colors.white,
    surface: AppColors.card,
    onSurface: AppColors.ink,
    error: AppColors.red,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppText.heading,
    ),
    textTheme: TextTheme(
      headlineMedium: AppText.display,
      headlineSmall: AppText.heading,
      titleMedium: AppText.title,
      bodyMedium: AppText.body,
      labelSmall: AppText.caption,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: AppText.body.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// ₱1,250.00
String peso(double amount) {
  final whole = amount.floor();
  final cents = ((amount - whole) * 100).round().toString().padLeft(2, '0');
  final digits = whole.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '₱$buffer.$cents';
}

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays == 1) return 'yesterday';
  return '${d.inDays}d ago';
}
