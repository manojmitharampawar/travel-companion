import 'package:equatable/equatable.dart';
import 'dart:ui';

/// Metro line definition with city, name, code, and color.
class MetroLine extends Equatable {
  final int id;
  final String city;
  final String lineName;
  final String? lineCode;
  final String? lineColorHex; // e.g., "#0C60CA"
  final String? startStationCode;
  final String? endStationCode;

  const MetroLine({
    required this.id,
    required this.city,
    required this.lineName,
    this.lineCode,
    this.lineColorHex,
    this.startStationCode,
    this.endStationCode,
  });

  /// Parse color hex string to Flutter Color.
  /// Returns a default color if hex is invalid.
  Color get color {
    if (lineColorHex == null || lineColorHex!.isEmpty) {
      return const Color(0xFF006BB6); // Default blue
    }
    try {
      return Color(int.parse(lineColorHex!.replaceFirst('#', '0xff')));
    } catch (_) {
      return const Color(0xFF006BB6);
    }
  }

  /// Display name: "[City] [Line Name]"
  String get displayName => '$city $lineName';

  factory MetroLine.fromMap(Map<String, dynamic> map) {
    return MetroLine(
      id: map['id'] as int,
      city: map['city'] as String,
      lineName: map['line_name'] as String,
      lineCode: map['line_code'] as String?,
      lineColorHex: map['line_color'] as String?,
      startStationCode: map['start_station_code'] as String?,
      endStationCode: map['end_station_code'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'city': city,
      'line_name': lineName,
      'line_code': lineCode,
      'line_color': lineColorHex,
      'start_station_code': startStationCode,
      'end_station_code': endStationCode,
    };
  }

  @override
  List<Object?> get props => [id, city, lineName, lineCode, lineColorHex];
}
