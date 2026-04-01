import 'package:flutter/cupertino.dart';

class GlassStatusChip extends StatelessWidget {
  final bool isCompleted;

  const GlassStatusChip({required this.isCompleted, super.key});

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? const Color(0xFF27AE60)
        : const Color(0xFFE74C3C);
    final text = isCompleted ? 'Completed' : 'Cancelled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
