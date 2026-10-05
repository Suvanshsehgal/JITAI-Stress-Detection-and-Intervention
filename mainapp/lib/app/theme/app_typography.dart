import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Headings: Bricolage Grotesque
  static final TextStyle _bricolage = GoogleFonts.bricolageGrotesque();
  // Body/Interface: Figtree
  static final TextStyle _figtree = GoogleFonts.figtree();

  static TextTheme createTextTheme(Color primaryTextColor, Color secondaryTextColor) {
    return TextTheme(
      displayLarge: _bricolage.copyWith(fontSize: 57, fontWeight: FontWeight.bold, color: primaryTextColor),
      displayMedium: _bricolage.copyWith(fontSize: 45, fontWeight: FontWeight.bold, color: primaryTextColor),
      displaySmall: _bricolage.copyWith(fontSize: 36, fontWeight: FontWeight.bold, color: primaryTextColor),
      
      headlineLarge: _bricolage.copyWith(fontSize: 32, fontWeight: FontWeight.w700, color: primaryTextColor),
      headlineMedium: _bricolage.copyWith(fontSize: 28, fontWeight: FontWeight.w600, color: primaryTextColor),
      headlineSmall: _bricolage.copyWith(fontSize: 24, fontWeight: FontWeight.w600, color: primaryTextColor),
      
      titleLarge: _bricolage.copyWith(fontSize: 22, fontWeight: FontWeight.w600, color: primaryTextColor),
      titleMedium: _bricolage.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: primaryTextColor),
      titleSmall: _bricolage.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: primaryTextColor),
      
      bodyLarge: _figtree.copyWith(fontSize: 16, fontWeight: FontWeight.w400, color: primaryTextColor),
      bodyMedium: _figtree.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: primaryTextColor),
      bodySmall: _figtree.copyWith(fontSize: 12, fontWeight: FontWeight.w400, color: secondaryTextColor),
      
      labelLarge: _figtree.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: primaryTextColor),
      labelMedium: _figtree.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: primaryTextColor),
      labelSmall: _figtree.copyWith(fontSize: 11, fontWeight: FontWeight.w500, color: secondaryTextColor),
    );
  }
}
