import 'package:flutter/cupertino.dart';
import 'package:travel_companion/data/models/transport_type.dart';

class HomeJourneyTypeBadge extends StatelessWidget {
  const HomeJourneyTypeBadge({
    super.key,
    required this.transportType,
    this.vehicleNumber,
  });

  final TransportType transportType;
  final String? vehicleNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: transportType.color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: transportType.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(transportType.icon, size: 12, color: transportType.color),
          if (_hasVehicleNumber) ...[
            const SizedBox(width: 4),
            Text(
              vehicleNumber!,
              style: TextStyle(
                color: transportType.color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasVehicleNumber =>
      vehicleNumber != null && vehicleNumber!.trim().isNotEmpty;
}
