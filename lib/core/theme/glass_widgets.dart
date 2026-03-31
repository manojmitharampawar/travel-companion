import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

// ═══════════════════════════════════════════════════
// Glassmorphism Design System
// ═══════════════════════════════════════════════════

/// Glassmorphism constants.
class GlassConstants {
  GlassConstants._();

  static const double blurAmount = 20.0;
  static const double cardRadius = 20.0;
  static const double smallRadius = 14.0;
  static const double chipRadius = 24.0;
  static const double borderWidth = 1.2;
  static const double cardOpacity = 0.12;
  static const double darkCardOpacity = 0.18;
  static const double borderOpacity = 0.2;

  // Gradient mesh colors for backgrounds
  static const Color meshBlue = Color(0xFF0D47A1);
  static const Color meshPurple = Color(0xFF6A1B9A);
  static const Color meshCyan = Color(0xFF00BCD4);
  static const Color meshOrange = Color(0xFFFF9800);
  static const Color meshPink = Color(0xFFE91E63);
  static const Color meshTeal = Color(0xFF009688);
}

// ─────────────────────────────────────────────
// 1. GlassBackground — full-screen gradient mesh
// ─────────────────────────────────────────────

/// A vibrant gradient mesh background that sits behind glass panels.
class GlassBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const GlassBackground({
    super.key,
    required this.child,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final bgColors = colors ??
        (isDark
            ? [
                const Color(0xFF0A0E21),
                const Color(0xFF0D1B3E),
                const Color(0xFF1A0A2E),
                const Color(0xFF0A1628),
              ]
            : [
                const Color(0xFFE8EAF6),
                const Color(0xFFE0F7FA),
                const Color(0xFFF3E5F5),
                const Color(0xFFE8EAF6),
              ]);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bgColors,
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// A vibrant gradient mesh with floating orbs.
class GlassMeshBackground extends StatelessWidget {
  final Widget child;
  final Color? primaryColor;

  const GlassMeshBackground({
    super.key,
    required this.child,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = primaryColor ?? GlassConstants.meshBlue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = isDark ? const Color(0xFF0A0E21) : const Color(0xFFF0F2F8);

    return Container(
      color: baseBg,
      child: Stack(
        children: [
          // Floating gradient orbs
          Positioned(
            top: -60,
            right: -40,
            child: _GlowOrb(color: accent, size: 220),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _GlowOrb(color: GlassConstants.meshPurple, size: 180),
          ),
          Positioned(
            top: 300,
            right: -30,
            child: _GlowOrb(color: GlassConstants.meshCyan, size: 140),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 2. GlassCard — frosted glass panel
// ─────────────────────────────────────────────

/// A frosted glass card with blur, semi-transparent background, and light border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? tintColor;
  final double? opacity;
  final double? blur;
  final VoidCallback? onTap;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius,
    this.tintColor,
    this.opacity,
    this.blur,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? GlassConstants.cardRadius;
    final bgColor = tintColor ??
        (isDark ? Colors.white : Colors.white);
    final bgOpacity = opacity ??
        (isDark ? GlassConstants.darkCardOpacity : 0.65);
    final blurAmt = blur ?? GlassConstants.blurAmount;

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmt, sigmaY: blurAmt),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: bgOpacity),
            borderRadius: BorderRadius.circular(radius),
            border: border ??
                Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: GlassConstants.borderOpacity)
                      : Colors.black.withValues(alpha: 0.08),
                  width: GlassConstants.borderWidth,
                ),
          ),
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }

    return Padding(
      padding: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: content,
    );
  }
}

// ─────────────────────────────────────────────
// 3. GlassSectionCard — GlassCard with header
// ─────────────────────────────────────────────

/// A glass card with a titled section header, replacing FormSectionCard.
class GlassSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  const GlassSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.children,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassSectionTitle(title: title, icon: icon, color: accentColor),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _GlassSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _GlassSectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 4. GlassButton — frosted action button
// ─────────────────────────────────────────────

class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color accentColor;
  final bool isLoading;
  final bool filled;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    required this.accentColor,
    this.isLoading = false,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: filled
                    ? LinearGradient(
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.8),
                        ],
                      )
                    : null,
                color: filled ? null : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: filled
                      ? Colors.white.withValues(alpha: 0.25)
                      : accentColor.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  else if (icon != null)
                    Icon(icon, size: 22, color: Colors.white),
                  if (icon != null || isLoading) const SizedBox(width: 10),
                  Text(
                    isLoading ? 'Saving...' : label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: filled ? Colors.white : accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 5. GlassChip — tag / info chip
// ─────────────────────────────────────────────

class GlassChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color? color;
  final bool highlight;

  const GlassChip({
    super.key,
    this.icon,
    required this.label,
    this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = color ?? (isDark ? Colors.white70 : Colors.black54);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? chipColor.withValues(alpha: 0.15)
            : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(GlassConstants.chipRadius),
        border: Border.all(
          color: highlight
              ? chipColor.withValues(alpha: 0.3)
              : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: chipColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 6. GlassAppBarHero — gradient header with orbs
// ─────────────────────────────────────────────

class GlassAppBarHero extends StatelessWidget {
  final Color primaryColor;
  final Color? secondaryColor;
  final IconData icon;
  final String title;
  final String subtitle;

  const GlassAppBarHero({
    super.key,
    required this.primaryColor,
    this.secondaryColor,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryColor ?? primaryColor.withValues(alpha: 0.7);
    final topPad = MediaQuery.paddingOf(context).top + kToolbarHeight + 4;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondary],
        ),
      ),
      child: Stack(
        children: [
          // Decorative orbs
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -10,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(24, topPad, 24, 24),
            child: Row(
              children: [
                // Glassmorphic icon container
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(icon, size: 32, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 7. GlassStepIndicator
// ─────────────────────────────────────────────

class GlassStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> labels;
  final Color accent;

  const GlassStepIndicator({
    super.key,
    required this.currentStep,
    required this.labels,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: List.generate(labels.length, (i) {
                final isActive = i <= currentStep;
                final isCurrent = i == currentStep;
                final isCompleted = i < currentStep;
                return Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isActive
                              ? accent.withValues(alpha: isCurrent ? 1.0 : 0.7)
                              : GlassColors.of(context).cardFill(0.08),
                          shape: BoxShape.circle,
                          border: isCurrent
                              ? Border.all(
                                  color: GlassColors.of(context).border(0.4),
                                  width: 2,
                                )
                              : null,
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? Colors.white
                                        : GlassColors.of(context).textTertiary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? GlassColors.of(context).text
                                : GlassColors.of(context).textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 8. GlassTrainCard — schedule result card
// ─────────────────────────────────────────────

class GlassTrainCard extends StatelessWidget {
  final String formattedDeparture;
  final String formattedArrival;
  final String travelDuration;
  final int stopsCount;
  final String? trainTypeLabel;
  final bool isFast;
  final Color lineColor;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accent;

  const GlassTrainCard({
    super.key,
    required this.formattedDeparture,
    required this.formattedArrival,
    required this.travelDuration,
    required this.stopsCount,
    this.trainTypeLabel,
    this.isFast = false,
    required this.lineColor,
    required this.isSelected,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.18)
                    : g.cardFill(),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? accent.withValues(alpha: 0.6)
                      : g.border(),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.2),
                          blurRadius: 12,
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Departure
                  _TimeColumn(
                    time: formattedDeparture,
                    label: 'DEP',
                    isSelected: isSelected,
                    accent: accent,
                  ),
                  const SizedBox(width: 14),
                  // Route line
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      lineColor.withValues(alpha: 0.6),
                                      lineColor,
                                      lineColor.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: g.cardFill(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                travelDuration,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: g.textAlpha(0.8),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      lineColor.withValues(alpha: 0.6),
                                      lineColor,
                                      lineColor.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: 10,
                                color: g.textTertiary),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (trainTypeLabel != null)
                              _GlassTypeBadge(
                                label: trainTypeLabel!,
                                isFast: isFast,
                                color: lineColor,
                              ),
                            if (trainTypeLabel != null)
                              const SizedBox(width: 8),
                            Text(
                              '$stopsCount stops',
                              style: TextStyle(
                                fontSize: 10,
                                color: g.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Arrival
                  _TimeColumn(
                    time: formattedArrival,
                    label: 'ARR',
                    isSelected: isSelected,
                    accent: accent,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle,
                        color: accent, size: 22),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final String time;
  final String label;
  final bool isSelected;
  final Color accent;

  const _TimeColumn({
    required this.time,
    required this.label,
    required this.isSelected,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Column(
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isSelected ? accent : g.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: g.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _GlassTypeBadge extends StatelessWidget {
  final String label;
  final bool isFast;
  final Color color;

  const _GlassTypeBadge({
    required this.label,
    required this.isFast,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFast) ...[
            Icon(Icons.bolt, size: 10, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 9. GlassDropdown — styled dropdown
// ─────────────────────────────────────────────

class GlassDropdownField<T> extends StatelessWidget {
  final String label;
  final IconData? prefixIcon;
  final Color? prefixIconColor;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;
  final double menuMaxHeight;

  const GlassDropdownField({
    super.key,
    required this.label,
    this.prefixIcon,
    this.prefixIconColor,
    this.value,
    required this.items,
    this.onChanged,
    this.isExpanded = true,
    this.menuMaxHeight = 300,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: prefixIconColor)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: g.inputFocusBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: g.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: g.inputFocusBorder, width: 2),
        ),
        filled: true,
        fillColor: g.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: g.textSecondary),
      ),
      dropdownColor: g.dropdownBg,
      isExpanded: isExpanded,
      menuMaxHeight: menuMaxHeight,
      borderRadius: BorderRadius.circular(14),
      style: TextStyle(color: g.text, fontSize: 14),
      iconEnabledColor: g.textSecondary,
      items: items,
      onChanged: onChanged,
    );
  }
}
