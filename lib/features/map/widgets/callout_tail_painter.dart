import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

class CalloutTailPainter extends CustomPainter {
  const CalloutTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CalloutTailPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
