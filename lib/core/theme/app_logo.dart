import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Travel Companion app logo — a stylized shield/compass-pin with a
/// train silhouette, rendered entirely with CustomPaint.
///
/// Usage:
///   AppLogo(size: 48)
///   AppLogo(size: 64, showLabel: true)
class AppLogo extends StatelessWidget {
  final double size;
  final bool showLabel;
  final Color? accentOverride;

  const AppLogo({
    super.key,
    this.size = 48,
    this.showLabel = false,
    this.accentOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _LogoPainter(accentOverride: accentOverride),
        ),
        if (showLabel) ...[
          SizedBox(height: size * 0.12),
          Text(
            'Travel Companion',
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          Text(
            'Never miss your stop',
            style: TextStyle(
              fontSize: size * 0.12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.45),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color? accentOverride;

  const _LogoPainter({this.accentOverride});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s / 2, s / 2);

    // ─── 1. Outer glow ───────────────────────
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..color = (accentOverride ?? const Color(0xFF3498DB)).withValues(alpha: 0.25);
    canvas.drawCircle(center, s * 0.38, glowPaint);

    // ─── 2. Main shield / circle ─────────────
    final accent = accentOverride ?? const Color(0xFF3498DB);
    final gradPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(s * 0.2, 0),
        Offset(s * 0.8, s),
        [accent, Color.lerp(accent, const Color(0xFF0A0E21), 0.5)!],
      );
    canvas.drawCircle(center, s * 0.4, gradPaint);

    // Glass ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.015
      ..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawCircle(center, s * 0.4, ringPaint);

    // Inner glass sheen (top-left highlight arc)
    final sheenPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025
      ..shader = ui.Gradient.sweep(
        center,
        [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.0),
        ],
        [0.0, 0.15, 0.3],
      );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: s * 0.35),
      -math.pi * 0.7,
      math.pi * 0.5,
      false,
      sheenPaint,
    );

    // ─── 3. Location pin shape (inner) ───────
    final pinPath = Path();
    final pinCx = s * 0.5;
    final pinTop = s * 0.2;
    final pinR = s * 0.16;

    // Pin circle
    pinPath.addOval(Rect.fromCircle(
      center: Offset(pinCx, pinTop + pinR),
      radius: pinR,
    ));

    // Pin tail
    pinPath.moveTo(pinCx - pinR * 0.65, pinTop + pinR + pinR * 0.5);
    pinPath.quadraticBezierTo(
      pinCx,
      pinTop + pinR * 3.6,
      pinCx + pinR * 0.65,
      pinTop + pinR + pinR * 0.5,
    );
    pinPath.close();

    final pinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95);
    canvas.drawPath(pinPath, pinPaint);

    // Inner circle of pin (accent color dot)
    final dotPaint = Paint()..color = accent;
    canvas.drawCircle(
      Offset(pinCx, pinTop + pinR),
      pinR * 0.5,
      dotPaint,
    );

    // ─── 4. Compass arrows (N/S tiny marks) ──
    final compassPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = s * 0.012
      ..strokeCap = StrokeCap.round;

    // North tick
    canvas.drawLine(
      Offset(s * 0.5, s * 0.08),
      Offset(s * 0.5, s * 0.13),
      compassPaint,
    );
    // South tick
    canvas.drawLine(
      Offset(s * 0.5, s * 0.87),
      Offset(s * 0.5, s * 0.92),
      compassPaint,
    );
    // East tick
    canvas.drawLine(
      Offset(s * 0.87, s * 0.5),
      Offset(s * 0.92, s * 0.5),
      compassPaint,
    );
    // West tick
    canvas.drawLine(
      Offset(s * 0.08, s * 0.5),
      Offset(s * 0.13, s * 0.5),
      compassPaint,
    );

    // ─── 5. Subtle wave/track lines at bottom ─
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = s * 0.012
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final trackPath1 = Path();
    trackPath1.moveTo(s * 0.25, s * 0.72);
    trackPath1.quadraticBezierTo(s * 0.4, s * 0.67, s * 0.5, s * 0.72);
    trackPath1.quadraticBezierTo(s * 0.6, s * 0.77, s * 0.75, s * 0.72);
    canvas.drawPath(trackPath1, trackPaint);

    final trackPath2 = Path();
    trackPath2.moveTo(s * 0.3, s * 0.78);
    trackPath2.quadraticBezierTo(s * 0.43, s * 0.73, s * 0.5, s * 0.78);
    trackPath2.quadraticBezierTo(s * 0.57, s * 0.83, s * 0.7, s * 0.78);
    canvas.drawPath(trackPath2, trackPaint..color = Colors.white.withValues(alpha: 0.15));
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.accentOverride != accentOverride;
}
