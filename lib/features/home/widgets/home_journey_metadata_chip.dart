import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/ui/glass/glass_panel.dart';

class HomeJourneyMetadataChip extends StatelessWidget {
  const HomeJourneyMetadataChip({
    super.key,
    required this.icon,
    required this.label,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String label;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final colors = GlassColors.of(context);
    final accentColor = isHighlighted
        ? colors.statusWarning
        : colors.textSecondary;

    return GlassPanel(
      blurSigma: 10,
      borderRadius: 8,
      fillOpacity: isHighlighted ? 0.12 : 0.06,
      borderColor: isHighlighted
          ? colors.statusWarning.withValues(alpha: 0.25)
          : colors.border(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: accentColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
