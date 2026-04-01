import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/transport_type.dart';

class QuickTripTransportSelector extends StatelessWidget {
  final TransportType selected;
  final List<TransportType> types;
  final ValueChanged<TransportType> onChanged;

  const QuickTripTransportSelector({
    super.key,
    required this.selected,
    required this.types,
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
            children: types.map((type) {
              final isSelected = type == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                          size: 20,
                          color: isSelected ? type.color : g.textAlpha(0.4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? type.color : g.textAlpha(0.4),
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
