import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/transport_type.dart';

class FullscreenMapTransportBadge extends StatelessWidget {
  const FullscreenMapTransportBadge({
    super.key,
    required this.transportType,
    required this.destination,
  });

  final TransportType transportType;
  final String destination;

  @override
  Widget build(BuildContext context) {
    final colors = GlassColors.of(context);
    final surface = colors.isDark
        ? const Color(0xFF0A0E21).withValues(alpha: 0.78)
        : colors.cardFillSolid(0.92);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: transportType.color.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(transportType.icon, size: 16, color: transportType.color),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  destination,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textAlpha(0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
