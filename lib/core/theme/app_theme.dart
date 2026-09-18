import 'package:flutter/material.dart';

class AppTheme {
  // Tactical Dark Palette
  static const Color background = Color(0xFF0F1216);
  static const Color surface = Color(0xFF171C23);
  static const Color surfaceElevated = Color(0xFF202731);
  static const Color border = Color(0xFF2C3543);
  static const Color borderFocused = Color(0xFF4B5E78);

  // Accents
  static const Color primaryAmber = Color(0xFFF59E0B);
  static const Color tacticalCyan = Color(0xFF38BDF8);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color alertRed = Color(0xFFEF4444);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static const TextStyle monospace = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontFamilyFallback: [
      'Consolas',
      'SF Mono',
      'Menlo',
      'Monaco',
      'DejaVu Sans Mono',
      'monospace',
    ],
  );

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: primaryAmber,
      onPrimary: Colors.black,
      secondary: tacticalCyan,
      onSecondary: Colors.black,
      surface: surface,
      onSurface: textPrimary,
      error: alertRed,
      onError: Colors.white,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      fontFamily: 'Inter',
      fontFamilyFallback: const [
        'Segoe UI',
        'SF Pro Text',
        'Ubuntu',
        'Roboto',
        'Noto Sans',
        'sans-serif',
      ],
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primaryAmber, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAmber,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(borderFocused),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(6),
      ),
    );
  }
}
