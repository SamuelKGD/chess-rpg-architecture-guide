import 'package:flutter/material.dart';

/// Design System — Modern Brutalism
///
/// Couleurs haute intensité, typographie massive, composants bruts.
/// Animations ultra-fluides 60fps.

class BrutalistColors {
  BrutalistColors._();

  // Backgrounds — High Contrast
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color backgroundLight = Color(0xFFF5F5F0);
  static const Color surface = Color(0xFF1A1A1A);

  // Accents — Néon / Stabilo (Call-to-Action)
  static const Color accentYellow = Color(0xFFE6FF00);
  static const Color accentRed = Color(0xFFFF2D2D);
  static const Color accentGreen = Color(0xFF00FF85);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textOnAccent = Color(0xFF0A0A0A);
}

class BrutalistTypography {
  BrutalistTypography._();

  /// Titres — Effet pancarte / tract
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 48,
    fontWeight: FontWeight.w900,
    letterSpacing: -2,
    height: 0.95,
    color: BrutalistColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    color: BrutalistColors.textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: BrutalistColors.textPrimary,
  );

  /// Corps de texte
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: BrutalistColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: BrutalistColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: BrutalistColors.textOnAccent,
  );
}

/// ThemeData brutaliste pour l'application.
ThemeData brutalistTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: BrutalistColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: BrutalistColors.accentYellow,
      secondary: BrutalistColors.accentRed,
      surface: BrutalistColors.surface,
    ),
    textTheme: const TextTheme(
      displayLarge: BrutalistTypography.displayLarge,
      displayMedium: BrutalistTypography.displayMedium,
      headlineLarge: BrutalistTypography.headlineLarge,
      bodyLarge: BrutalistTypography.bodyLarge,
      bodySmall: BrutalistTypography.bodySmall,
      labelSmall: BrutalistTypography.label,
    ),
    useMaterial3: true,
  );
}
