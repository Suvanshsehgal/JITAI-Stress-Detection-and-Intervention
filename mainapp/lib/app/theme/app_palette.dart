import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-aware colors. Widgets read these through `context.pal` so that
/// light and dark mode always use matching foreground/background pairs.
/// (The old `AppColors.lightX` constants stay as the source values.)
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.page,
    required this.paper,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.brand,
    required this.onBrand,
    required this.accent,
    required this.accentSoft,
    required this.calm,
    required this.calmSoft,
    required this.warm,
    required this.warmSoft,
    required this.rose,
    required this.roseSoft,
  });

  final Color page;
  final Color paper;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  /// Main button / strong surface color, and the text/icon color to put on it.
  final Color brand;
  final Color onBrand;

  final Color accent;
  final Color accentSoft;
  final Color calm;
  final Color calmSoft;
  final Color warm;
  final Color warmSoft;
  final Color rose;
  final Color roseSoft;

  static const AppPalette light = AppPalette(
    page: AppColors.lightPage,
    paper: AppColors.lightPaper,
    card: AppColors.lightCard,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    border: AppColors.lightBorder,
    brand: AppColors.lightBrand,
    onBrand: Colors.white,
    accent: AppColors.lightAccent,
    accentSoft: AppColors.lightAccentSoft,
    calm: AppColors.lightCalm,
    calmSoft: AppColors.lightCalmSoft,
    warm: AppColors.lightWarm,
    warmSoft: AppColors.lightWarmSoft,
    rose: AppColors.lightRose,
    roseSoft: AppColors.lightRoseSoft,
  );

  static const AppPalette dark = AppPalette(
    page: AppColors.darkPage,
    paper: AppColors.darkPaper,
    card: AppColors.darkCard,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    border: AppColors.darkBorder,
    brand: AppColors.darkBrand,
    onBrand: Color(0xFF161210),
    accent: AppColors.darkAccent,
    accentSoft: AppColors.darkAccentSoft,
    calm: AppColors.darkCalm,
    calmSoft: AppColors.darkCalmSoft,
    warm: AppColors.darkWarm,
    warmSoft: AppColors.darkWarmSoft,
    rose: AppColors.darkRose,
    roseSoft: AppColors.darkRoseSoft,
  );

  @override
  AppPalette copyWith({
    Color? page,
    Color? paper,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? brand,
    Color? onBrand,
    Color? accent,
    Color? accentSoft,
    Color? calm,
    Color? calmSoft,
    Color? warm,
    Color? warmSoft,
    Color? rose,
    Color? roseSoft,
  }) {
    return AppPalette(
      page: page ?? this.page,
      paper: paper ?? this.paper,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      calm: calm ?? this.calm,
      calmSoft: calmSoft ?? this.calmSoft,
      warm: warm ?? this.warm,
      warmSoft: warmSoft ?? this.warmSoft,
      rose: rose ?? this.rose,
      roseSoft: roseSoft ?? this.roseSoft,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      page: Color.lerp(page, other.page, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      card: Color.lerp(card, other.card, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      calm: Color.lerp(calm, other.calm, t)!,
      calmSoft: Color.lerp(calmSoft, other.calmSoft, t)!,
      warm: Color.lerp(warm, other.warm, t)!,
      warmSoft: Color.lerp(warmSoft, other.warmSoft, t)!,
      rose: Color.lerp(rose, other.rose, t)!,
      roseSoft: Color.lerp(roseSoft, other.roseSoft, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The palette for the current theme (light or dark).
  AppPalette get pal => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
