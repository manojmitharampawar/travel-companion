import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:travel_companion/data/models/location_point.dart';

/// Thin wrapper around the Nominatim OpenStreetMap geocoding API.
/// No API key required; rate-limit: 1 req/sec.
class GeocodingService {
  GeocodingService._();

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'User-Agent': 'TravelCompanionApp/1.0 (contact@travelcompanion.app)',
        'Accept-Language': 'en',
      },
    ),
  );

  /// Forward geocoding — query → list of [LocationPoint].
  /// Restricted to India (`countrycodes=in`) for relevance.
  static Future<List<LocationPoint>> search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      dev.log('GeocodingService.search: querying "$query"', name: 'Geocoding');
      final resp = await _dio.get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 10,
          'countrycodes': 'in',
          'addressdetails': 1,
          'dedupe': 1,
        },
      );
      final data = resp.data ?? [];
      dev.log(
        'GeocodingService.search: got ${data.length} results',
        name: 'Geocoding',
      );
      return data.map((e) {
        final map = e as Map<String, dynamic>;
        final displayName = (map['display_name'] as String? ?? '');
        final shortName = displayName.split(',').first.trim();
        final parts = displayName.split(',');
        final addressSnippet = parts.length > 2
            ? '${parts[1].trim()}, ${parts[2].trim()}'
            : parts.length > 1
            ? parts[1].trim()
            : '';
        return LocationPoint(
          name: shortName,
          latitude: double.tryParse(map['lat'] as String? ?? '0') ?? 0,
          longitude: double.tryParse(map['lon'] as String? ?? '0') ?? 0,
          address: addressSnippet.isNotEmpty ? addressSnippet : null,
        );
      }).toList();
    } catch (e, st) {
      dev.log(
        'GeocodingService.search FAILED: $e',
        name: 'Geocoding',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Reverse geocoding — lat/lon → [LocationPoint] with address.
  static Future<LocationPoint?> reverseGeocode(double lat, double lon) async {
    try {
      dev.log(
        'GeocodingService.reverseGeocode: ($lat, $lon)',
        name: 'Geocoding',
      );
      final resp = await _dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {'lat': lat, 'lon': lon, 'format': 'json', 'zoom': 17},
      );
      final data = resp.data;
      if (data == null) return null;
      final displayName = (data['display_name'] as String? ?? '');
      final shortName = displayName.split(',').first.trim();
      final parts = displayName.split(',');
      final addressSnippet = parts.length > 2
          ? '${parts[1].trim()}, ${parts[2].trim()}'
          : parts.length > 1
          ? parts[1].trim()
          : '';
      return LocationPoint(
        name: shortName.isNotEmpty ? shortName : 'Pinned Location',
        latitude: lat,
        longitude: lon,
        address: addressSnippet.isNotEmpty ? addressSnippet : null,
      );
    } catch (e, st) {
      dev.log(
        'GeocodingService.reverseGeocode FAILED: $e',
        name: 'Geocoding',
        error: e,
        stackTrace: st,
      );
      return LocationPoint(
        name: 'Pinned Location',
        latitude: lat,
        longitude: lon,
      );
    }
  }
}
