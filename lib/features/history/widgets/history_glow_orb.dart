import 'package:flutter/cupertino.dart';

class HistoryGlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const HistoryGlowOrb({required this.color, required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.06),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
