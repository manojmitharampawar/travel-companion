import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class JourneyStationLabel extends StatelessWidget {
  final String tag;
  final String name;
  final String code;
  final Color color;

  const JourneyStationLabel({
    super.key,
    required this.tag,
    required this.name,
    required this.code,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tag,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: g.textAlpha(0.9),
          ),
        ),
        if (code.isNotEmpty)
          Text(code, style: TextStyle(fontSize: 12, color: g.textAlpha(0.5))),
      ],
    );
  }
}
