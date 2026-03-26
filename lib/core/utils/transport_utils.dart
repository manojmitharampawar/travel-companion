import 'package:travel_companion/data/models/transport_type.dart';

/// Thin delegation wrapper kept for backwards compatibility.
/// Prefer calling extension methods directly:
///   `type.speedLabel`, `type.vehicleLabel`, `type.vehicleNameLabel`, `type.hasReservation`
class TransportUtils {
  TransportUtils._();

  static String speedLabel(TransportType type) => type.speedLabel;
  static String vehicleLabel(TransportType type) => type.vehicleLabel;
  static String vehicleNameLabel(TransportType type) => type.vehicleNameLabel;
  static bool hasReservation(TransportType type) => type.hasReservation;
}
