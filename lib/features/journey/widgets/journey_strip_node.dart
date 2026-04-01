import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';

class JourneyStripNode extends StatelessWidget {
  final TrainRouteStop stop;
  final bool isPassed;
  final bool isNext;
  final bool isFirst;
  final bool isLast;
  final Color accentColor;

  const JourneyStripNode({
    super.key,
    required this.stop,
    required this.isPassed,
    required this.isNext,
    required this.isFirst,
    required this.isLast,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final orangeAccent = g.statusWarning;
    final dotColor = isNext
        ? orangeAccent
        : isPassed
        ? CupertinoColors.white.withValues(alpha: 0.25)
        : isFirst
        ? g.statusSuccess
        : isLast
        ? g.statusDanger
        : accentColor.withValues(alpha: 0.6);

    final dotSize = isNext || isFirst || isLast ? 12.0 : 8.0;

    final labelColor = isNext
        ? orangeAccent
        : isPassed
        ? CupertinoColors.white.withValues(alpha: 0.3)
        : isFirst || isLast
        ? CupertinoColors.white.withValues(alpha: 0.9)
        : CupertinoColors.white.withValues(alpha: 0.5);

    return SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isFirst)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isPassed
                        ? CupertinoColors.white.withValues(alpha: 0.15)
                        : accentColor.withValues(alpha: 0.2),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  border: (isNext || isFirst || isLast)
                      ? Border.all(
                          color: CupertinoColors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        )
                      : null,
                  boxShadow: isNext
                      ? [
                          BoxShadow(
                            color: orangeAccent.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isPassed
                        ? CupertinoColors.white.withValues(alpha: 0.15)
                        : accentColor.withValues(alpha: 0.2),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            stop.stationCode,
            style: TextStyle(
              fontSize: isNext ? 11 : 10,
              fontWeight: isNext || isFirst || isLast
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: labelColor,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          if (isNext)
            Text(
              'Next',
              style: TextStyle(
                fontSize: 9,
                color: orangeAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
