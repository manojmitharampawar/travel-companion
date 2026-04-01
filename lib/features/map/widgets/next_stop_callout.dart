import 'package:flutter/cupertino.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/features/map/widgets/callout_tail_painter.dart';

class NextStopCallout extends StatelessWidget {
  const NextStopCallout({super.key, required this.stop});

  final TrainRouteStop stop;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF57C00),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF57C00).withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                stop.stationCode,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              if (stop.timeDisplay.isNotEmpty)
                Text(
                  stop.timeDisplay,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        const CustomPaint(
          size: Size(10, 6),
          painter: CalloutTailPainter(color: Color(0xFFF57C00)),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF57C00),
            border: Border.all(color: CupertinoColors.white, width: 2),
          ),
        ),
      ],
    );
  }
}
