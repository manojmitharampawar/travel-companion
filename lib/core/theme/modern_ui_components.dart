import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/transport_type.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const ModernCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? g.cardFill(0.08),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor ?? g.border(0.12)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class TransportBadge extends StatelessWidget {
  final TransportType transportType;
  final String label;

  const TransportBadge({
    super.key,
    required this.transportType,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: transportType.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: transportType.color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: transportType.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor ?? g.icon),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: g.textSecondary, fontSize: 13)),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: g.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? accentColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final accent = accentColor ?? g.accent;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: TextStyle(
            color: g.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class JourneyHeader extends StatelessWidget {
  final TransportType transportType;
  final String title;
  final String subtitle;
  final VoidCallback? onBackPressed;

  const JourneyHeader({
    super.key,
    required this.transportType,
    required this.title,
    required this.subtitle,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            transportType.color,
            transportType.color.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBackPressed != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onBackPressed,
              child: const Icon(
                CupertinoIcons.back,
                color: CupertinoColors.white,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: CupertinoColors.white.withValues(alpha: 0.88),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class ModernInputField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final Widget? prefix;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const ModernInputField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.prefix,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return CupertinoTextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      placeholder: placeholder,
      prefix: prefix,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: g.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: g.inputBorder),
      ),
    );
  }
}

class ModernButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;

  const ModernButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return CupertinoButton(
      onPressed: isLoading ? null : onPressed,
      color: color ?? g.accent,
      borderRadius: BorderRadius.circular(12),
      child: isLoading
          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class StatusIndicator extends StatelessWidget {
  final String label;
  final Color color;

  const StatusIndicator({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class TextDivider extends StatelessWidget {
  final String text;

  const TextDivider({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: g.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(text, style: TextStyle(fontSize: 12, color: g.textHint)),
        ),
        Expanded(child: Container(height: 1, color: g.divider)),
      ],
    );
  }
}
