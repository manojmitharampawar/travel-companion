import 'package:dio/dio.dart';
import 'package:travel_companion/data/models/train_status.dart';

/// Service to fetch live train running status from Indian Railways.
///
/// Uses publicly available APIs for train status. In production,
/// you should register for the official Indian Railways API key.
///
/// Fallback: RailwayAPI.site or similar services.
class TrainStatusApi {
  final Dio _dio;

  TrainStatusApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  /// Fetch live running status for a train on a given date.
  /// Returns null if the API is unavailable or train not found.
  Future<TrainStatus?> getLiveStatus({
    required String trainNumber,
    required DateTime date,
  }) async {
    try {
      // Using a public railway API endpoint
      // In production, replace with official IRCTC/RailwayAPI key-based access
      final dateStr =
          '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';

      final response = await _dio.get(
        'https://rappid.in/apis/train.php',
        queryParameters: {
          'train_no': trainNumber,
          'date': dateStr,
        },
      );

      if (response.statusCode != 200 || response.data == null) return null;

      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      if (data['success'] != true) return null;

      return _parseTrainStatus(data, trainNumber);
    } on DioException {
      return null;
    } catch (e) {
      return null;
    }
  }

  TrainStatus? _parseTrainStatus(
    Map<String, dynamic> data,
    String trainNumber,
  ) {
    try {
      final trainName = data['train_name'] as String? ?? 'Train $trainNumber';
      final currentStation = data['current_station'] as String? ?? 'Unknown';
      final delay = data['delay'] as int? ?? 0;

      final stationList = data['route'] as List<dynamic>? ?? [];

      final stationStatuses = stationList.map<StationStatus>((s) {
        final station = s as Map<String, dynamic>;
        return StationStatus(
          stationCode: station['station_code'] as String? ?? '',
          stationName: station['station_name'] as String? ?? '',
          scheduledArrival: station['scheduled_arrival'] as String?,
          actualArrival: station['actual_arrival'] as String?,
          scheduledDeparture: station['scheduled_departure'] as String?,
          actualDeparture: station['actual_departure'] as String?,
          delayMinutes: station['delay'] as int? ?? 0,
          hasPassed: station['has_passed'] as bool? ?? false,
        );
      }).toList();

      return TrainStatus(
        trainNumber: trainNumber,
        trainName: trainName,
        currentStation: currentStation,
        delayMinutes: delay,
        lastUpdated: DateTime.now(),
        stationStatuses: stationStatuses,
      );
    } catch (e) {
      return null;
    }
  }

  /// Search trains between two stations
  Future<List<Map<String, dynamic>>> searchTrains({
    required String fromStation,
    required String toStation,
  }) async {
    try {
      final response = await _dio.get(
        'https://rappid.in/apis/train.php',
        queryParameters: {
          'from': fromStation,
          'to': toStation,
        },
      );

      if (response.statusCode != 200 || response.data == null) return [];

      final data = response.data;
      if (data is! Map<String, dynamic>) return [];
      if (data['trains'] is! List) return [];

      return (data['trains'] as List).map((t) {
        final train = t as Map<String, dynamic>;
        return {
          'train_number': train['train_number'] as String? ?? '',
          'train_name': train['train_name'] as String? ?? '',
          'from_station': train['from_station'] as String? ?? '',
          'to_station': train['to_station'] as String? ?? '',
          'departure': train['departure'] as String? ?? '',
          'arrival': train['arrival'] as String? ?? '',
          'duration': train['duration'] as String? ?? '',
          'running_days': train['running_days'] as String? ?? '',
        };
      }).toList();
    } on DioException {
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get train details by train number (name, route, schedule)
  Future<Map<String, dynamic>?> getTrainDetails(String trainNumber) async {
    try {
      final response = await _dio.get(
        'https://rappid.in/apis/train.php',
        queryParameters: {'train_no': trainNumber},
      );

      if (response.statusCode != 200 || response.data == null) return null;

      final data = response.data;
      if (data is! Map<String, dynamic>) return null;

      return {
        'train_number': data['train_number'] as String? ?? trainNumber,
        'train_name': data['train_name'] as String? ?? '',
        'from_station': data['from_station'] as String? ?? '',
        'to_station': data['to_station'] as String? ?? '',
        'route': data['route'] as List? ?? [],
      };
    } on DioException {
      return null;
    } catch (e) {
      return null;
    }
  }
}
