import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class JourneyStationTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final VoidCallback onTap;

  const JourneyStationTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: g.border(0.08))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: g.text,
                    ),
                    child: title,
                  ),
                  if (subtitle != null)
                    DefaultTextStyle(
                      style: TextStyle(fontSize: 12, color: g.textAlpha(0.6)),
                      child: subtitle!,
                    ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 12,
              color: g.textAlpha(0.4),
            ),
          ],
        ),
      ),
    );
  }
}
