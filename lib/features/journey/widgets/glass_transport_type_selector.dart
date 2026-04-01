import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/transport_type.dart';

class GlassTransportTypeSelector extends StatelessWidget {
  final TransportType selected;
  final ValueChanged<TransportType> onChanged;

  const GlassTransportTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: g.cardFill(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: g.border(0.1)),
          ),
          child: Row(
            children: TransportType.values.map((type) {
              final isSelected = type == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? type.color.withValues(alpha: 0.2)
                          : const Color(0x00000000),
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: type.color.withValues(alpha: 0.4))
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type.icon,
                          size: 18,
                          color: isSelected ? type.color : g.textTertiary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? type.color : g.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
