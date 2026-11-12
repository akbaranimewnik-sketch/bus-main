import 'package:flutter/material.dart';

/// Professional Color Palette inspired by Coolors.co (Top Popular Professional schemes):
/// - Deep Corporate Navy: #0A192F / #003D74
/// - Modern Business Blue: #1171BA
/// - Innovation Tech Cyan: #24AAE2 / #1399C6
/// - ESG & Green Transit Teal: #0E8C7F
/// - Executive Accent Gold: #D4AF37
/// - Neutral Steel / Slate: #2E4053 / #425363
/// - Clean Light Neutral: #F4F6F8
class AppColors {
  // Primary Corporate & Tech anchors (Coolors Professional)
  static const primary = Color(0xFF003D74); // Deep Corporate Blue (#003d74)
  static const primaryLight = Color(0xFF1171BA); // Modern Business Blue (#1171ba)
  static const primaryDark = Color(0xFF0A192F); // Deep Tech Navy (#0a192f)
  static const primaryNavy = Color(0xFF1C2833); // Deep Neutral Navy (#1c2833)

  // Accents & Innovation (Coolors Professional)
  static const accent = Color(0xFF0E8C7F); // Green Transit Teal (#0e8c7f)
  static const accentCyan = Color(0xFF24AAE2); // Innovation Cyan (#24aae2)
  static const accentSky = Color(0xFF1399C6); // High-contrast Tech Blue (#1399c6)
  static const accentGold = Color(0xFFD4AF37); // Executive Muted Gold (#d4af37)
  static const accentAmber = Color(0xFFED7700); // Dynamic Business Orange (#ed7700)
  static const accentViolet = Color(0xFF635BFF); // Modern Tech Violet (#635bff)

  // Neutrals (Coolors Balanced Neutrals)
  static const background = Color(0xFFF4F6F8); // Clean Crisp Neutral (#f4f6f8)
  static const surface = Colors.white;
  static const surfaceDark = Color(0xFF0F172A);
  static const surfaceCardDark = Color(0xFF1C2833);
  static const surfaceBorderDark = Color(0xFF2E4053);

  // Status & Feedback
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFED7700);
  static const success = Color(0xFF0E8C7F);

  // Typography & Borders
  static const textPrimary = Color(0xFF1C2833); // Slate Navy Text (#1c2833)
  static const textSecondary = Color(0xFF425363); // Coolors Slate Gray (#425363)
  static const textMuted = Color(0xFF8896A6);
  static const border = Color(0xFFE2E8F0);

  // Professional Gradients
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A192F), // Coolors Tech Deep Navy
      Color(0xFF003D74), // Coolors Corporate Navy
      Color(0xFF1171BA), // Coolors Business Blue
    ],
  );

  static const cyanBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF24AAE2), // Coolors Cyan
      Color(0xFF1171BA), // Coolors Blue
    ],
  );

  static const emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0E8C7F), // Coolors Transit Teal
      Color(0xFF10B981), // Fresh Mint Emerald
    ],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD4AF37), // Coolors Muted Gold
      Color(0xFFED7700), // Coolors Energetic Amber
    ],
  );

  static const cardDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1C2833),
      Color(0xFF0F172A),
    ],
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Outfit',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryLight,
      surface: AppColors.surface,
      primary: AppColors.primary,
      secondary: AppColors.accentCyan,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w800,
        fontSize: 18,
        color: Colors.white,
        letterSpacing: -0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: AppColors.primaryLight.withOpacity(0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    fontFamily: 'Outfit',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryLight,
      brightness: Brightness.dark,
      surface: AppColors.surfaceDark,
      primary: AppColors.accentCyan,
      secondary: AppColors.accent,
    ),
    scaffoldBackgroundColor: const Color(0xFF080D1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w800,
        fontSize: 18,
        color: Colors.white,
      ),
    ),
  );
}
