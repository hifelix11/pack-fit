import 'package:flutter/material.dart';

class PackFitTheme {
  PackFitTheme._();

  // ── Colours ──────────────────────────────────────────────
  static const Color background = Color(0xFF0A0A0A);
  static const Color timerBackground = Color(0xFF000000);
  static const Color accent = Color(0xFF00E676);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888888);
  static const Color error = Color(0xFFFF5252);

  // ── Radii ────────────────────────────────────────────────
  static const double buttonRadius = 28;
  static const double cardRadius = 16;

  // ── LED colours ──────────────────────────────────────────
  static const Color ledOn = Color(0xFF00E676);
  static const Color ledOff = Color(0x1400E676);

  // ── Theme data ───────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accent,
          surface: Color(0xFF1A1A1A),
          error: error,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              color: textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(
              color: textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(
              color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(
              color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
          labelLarge: TextStyle(
              color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: const BorderSide(color: accent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: accent),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: textSecondary),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF2A2A2A),
          contentTextStyle: TextStyle(color: textPrimary),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
        ),
      );
}
