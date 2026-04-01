import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class ReschedulePickerTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const ReschedulePickerTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: g.dropdownBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: g.border(0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: g.textAlpha(0.6)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: g.textAlpha(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: g.text,
                    ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.pencil, size: 16, color: g.textAlpha(0.45)),
          ],
        ),
      ),
    );
  }
}
