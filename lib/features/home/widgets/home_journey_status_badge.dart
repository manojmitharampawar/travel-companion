import 'package:flutter/cupertino.dart';
import 'package:travel_companion/data/models/journey.dart';

class HomeJourneyStatusBadge extends StatelessWidget {
  const HomeJourneyStatusBadge({super.key, required this.status});

  final JourneyStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, text) = _statusPresentation(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (Color, String) _statusPresentation(JourneyStatus value) {
    return switch (value) {
      JourneyStatus.upcoming => (const Color(0xFF3498DB), 'Upcoming'),
      JourneyStatus.active => (const Color(0xFF27AE60), 'Active'),
      JourneyStatus.completed => (const Color(0xFF7F8C8D), 'Done'),
      JourneyStatus.cancelled => (const Color(0xFFE74C3C), 'Cancelled'),
    };
  }
}
