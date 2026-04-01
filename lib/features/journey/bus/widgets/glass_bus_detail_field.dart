import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class GlassBusDetailField extends StatelessWidget {
  const GlassBusDetailField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.accentColor,
    required this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final Color accentColor;
  final ValueChanged<String> onChanged;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: g.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: g.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: g.inputBorder),
              ),
              child: CupertinoTextField(
                controller: controller,
                onChanged: onChanged,
                textCapitalization: textCapitalization,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                style: TextStyle(
                  color: g.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                placeholder: hintText,
                placeholderStyle: TextStyle(color: g.textHint, fontSize: 13),
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    icon,
                    size: 18,
                    color: accentColor.withValues(alpha: 0.9),
                  ),
                ),
                decoration: null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
