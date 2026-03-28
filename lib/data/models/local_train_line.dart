import 'package:flutter/material.dart';

class LocalTrainLine {
  final int id;
  final String city;
  final String lineName;
  final String lineCode;
  final String? color;
  final String? startStation;
  final String? endStation;

  const LocalTrainLine({
    required this.id,
    required this.city,
    required this.lineName,
    required this.lineCode,
    this.color,
    this.startStation,
    this.endStation,
  });

  Color get lineColor {
    if (color == null || color!.isEmpty) return const Color(0xFFE65100);
    try {
      return Color(int.parse(color!.replaceFirst('#', '0xff')));
    } catch (_) {
      return const Color(0xFFE65100);
    }
  }

  factory LocalTrainLine.fromMap(Map<String, dynamic> map) => LocalTrainLine(
        id: map['id'] as int,
        city: map['city'] as String,
        lineName: map['line_name'] as String,
        lineCode: map['line_code'] as String,
        color: map['color'] as String?,
        startStation: map['start_station'] as String?,
        endStation: map['end_station'] as String?,
      );
}
