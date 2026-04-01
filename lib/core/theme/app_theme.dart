import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/app_theme_mode.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFFFF9800);
  static const Color accentColor = Color(0xFF00BCD4);
  static const Color successColor = Color(0xFF27AE60);
  static const Color dangerColor = Color(0xFFE74C3C);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color infoColor = Color(0xFF3498DB);

  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color backgroundColor = Color(0xFFFBFDFE);
  static const Color cardBackground = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  static Brightness resolveBrightness({
    required AppThemeMode themeMode,
    required Brightness platformBrightness,
  }) {
    switch (themeMode) {
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
        return Brightness.dark;
      case AppThemeMode.system:
        return platformBrightness;
    }
  }

  static CupertinoThemeData cupertinoTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? CupertinoColors.white : textPrimary;

    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0A0E21)
          : const Color(0xFFF2F4F8),
      barBackgroundColor: isDark
          ? const Color(0xFF0A0E21).withValues(alpha: 0.85)
          : CupertinoColors.white.withValues(alpha: 0.85),
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
}
