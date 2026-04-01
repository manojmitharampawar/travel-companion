import 'package:equatable/equatable.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/data/models/transport_type.dart';

enum JourneyStatus { upcoming, active, completed, cancelled }

class Journey extends Equatable {
  final int? id;
  final TransportType transportType;
  final String? pnr;
  final String? vehicleNumber; // train number, bus route, metro line
  final String? vehicleName;
  final DateTime journeyDate;
  final String? boardingStationCode;
  final String? destinationStationCode;
  final double? originLatitude;
  final double? originLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String? originName;
  final String? destinationName;
  final String? travelClass;
  final String? berth;
  final JourneyStatus status;
  final DateTime createdAt;
  final bool isFavorite;
  final bool isQuickTrip;
  final int? repeatDays; // 7-bit bitmask: bit 0=Mon ... bit 6=Sun
  final String? scheduledTime; // HH:mm for repeat journeys

  // Populated from station lookups (not stored in DB)
  final String? boardingStationName;
  final String? destinationStationName;

  const Journey({
    this.id,
    this.transportType = TransportType.train,
    this.pnr,
    this.vehicleNumber,
    this.vehicleName,
    required this.journeyDate,
    this.boardingStationCode,
    this.destinationStationCode,
    this.originLatitude,
    this.originLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.originName,
    this.destinationName,
    this.travelClass,
    this.berth,
    this.status = JourneyStatus.upcoming,
    required this.createdAt,
    this.isFavorite = false,
    this.isQuickTrip = false,
    this.repeatDays,
    this.scheduledTime,
    this.boardingStationName,
    this.destinationStationName,
  });

  // Backward-compatible getters
  String get trainNumber => vehicleNumber ?? '';
  String? get trainName => vehicleName;

  factory Journey.fromMap(Map<String, dynamic> map) {
    return Journey(
      id: map['id'] as int?,
      transportType: TransportTypeExtension.fromDbValue(
        map['transport_type'] as String?,
      ),
      pnr: map['pnr'] as String?,
      vehicleNumber:
          map['vehicle_number'] as String? ?? map['train_number'] as String?,
      vehicleName:
          map['vehicle_name'] as String? ?? map['train_name'] as String?,
      journeyDate: DateTime.parse(map['journey_date'] as String),
      boardingStationCode: map['boarding_station_code'] as String?,
      destinationStationCode: map['destination_station_code'] as String?,
      originLatitude: (map['origin_latitude'] as num?)?.toDouble(),
      originLongitude: (map['origin_longitude'] as num?)?.toDouble(),
      destinationLatitude: (map['destination_latitude'] as num?)?.toDouble(),
      destinationLongitude: (map['destination_longitude'] as num?)?.toDouble(),
      originName: map['origin_name'] as String?,
      destinationName: map['destination_name'] as String?,
      travelClass: map['class'] as String?,
      berth: map['berth'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      isQuickTrip: (map['is_quick_trip'] as int?) == 1,
      repeatDays: map['repeat_days'] as int?,
      scheduledTime: map['scheduled_time'] as String?,
      status: JourneyStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'upcoming'),
        orElse: () => JourneyStatus.upcoming,
      ),
      createdAt: DateTime.parse(
        map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'transport_type': transportType.dbValue,
      'pnr': pnr,
      'vehicle_number': vehicleNumber,
      'vehicle_name': vehicleName,
      'journey_date': journeyDate.toIso8601String(),
      'boarding_station_code': boardingStationCode ?? '',
      'destination_station_code': destinationStationCode ?? '',
      'origin_latitude': originLatitude,
      'origin_longitude': originLongitude,
      'destination_latitude': destinationLatitude,
      'destination_longitude': destinationLongitude,
      'origin_name': originName,
      'destination_name': destinationName,
      'class': travelClass,
      'berth': berth,
      'is_favorite': isFavorite ? 1 : 0,
      'is_quick_trip': isQuickTrip ? 1 : 0,
      'repeat_days': repeatDays,
      'scheduled_time': scheduledTime,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Journey copyWith({
    int? id,
    TransportType? transportType,
    String? pnr,
    String? vehicleNumber,
    String? vehicleName,
    DateTime? journeyDate,
    String? boardingStationCode,
    String? destinationStationCode,
    double? originLatitude,
    double? originLongitude,
    double? destinationLatitude,
    double? destinationLongitude,
    String? originName,
    String? destinationName,
    String? travelClass,
    String? berth,
    JourneyStatus? status,
    DateTime? createdAt,
    bool? isFavorite,
    bool? isQuickTrip,
    int? repeatDays,
    String? scheduledTime,
    String? boardingStationName,
    String? destinationStationName,
  }) {
    return Journey(
      id: id ?? this.id,
      transportType: transportType ?? this.transportType,
      pnr: pnr ?? this.pnr,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleName: vehicleName ?? this.vehicleName,
      journeyDate: journeyDate ?? this.journeyDate,
      boardingStationCode: boardingStationCode ?? this.boardingStationCode,
      destinationStationCode:
          destinationStationCode ?? this.destinationStationCode,
      originLatitude: originLatitude ?? this.originLatitude,
      originLongitude: originLongitude ?? this.originLongitude,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      originName: originName ?? this.originName,
      destinationName: destinationName ?? this.destinationName,
      travelClass: travelClass ?? this.travelClass,
      berth: berth ?? this.berth,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isQuickTrip: isQuickTrip ?? this.isQuickTrip,
      repeatDays: repeatDays ?? this.repeatDays,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      boardingStationName: boardingStationName ?? this.boardingStationName,
      destinationStationName:
          destinationStationName ?? this.destinationStationName,
    );
  }

  bool get isToday => AppDateUtils.isToday(journeyDate);

  bool get isUpcoming => status == JourneyStatus.upcoming;
  bool get isActive => status == JourneyStatus.active;
  bool get isTrain => transportType == TransportType.train;
  bool get isBus => transportType == TransportType.bus;
  bool get isMetro => transportType == TransportType.metro;
  bool get isLocalTrain => transportType == TransportType.localTrain;

  bool get isRepeating => repeatDays != null && repeatDays! > 0;

  String get repeatDaysDisplay {
    if (repeatDays == null || repeatDays == 0) return '';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final active = <String>[];
    for (var i = 0; i < 7; i++) {
      if (repeatDays! & (1 << i) != 0) active.add(days[i]);
    }
    if (active.length == 7) return 'Daily';
    if (active.length == 5 &&
        !(repeatDays! & (1 << 5) != 0) &&
        !(repeatDays! & (1 << 6) != 0)) {
      return 'Weekdays';
    }
    return active.join(', ');
  }

  /// Effective origin display name
  String get effectiveOriginName =>
      boardingStationName ?? originName ?? boardingStationCode ?? 'Origin';

  /// Effective destination display name
  String get effectiveDestinationName =>
      destinationStationName ??
      destinationName ??
      destinationStationCode ??
      'Destination';

  @override
  List<Object?> get props => [
    id,
    transportType,
    pnr,
    vehicleNumber,
    vehicleName,
    journeyDate,
    boardingStationCode,
    destinationStationCode,
    originLatitude,
    originLongitude,
    destinationLatitude,
    destinationLongitude,
    originName,
    destinationName,
    travelClass,
    berth,
    status,
    createdAt,
    isFavorite,
    isQuickTrip,
    repeatDays,
    scheduledTime,
  ];
}
