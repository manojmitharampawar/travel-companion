import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/features/journey/widgets/tile_data.dart';

class GlassInfoTile extends StatelessWidget {
  final TileData data;
  final Color accentColor;

  const GlassInfoTile({
    super.key,
    required this.data,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final width = (MediaQuery.sizeOf(context).width - 48) / 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: g.cardFill(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: g.border(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(data.icon, size: 13, color: accentColor),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: g.textAlpha(0.5),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: g.textAlpha(0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
