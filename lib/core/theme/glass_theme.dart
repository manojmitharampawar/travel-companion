import 'package:flutter/cupertino.dart';

/// Centralized glass-morphism color system that adapts to light/dark mode.
///
/// Usage: `final g = GlassColors.of(context);`
/// Then use `g.bg`, `g.cardFill`, `g.text`, `g.textSecondary`, etc.
class GlassColors {
  final Brightness brightness;

  const GlassColors._(this.brightness);

  factory GlassColors.of(BuildContext context) {
    final cupertinoBrightness = CupertinoTheme.maybeBrightnessOf(context);
    final mediaBrightness = MediaQuery.maybePlatformBrightnessOf(context);
    return GlassColors._(
      cupertinoBrightness ?? mediaBrightness ?? Brightness.light,
    );
  }

  bool get isDark => brightness == Brightness.dark;

  // ── Background ──────────────────────────────
  Color get bg => isDark ? const Color(0xFF0A0E21) : const Color(0xFFF2F4F8);

  /// Background gradient colors for full-screen backgrounds.
  List<Color> get bgGradient => isDark
      ? const [
          Color(0xFF0A0E21),
          Color(0xFF0D1B3E),
          Color(0xFF1A0A2E),
          Color(0xFF0A1628),
        ]
      : const [
          Color(0xFFF2F4F8),
          Color(0xFFE8EDF5),
          Color(0xFFF0EBF5),
          Color(0xFFEBF0F5),
        ];

  // ── Surface / Card fills ────────────────────
  Color cardFill([double alpha = 0.07]) => isDark
      ? CupertinoColors.white.withValues(alpha: 0.12 + alpha)
      : CupertinoColors.white.withValues(alpha: 0.65 + alpha);

