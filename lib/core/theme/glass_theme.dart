import 'package:flutter/material.dart';

/// Centralized glass-morphism color system that adapts to light/dark mode.
///
/// Usage: `final g = GlassColors.of(context);`
/// Then use `g.bg`, `g.cardFill`, `g.text`, `g.textSecondary`, etc.
class GlassColors {
  final Brightness brightness;

  const GlassColors._(this.brightness);

  factory GlassColors.of(BuildContext context) {
    return GlassColors._(Theme.of(context).brightness);
  }

  bool get isDark => brightness == Brightness.dark;

  // ── Background ──────────────────────────────
  Color get bg => isDark ? const Color(0xFF0A0E21) : const Color(0xFFF2F4F8);

  /// Background gradient colors for full-screen backgrounds.
  List<Color> get bgGradient => isDark
      ? const [Color(0xFF0A0E21), Color(0xFF0D1B3E), Color(0xFF1A0A2E), Color(0xFF0A1628)]
      : const [Color(0xFFF2F4F8), Color(0xFFE8EDF5), Color(0xFFF0EBF5), Color(0xFFEBF0F5)];

  // ── Surface / Card fills ────────────────────
  Color cardFill([double alpha = 0.07]) =>
      isDark ? Colors.white.withValues(alpha: alpha) : Colors.white.withValues(alpha: 0.65 + alpha);

  Color cardFillSolid([double alpha = 0.07]) =>
      isDark ? Colors.white.withValues(alpha: alpha) : const Color(0xFFFFFFFF).withValues(alpha: 0.72);

  // ── Borders ─────────────────────────────────
  Color border([double alpha = 0.12]) =>
      isDark ? Colors.white.withValues(alpha: alpha) : Colors.black.withValues(alpha: alpha * 0.7);

  // ── Text ────────────────────────────────────
  Color get text => isDark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF1A1D2E);

  Color get textSecondary =>
      isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF5A5E6E);

  Color get textTertiary =>
      isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF8A8E9E);

  Color get textHint =>
      isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFAAAEB8);

  /// Custom text alpha — maps dark-mode white alpha to appropriate light equivalent.
  Color textAlpha(double darkAlpha) {
    if (isDark) return Colors.white.withValues(alpha: darkAlpha);
    // Map alpha to light-mode opacity: higher dark alpha → more opaque dark text
    if (darkAlpha >= 0.85) return const Color(0xFF1A1D2E);
    if (darkAlpha >= 0.7) return const Color(0xFF3A3E4E);
    if (darkAlpha >= 0.5) return const Color(0xFF5A5E6E);
    if (darkAlpha >= 0.35) return const Color(0xFF7A7E8E);
    return const Color(0xFFAAAEB8);
  }

  // ── Icon colors ─────────────────────────────
  Color get icon => isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF4A4E5E);

  Color iconAlpha(double darkAlpha) => textAlpha(darkAlpha);

  // ── Dividers ────────────────────────────────
  Color get divider =>
      isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06);

  // ── Dropdown / popup background ─────────────
  Color get dropdownBg => isDark ? const Color(0xFF1A2340) : const Color(0xFFF5F7FB);

  // ── Input fields ────────────────────────────
  Color get inputFill =>
      isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.8);

  Color get inputBorder =>
      isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12);

  Color get inputFocusBorder =>
      isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3);

  // ── AppBar glass ────────────────────────────
  Color get appBarBg =>
      isDark ? const Color(0xFF0A0E21).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85);

  Color get appBarBorder =>
      isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08);

  // ── Bottom bar ──────────────────────────────
  Color get bottomBarBg =>
      isDark ? const Color(0xFF0A0E21).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9);

  Color get bottomBarBorder =>
      isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08);

  // ── Switch styling ──────────────────────────
  Color get switchActiveThumb => const Color(0xFF3498DB);
  Color get switchActiveTrack => const Color(0xFF3498DB).withValues(alpha: 0.35);
  Color get switchInactiveThumb =>
      isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade400;
  Color get switchInactiveTrack =>
      isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300;

  // ── Shadows ─────────────────────────────────
  Color get shadow =>
      isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.06);

  // ── Orb decorations (background accents) ────
  Color orbAlpha(Color color, double darkAlpha) =>
      isDark ? color.withValues(alpha: darkAlpha) : color.withValues(alpha: darkAlpha * 0.4);

  // ── Foreground color for AppBar icons/text ──
  Color get appBarForeground => isDark ? Colors.white : const Color(0xFF1A1D2E);

  // ── Snackbar styling ────────────────────────
  Color get snackBarBg => isDark ? const Color(0xFF1A2340) : const Color(0xFF323232);
}
