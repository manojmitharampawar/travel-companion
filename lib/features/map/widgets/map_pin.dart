import 'package:flutter/cupertino.dart';
import 'package:travel_companion/features/map/widgets/pin_tail_painter.dart';

class MapPin extends StatelessWidget {
  const MapPin({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: CupertinoColors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            CupertinoIcons.location_solid,
            color: CupertinoColors.white,
            size: 20,
          ),
        ),
        CustomPaint(
          size: const Size(14, 10),
          painter: PinTailPainter(color: color),
        ),
        Container(
          width: 16,
          height: 6,
          decoration: BoxDecoration(
            color: CupertinoColors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}
