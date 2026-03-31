import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart' show Colors;

class AppTheme {
  AppTheme._();

  // Modern, vibrant color palette
  static const Color primaryColor = Color(0xFF0D47A1); // Deep railway blue
  static const Color primaryLight = Color(0xFF1976D2); // Lighter primary
  static const Color secondaryColor = Color(0xFFFF9800); // Vibrant orange
  static const Color accentColor = Color(0xFF00BCD4); // Cyan accent
  static const Color successColor = Color(0xFF27AE60);
  static const Color dangerColor = Color(0xFFE74C3C);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color infoColor = Color(0xFF3498DB);
  
  // Neutral colors
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color backgroundColor = Color(0xFFFBFDFE);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  static Brightness resolveBrightness({
    required material.ThemeMode themeMode,
    required Brightness platformBrightness,
  }) {
    switch (themeMode) {
      case material.ThemeMode.light:
        return Brightness.light;
      case material.ThemeMode.dark:
        return Brightness.dark;
      case material.ThemeMode.system:
        return platformBrightness;
    }
  }

  static CupertinoThemeData cupertinoTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? CupertinoColors.white : textPrimary;

    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0A0E21) : const Color(0xFFF2F4F8),
      barBackgroundColor: isDark
          ? const Color(0xFF0A0E21).withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.85),
      textTheme: CupertinoTextThemeData(
        primaryColor: primaryColor,
        textStyle: TextStyle(color: textColor),
        navTitleTextStyle: TextStyle(
          color: textColor,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static material.ThemeData materialCompatibilityTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return material.ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: material.ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0A0E21) : const Color(0xFFF2F4F8),
      appBarTheme: material.AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF121212) : primaryColor,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 1,
      ),
      cardTheme: material.CardThemeData(
        elevation: isDark ? 2 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? const Color(0xFF1E1E1E) : cardBackground,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: material.InputDecorationTheme(
        border: material.OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: material.BorderSide(
            color: isDark ? const Color(0xFF616161) : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
        enabledBorder: material.OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: material.BorderSide(
            color: isDark ? const Color(0xFF616161) : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
        focusedBorder: material.OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const material.BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: material.OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const material.BorderSide(color: dangerColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        hintStyle: const TextStyle(color: textHint, fontSize: 14),
        labelStyle: TextStyle(
          color: isDark ? Colors.white.withValues(alpha: 0.9) : textPrimary,
          fontSize: 14,
        ),
      ),
      textTheme: material.TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : textPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.white.withValues(alpha: 0.92) : textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.white.withValues(alpha: 0.75) : textSecondary,
          height: 1.43,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.white.withValues(alpha: 0.66) : textSecondary,
          height: 1.33,
        ),
      ),
    );
  }

  static material.ThemeData get lightTheme => materialCompatibilityTheme(Brightness.light);

  static material.ThemeData get darkTheme => materialCompatibilityTheme(Brightness.dark);
}
