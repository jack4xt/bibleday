import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Tmavé barvy
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surfaceElevated = Color(0xFF1A1A26);
  static const Color neonGold = Color(0xFFFFD700);
  static const Color neonGoldGlow = Color(0xFFFFAA00);
  static const Color neonPurple = Color(0xFFAA66FF);
  static const Color neonPurpleGlow = Color(0xFF7733CC);
  static const Color textPrimary = Color(0xFFF0E6D3);
  static const Color textSecondary = Color(0xFF8A7A6A);
  static const Color divider = Color(0xFF2A2A3A);

  // Světlé barvy
  static const Color lightBackground = Color(0xFFFAF8F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF5F0E8);
  static const Color lightGold = Color(0xFFB8860B);
  static const Color lightPurple = Color(0xFF7733CC);
  static const Color lightTextPrimary = Color(0xFF1A1208);
  static const Color lightTextSecondary = Color(0xFF6B5D4A);
  static const Color lightDivider = Color(0xFFE5DDD0);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: neonGold,
        secondary: neonPurple,
        onSurface: textPrimary,
        onPrimary: background,
      ),
      textTheme: GoogleFonts.crimsonTextTextTheme().copyWith(
        displayLarge: GoogleFonts.cinzelDecorative(
          color: neonGold,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.cinzel(
          color: neonGold,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
        headlineMedium: GoogleFonts.cinzel(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.crimsonText(
          color: textPrimary,
          fontSize: 18,
          height: 1.7,
        ),
        bodyMedium: GoogleFonts.crimsonText(
          color: textSecondary,
          fontSize: 16,
          height: 1.6,
        ),
        labelMedium: GoogleFonts.cinzel(
          color: textSecondary,
          fontSize: 11,
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cinzelDecorative(
          color: neonGold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: neonGold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: neonGold,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        surface: lightSurface,
        primary: lightGold,
        secondary: lightPurple,
        onSurface: lightTextPrimary,
        onPrimary: lightBackground,
      ),
      textTheme: GoogleFonts.crimsonTextTextTheme().copyWith(
        displayLarge: GoogleFonts.cinzelDecorative(
          color: lightGold,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.cinzel(
          color: lightGold,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
        headlineMedium: GoogleFonts.cinzel(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.crimsonText(
          color: lightTextPrimary,
          fontSize: 18,
          height: 1.7,
        ),
        bodyMedium: GoogleFonts.crimsonText(
          color: lightTextSecondary,
          fontSize: 16,
          height: 1.6,
        ),
        labelMedium: GoogleFonts.cinzel(
          color: lightTextSecondary,
          fontSize: 11,
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightDivider, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cinzelDecorative(
          color: lightGold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: lightGold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: lightGold,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 1,
      ),
    );
  }

  // Helper metody pro dynamické barvy podle tématu
  static Color surfaceColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surface : lightSurface;

  static Color surfaceElevatedColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceElevated : lightSurfaceElevated;

  static Color backgroundColorOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? background : lightBackground;

  static Color textPrimaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPrimary : lightTextPrimary;

  static Color textSecondaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondary : lightTextSecondary;

  static Color dividerColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? divider : lightDivider;

  static Color goldColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? neonGold : lightGold;

  static Color purpleColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? neonPurple : lightPurple;
}
