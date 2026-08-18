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

  static const lightBG = Color(0xFFF0F4F8); // أزرق ثلجي فاتح جداً
  static const lightBGAlt = Color(0xFFD9E2EC); 
  static const lightSurface = Color(0xFFFFFFFF); 
  static const lightCard = Color(0xFFFFFFFF); // أبيض ناصع
  static const lightBorder = Color(0xFFD9E2EC); // كحلي فاتح جداً
  static const lightMuted = Color(0xFF486581); // درجة متوسطة من الكحلي
  static const lightText = Color(0xFF102A43); // أزرق ليلي داكن جداً

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
            surfaceContainerHighest: VivumColors.darkCard,
          )
        : const ColorScheme.light(
            primary: VivumColors.teal,
            secondary: VivumColors.amber,
            surface: VivumColors.lightSurface,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: VivumColors.lightText,
            outline: VivumColors.lightBorder, 
            surfaceContainerHighest: Color(0xFFE1E8F0), // ظل أنعم من الأزرق الثلجي
          );

    final baseTextTheme = GoogleFonts.cairoTextTheme();
    final textColor = isDark ? VivumColors.darkWhite : VivumColors.lightText;
    final mutedColor = isDark ? VivumColors.darkMuted : VivumColors.lightMuted;
    final secondaryTextColor = isDark ? VivumColors.darkMuted : VivumColors.lightMuted;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        displaySmall: baseTextTheme.displaySmall?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.w600),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: textColor, fontWeight: FontWeight.w600),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textColor),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: secondaryTextColor),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: secondaryTextColor),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: secondaryTextColor),
        labelSmall: baseTextTheme.labelSmall?.copyWith(color: secondaryTextColor),
      ),
      scaffoldBackgroundColor: isDark ? VivumColors.darkBG : VivumColors.lightBG,
      hintColor: mutedColor,
      dividerColor: isDark ? VivumColors.darkBorder : VivumColors.lightBorder,
      cardColor: isDark ? VivumColors.darkCard : VivumColors.lightCard,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color: isDark ? VivumColors.darkCard : VivumColors.lightCard,
        elevation: isDark ? 0 : 2, // إضافة شادو خفيف جداً في اللايت مود لتمييز الكروت
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outline, 
            width: isDark ? 1 : 0.5, // بورد أنعم في اللايت مود مع الشادو
          ),
        ),
      ),
    );
  }
}