  Color cardFillSolid([double alpha = 0.07]) => isDark
      ? CupertinoColors.white.withValues(alpha: alpha)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.72);

  // ── Borders ─────────────────────────────────
  Color border([double alpha = 0.12]) => isDark
      ? CupertinoColors.white.withValues(alpha: alpha)
      : CupertinoColors.black.withValues(alpha: alpha * 0.7);

  // ── Text ────────────────────────────────────
  Color get text => isDark
      ? CupertinoColors.white.withValues(alpha: 0.92)
      : const Color(0xFF1A1D2E);

  Color get textSecondary => isDark
      ? CupertinoColors.white.withValues(alpha: 0.6)
      : const Color(0xFF5A5E6E);

  Color get textTertiary => isDark
      ? CupertinoColors.white.withValues(alpha: 0.4)
      : const Color(0xFF8A8E9E);

  Color get textHint => isDark
      ? CupertinoColors.white.withValues(alpha: 0.3)
      : const Color(0xFFAAAEB8);

  /// Custom text alpha — maps dark-mode white alpha to appropriate light equivalent.
  Color textAlpha(double darkAlpha) {
    if (isDark) return CupertinoColors.white.withValues(alpha: darkAlpha);
    // Map alpha to light-mode opacity: higher dark alpha → more opaque dark text
    if (darkAlpha >= 0.85) return const Color(0xFF1A1D2E);
    if (darkAlpha >= 0.7) return const Color(0xFF3A3E4E);
    if (darkAlpha >= 0.5) return const Color(0xFF5A5E6E);
    if (darkAlpha >= 0.35) return const Color(0xFF7A7E8E);
    return const Color(0xFFAAAEB8);
  }

  // ── Icon colors ─────────────────────────────
  Color get icon => isDark
      ? CupertinoColors.white.withValues(alpha: 0.8)
      : const Color(0xFF4A4E5E);

  Color iconAlpha(double darkAlpha) => textAlpha(darkAlpha);

  // ── Dividers ────────────────────────────────
  Color get divider => isDark
      ? CupertinoColors.white.withValues(alpha: 0.06)
      : CupertinoColors.black.withValues(alpha: 0.06);

  // ── Dropdown / popup background ─────────────
  Color get dropdownBg =>
      isDark ? const Color(0xFF1A2340) : const Color(0xFFF5F7FB);

  // ── Input fields ────────────────────────────
  Color get inputFill => isDark
      ? CupertinoColors.white.withValues(alpha: 0.14)
      : CupertinoColors.white.withValues(alpha: 0.8);

  Color get inputBorder => isDark
      ? CupertinoColors.white.withValues(alpha: 0.12)
      : CupertinoColors.black.withValues(alpha: 0.12);

  Color get inputFocusBorder => isDark
      ? CupertinoColors.white.withValues(alpha: 0.3)
      : CupertinoColors.black.withValues(alpha: 0.3);

  // ── AppBar glass ────────────────────────────
  Color get appBarBg => isDark
      ? const Color(0xFF0A0E21).withValues(alpha: 0.85)
      : CupertinoColors.white.withValues(alpha: 0.85);

  Color get appBarBorder => isDark
      ? CupertinoColors.white.withValues(alpha: 0.1)
      : CupertinoColors.black.withValues(alpha: 0.08);

  // ── Bottom bar ──────────────────────────────
  Color get bottomBarBg => isDark
      ? const Color(0xFF0A0E21).withValues(alpha: 0.85)
      : CupertinoColors.white.withValues(alpha: 0.9);

  Color get bottomBarBorder => isDark
      ? CupertinoColors.white.withValues(alpha: 0.1)
      : CupertinoColors.black.withValues(alpha: 0.08);

  // ── Switch styling ──────────────────────────
  Color get switchActiveThumb => const Color(0xFF3498DB);
  Color get switchActiveTrack =>
      const Color(0xFF3498DB).withValues(alpha: 0.35);
  Color get switchInactiveThumb => isDark
      ? CupertinoColors.white.withValues(alpha: 0.5)
      : const Color(0xFFBDBDBD);
  Color get switchInactiveTrack => isDark
      ? CupertinoColors.white.withValues(alpha: 0.1)
      : const Color(0xFFE0E0E0);

  // ── Shadows ─────────────────────────────────
  Color get shadow => isDark
      ? CupertinoColors.black.withValues(alpha: 0.2)
      : CupertinoColors.black.withValues(alpha: 0.06);

  // ── Orb decorations (background accents) ────
  Color orbAlpha(Color color, double darkAlpha) => isDark
      ? color.withValues(alpha: darkAlpha)
      : color.withValues(alpha: darkAlpha * 0.4);

  // ── Foreground color for AppBar icons/text ──
  Color get appBarForeground =>
      isDark ? CupertinoColors.white : const Color(0xFF1A1D2E);

  // ── Snackbar styling ────────────────────────
  Color get snackBarBg =>
      isDark ? const Color(0xFF1A2340) : const Color(0xFF323232);

  // ── Loading indicator ─────────────────────
  Color get loadingIndicator =>
      isDark ? const Color(0xB3FFFFFF) : const Color(0xFF4A4E5E);

  // ── Semantic colors ───────────────────────
  Color get statusInfo => const Color(0xFF3498DB);
  Color get statusSuccess => const Color(0xFF27AE60);
  Color get statusWarning => const Color(0xFFF39C12);
  Color get statusDanger => const Color(0xFFE74C3C);
  Color get statusNeutral =>
      isDark ? const Color(0x8AFFFFFF) : CupertinoColors.systemGrey;
  Color get favorite => const Color(0xFFFF5252);

  // ── Hero / gradient headers (text on accent bg is always white) ──
  static const Color onAccent = CupertinoColors.white;
  static final Color onAccentSecondary = CupertinoColors.white.withValues(
    alpha: 0.82,
  );

  // ── App accent colors ────────────────────
  /// Primary brand accent (deep railway blue) — slightly brighter in dark mode.
  Color get accent =>
      isDark ? const Color(0xFF1976D2) : const Color(0xFF0D47A1);

  /// Secondary brand accent (vibrant orange) — slightly brighter in dark mode.
  Color get secondaryAccent =>
      isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800);

  // ── Transport screen accents ────────────
  Color get trainAccent =>
      isDark ? const Color(0xFF1E88E5) : const Color(0xFF1565C0);
  Color get busAccent =>
      isDark ? const Color(0xFF43A047) : const Color(0xFF2E7D32);
  Color get metroAccent =>
      isDark ? const Color(0xFF29B6F6) : const Color(0xFF006BB6);
  Color get metroAccentLight =>
      isDark ? const Color(0xFF81D4FA) : const Color(0xFF4FC3F7);
  Color get localTrainAccent =>
      isDark ? const Color(0xFFFF8A50) : const Color(0xFFE65100);
  Color get localTrainAccentLight =>
      isDark ? const Color(0xFFFFAB91) : const Color(0xFFFF8A50);

  // ── Route marker colors ─────────────────
  Color get originMarker =>
      isDark ? const Color(0xFF42A5F5) : const Color(0xFF1A73E8);
  Color get destMarker =>
      isDark ? const Color(0xFFEF5350) : const Color(0xFFD93025);

  // ── Overlay / scrim ───────────────────────
  Color get scrim => isDark
      ? const Color(0xFF0A0E21).withValues(alpha: 0.92)
      : CupertinoColors.black.withValues(alpha: 0.45);
}
