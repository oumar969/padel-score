import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const bgColor = Color(0xFF07070F);
const surfaceColor = Color(0xFF0F0F1C);
const cardColor = Color(0xFF141424);
const dividerColor = Color(0xFF252540);

const team1Color = Color(0xFF5B9FFF);
const team1Dark = Color(0xFF1A3A80);
const team2Color = Color(0xFFFF5A5A);
const team2Dark = Color(0xFF801A1A);

const accentGreen = Color(0xFF3DFFA0);
const goldColor = Color(0xFFFFD700);

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: bgColor,
    colorScheme: const ColorScheme.dark(
      primary: team1Color,
      secondary: team2Color,
      surface: surfaceColor,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 108,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: -4,
        height: 1,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -2,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.white54,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: Colors.white38,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bgColor,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: team1Color, width: 2),
      ),
      labelStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: team1Color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        elevation: 0,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: dividerColor, width: 1),
      ),
    ),
  );
}
