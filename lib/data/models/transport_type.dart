import 'package:flutter/cupertino.dart';

enum TransportType { train, bus, metro, localTrain }

extension TransportTypeExtension on TransportType {
  String get label {
    switch (this) {
      case TransportType.train:
        return 'Train';
      case TransportType.bus:
        return 'Bus';
      case TransportType.metro:
        return 'Metro';
      case TransportType.localTrain:
        return 'Local Train';
    }
  }

  IconData get icon {
    switch (this) {
      case TransportType.train:
        return CupertinoIcons.train_style_one;
      case TransportType.bus:
        return CupertinoIcons.bus;
      case TransportType.metro:
        return CupertinoIcons.tram_fill;
      case TransportType.localTrain:
        return CupertinoIcons.train_style_two;
    }
  }

  Color get color {
    switch (this) {
      case TransportType.train:
        return const Color(0xFF1565C0); // Railway blue
      case TransportType.bus:
        return const Color(0xFF2E7D32); // Green
      case TransportType.metro:
        return const Color(0xFF6A1B9A); // Purple
      case TransportType.localTrain:
        return const Color(0xFFE65100); // Deep orange
    }
  }

  String get dbValue {
    switch (this) {
      case TransportType.train:
        return 'train';
      case TransportType.bus:
        return 'bus';
      case TransportType.metro:
        return 'metro';
      case TransportType.localTrain:
        return 'local_train';
    }
  }

  static TransportType fromDbValue(String? value) {
    switch (value) {
      case 'bus':
        return TransportType.bus;
      case 'metro':
        return TransportType.metro;
      case 'local_train':
        return TransportType.localTrain;
      default:
        return TransportType.train;
    }
  }

  String get vehicleLabel {
    switch (this) {
      case TransportType.train:
        return 'Train Number';
      case TransportType.bus:
        return 'Route Number';
      case TransportType.metro:
        return 'Line Name';
      case TransportType.localTrain:
        return 'Line/Route';
    }
  }

  String get vehicleNameLabel {
    switch (this) {
      case TransportType.train:
        return 'Train Name';
      case TransportType.bus:
        return 'Bus Operator';
      case TransportType.metro:
        return 'Metro Line';
      case TransportType.localTrain:
        return 'Local Line';
    }
  }

  String get speedLabel {
    switch (this) {
      case TransportType.train:
        return 'Based on avg train speed (~55 km/h)';
      case TransportType.bus:
        return 'Based on avg bus speed (~30 km/h)';
      case TransportType.metro:
        return 'Based on avg metro speed (~35 km/h)';
      case TransportType.localTrain:
        return 'Based on avg local train speed (~40 km/h)';
    }
  }

  bool get hasReservation => this == TransportType.train;
}
