import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

import 'glass_constants.dart';

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
    final bgColor = tintColor ?? Colors.white;
    final bgOpacity = opacity ?? (isDark ? GlassConstants.darkCardOpacity : 0.65);
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
            : (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(GlassConstants.chipRadius),
        border: Border.all(
          color: highlight
              ? chipColor.withValues(alpha: 0.3)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08)),
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
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: prefixIconColor) : null,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
