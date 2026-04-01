import 'package:flutter/cupertino.dart';

class PulsingPositionMarker extends StatefulWidget {
  const PulsingPositionMarker({super.key});

  @override
  State<PulsingPositionMarker> createState() => _PulsingPositionMarkerState();
}

class _PulsingPositionMarkerState extends State<PulsingPositionMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.5,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 44 * _animation.value,
              height: 44 * _animation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF1A73E8,
                ).withValues(alpha: 0.15 * _animation.value),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1565C0),
                border: Border.all(color: CupertinoColors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
