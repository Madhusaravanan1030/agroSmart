import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF1D9E75);
  static const Color lightGreen   = Color(0xFFE1F5EE);
  static const Color darkGreen    = Color(0xFF0F6E56);
  static const Color skyBlue      = Color(0xFF378ADD);
  static const Color lightBlue    = Color(0xFFE6F1FB);
  static const Color warmAmber    = Color(0xFFBA7517);
  static const Color lightAmber   = Color(0xFFFAEEDA);
  static const Color softRed      = Color(0xFFE24B4A);
  static const Color lightRed     = Color(0xFFFCEBEB);
  static const Color surfaceGray  = Color(0xFFF5F5F5);
  static const Color borderGray   = Color(0xFFE0E0E0);
  static const Color darkSurface  = Color(0xFF121212);
  static const Color darkCard     = Color(0xFF1E1E1E);
  static const Color darkBorder   = Color(0xFF2C2C2C);
  static const Color darkAppBar   = Color(0xFF0D5C42);

  // ── Light theme ───────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: skyBlue,
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 18,
        fontWeight: FontWeight.w600, fontFamily: 'Poppins',
      ),
    ),
    // ✅ Fix: CardTheme → CardThemeData
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderGray, width: 0.5),
      ),
      margin: const EdgeInsets.only(bottom: 12),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 8,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey,
    ),
    scaffoldBackgroundColor: surfaceGray,
    fontFamily: 'Poppins',
    dividerColor: borderGray,
  );

  // ── Dark theme ────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: skyBlue,
      surface: darkCard,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkAppBar,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 18,
        fontWeight: FontWeight.w600, fontFamily: 'Poppins',
      ),
    ),
    // ✅ Fix: CardTheme → CardThemeData
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: darkBorder, width: 0.5),
      ),
      margin: const EdgeInsets.only(bottom: 12),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkCard,
      elevation: 8,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey,
    ),
    scaffoldBackgroundColor: darkSurface,
    fontFamily: 'Poppins',
    dividerColor: darkBorder,
  );

  // ── cardDecoration: TWO versions ─────────────────────────────
  // Use cardDecoration(context) when you have BuildContext available.
  // Use cardDecorationStatic when you don't (e.g. inside non-widget helpers).

  /// Context-aware version — adapts to dark/light mode automatically
  static BoxDecoration cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkCard : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: isDark ? darkBorder : borderGray, width: 0.5),
    );
  }

  /// Static fallback — always light. Use ONLY where context isn't available.
  static BoxDecoration get cardDecorationStatic => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: borderGray, width: 0.5),
  );

  static BoxDecoration metricDecoration(Color tint) => BoxDecoration(
    color: tint.withOpacity(0.12),
    borderRadius: BorderRadius.circular(10),
  );

  static Widget badge(String label, Color bg, Color text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: text)),
  );
}