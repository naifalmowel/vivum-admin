import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VivumColors {
  static const teal = Color(0xFF00B5CC);
  static const tealLight = Color(0xFF33C6D9);
  static const tealDark = Color(0xFF008FA3);
  static const amber = Color(0xFFF5A61A);
  static const amberLight = Color(0xFFF7B84B);

  static const darkBG = Color(0xFF15171E); 
  static const darkSurface = Color(0xFF1C1F26);
  static const darkCard = Color(0xFF232730);
  static const darkBorder = Color(0xFF2E333D);
  static const darkMuted = Color(0xFF9499B8);
  static const darkWhite = Color(0xFFE2E4E9);

  static const lightBG = Color(0xFFF5F7FA); 
  static const lightBGAlt = Color(0xFFEDF1F5); 
  static const lightSurface = Color(0xFFFDFDFD); 
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFD1D9E0); 
  static const lightMuted = Color(0xFF5A6672); 
  static const lightText = Color(0xFF1A1F2E); 

  static const LinearGradient tealGradient = LinearGradient(
    colors: [teal, Color(0xFF006B7A)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [amber, Color(0xFFE8890A)],
  );
}

class AppTheme {
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme colorScheme = isDark
        ? const ColorScheme.dark(
            primary: VivumColors.teal,
            secondary: VivumColors.amber,
            surface: VivumColors.darkSurface,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: VivumColors.darkWhite,
            outline: VivumColors.darkBorder,
          )
        : const ColorScheme.light(
            primary: VivumColors.teal,
            secondary: VivumColors.amber,
            surface: VivumColors.lightSurface,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: VivumColors.lightText,
            outline: VivumColors.lightBorder,
          );

    final baseTextTheme = GoogleFonts.cairoTextTheme();
    final textColor = isDark ? VivumColors.darkWhite : VivumColors.lightText;
    final mutedColor = isDark ? VivumColors.darkMuted : VivumColors.lightMuted;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      textTheme: baseTextTheme.copyWith(
        displaySmall: baseTextTheme.displaySmall?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: mutedColor),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: mutedColor),
      ),
      scaffoldBackgroundColor: isDark ? VivumColors.darkBG : VivumColors.lightBG,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color: isDark ? VivumColors.darkCard : VivumColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),
    );
  }
}
