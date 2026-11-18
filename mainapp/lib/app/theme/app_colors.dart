import 'package:flutter/material.dart';

class AppColors {
  // Still Point / Stride Probe Light Theme Palette
  // Warm linen canvas with visible depth against pure white cards
  static const Color lightPage = Color(0xFFF7F3EE);          // Warm linen/canvas surface
  static const Color lightPaper = Color(0xFFEDE4DA);         // Distinct secondary surface
  static const Color lightCard = Color(0xFFFFFFFF);          // Clean pure white card surface
  static const Color lightTextPrimary = Color(0xFF241815);   // Deep espresso ink (AAA contrast)
  static const Color lightTextSecondary = Color(0xFF65544B); // Rich warm brown (high legibility)
  static const Color lightTextTertiary = Color(0xFF8C7B72);  // Subtle hint/timestamp brown
  static const Color lightBorder = Color(0xFFE2D7CC);        // Crisp, tactile card & box boundary
  
  // Brand & Accent Colors
  static const Color lightBrand = Color(0xFF352520);         // Deep warm espresso brown (primary dark)
  static const Color lightBrandSubtext = Color(0xFFEADBCE);  // High-contrast ivory text on dark brand
  static const Color lightAccent = Color(0xFFEE7A5C);        // Vibrant terracotta coral (action/CTA)
  static const Color lightAccentSoft = Color(0xFFFCE8E2);    // Coral soft tint
  
  // Stress Metric Status Colors
  static const Color lightCalm = Color(0xFF227B55);          // Forest emerald green (0-33 Calm)
  static const Color lightCalmSoft = Color(0xFFE6F4EA);
  static const Color lightWarm = Color(0xFFD47A22);          // Warm amber / ochre (34-66 Moderate)
  static const Color lightWarmSoft = Color(0xFFFDF2E2);
  static const Color lightRose = Color(0xFFD94843);          // Terracotta alert red (67-100 High)
  static const Color lightRoseSoft = Color(0xFFFCE8E6);

  // Mascot & Fun Accents
  static const Color mascotPurple = Color(0xFFC042EB);       // Cheerful Stillpoint purple berry
  static const Color mascotRosy = Color(0xFFF875AA);         // Rosy cheeks
  static const Color mascotLeaf = Color(0xFF78C850);         // Sprout leaf

  // Dark Theme Tokens (Warm Charcoal)
  static const Color darkPage = Color(0xFF161210);
  static const Color darkPaper = Color(0xFF221C19);
  static const Color darkCard = Color(0xFF2C2521);
  static const Color darkTextPrimary = Color(0xFFFAF7F3);
  static const Color darkTextSecondary = Color(0xFFC5B8AF);
  static const Color darkBorder = Color(0xFF453B34);

  static const Color darkBrand = Color(0xFFF5EFEB);
  static const Color darkAccent = Color(0xFFFF8E72);
  static const Color darkAccentSoft = Color(0xFF3D251E);
  static const Color darkCalm = Color(0xFF56C79A);
  static const Color darkCalmSoft = Color(0xFF19382B);
  static const Color darkWarm = Color(0xFFF5B85A);
  static const Color darkWarmSoft = Color(0xFF3A2E17);
  static const Color darkRose = Color(0xFFF07A90);
  static const Color darkRoseSoft = Color(0xFF3D1B25);
}
