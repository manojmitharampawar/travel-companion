import 'package:dio/dio.dart';
import 'package:travel_companion/data/models/station.dart';

class MetroStationApi {
  final _dio = Dio();

  /// Search metro stations from external APIs
  /// Returns list of stations from the API
  Future<List<Station>> searchMetroStations(String query, String? city) async {
    try {
      // Try searching from a metro/transit API
      // Using a generic transit API endpoint
      final response = await _dio.get(
        'https://api.transitapp.com/v3/public/stations',
        queryParameters: <String, dynamic>{'query': query, 'city': ?city},
        options: Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data['stations'] is List) {
          return (data['stations'] as List)
              .whereType<Map<String, dynamic>>()
              .map((station) {
                return Station(
                  id: 0,
                  code: (station['id'] as String?) ?? '',
                  name: (station['name'] as String?) ?? '',
                  latitude:
                      double.tryParse(station['latitude']?.toString() ?? '') ??
                      0.0,
                  longitude:
                      double.tryParse(station['longitude']?.toString() ?? '') ??
                      0.0,
                  zone: station['line'] as String?,
                  stationType: 'metro',
                );
              })
              .toList();
        }
      }
      return [];
    } catch (e) {
      // Fall back to empty list if API fails
      return [];
    }
  }

  /// Get metro lines from the area/city
  Future<List<String>> getMetroLines(String? city) async {
    try {
      final response = await _dio.get(
        'https://api.transitapp.com/v3/public/lines',
        queryParameters: <String, dynamic>{'city': ?city},
        options: Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data['lines'] is List) {
          return (data['lines'] as List)
              .whereType<Map<String, dynamic>>()
              .map((line) => line['name'] as String? ?? '')
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Search local train stations
  Future<List<Station>> searchLocalTrainStations(
    String query,
    String? city,
  ) async {
    try {
      final response = await _dio.get(
        'https://api.transitapp.com/v3/public/stations',
        queryParameters: <String, dynamic>{
          'query': query,
          'type': 'local_train',
          'city': ?city,
        },
        options: Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data['stations'] is List) {
          return (data['stations'] as List)
              .whereType<Map<String, dynamic>>()
              .map((station) {
                return Station(
                  id: 0,
                  code: (station['id'] as String?) ?? '',
                  name: (station['name'] as String?) ?? '',
                  latitude:
                      double.tryParse(station['latitude']?.toString() ?? '') ??
                      0.0,
                  longitude:
                      double.tryParse(station['longitude']?.toString() ?? '') ??
                      0.0,
                  zone: station['line'] as String?,
                  stationType: 'local_train',
                );
              })
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
