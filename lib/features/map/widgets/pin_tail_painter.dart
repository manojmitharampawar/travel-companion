import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

class PinTailPainter extends CustomPainter {
  const PinTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      ui.Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(PinTailPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
