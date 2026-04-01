import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Result from an OSRM route query, including the polyline, distance, and duration.
class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMinutes;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });

  static const empty = RouteResult(
    points: [],
    distanceKm: 0,
    durationMinutes: 0,
  );

  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;

  String get distanceText {
    if (distanceKm < 1) return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get durationText {
    final totalMin = durationMinutes.round();
    if (totalMin < 60) return '$totalMin min';
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}

/// Fetches a road-following polyline from the OSRM public routing API.
/// No API key required.  Rate-limit: reasonable fair use.
class RoutingService {
  RoutingService._();

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'TravelCompanionApp/1.0 (contact@travelcompanion.app)',
      },
    ),
  );

  /// Returns a [RouteResult] with road-following polyline, distance, and duration.
  ///
  /// [profile] can be `'driving'` (default), `'walking'`, or `'cycling'`.
  /// Falls back to [RouteResult.empty] on any error.
  static Future<RouteResult> fetchRoute({
    required LatLng origin,
    required LatLng destination,
    String profile = 'driving',
  }) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/$profile'
          '/${origin.longitude},${origin.latitude}'
          ';${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson';

      dev.log('RoutingService.fetchRoute: $url', name: 'Routing');
      final resp = await _dio.get<Map<String, dynamic>>(url);
      final data = resp.data;
      if (data == null) return RouteResult.empty;

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return RouteResult.empty;

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      if (geometry == null) return RouteResult.empty;

      final coordinates = geometry['coordinates'] as List<dynamic>?;
      if (coordinates == null) return RouteResult.empty;

      final points = coordinates.map((c) {
        final coord = c as List<dynamic>;
        final lon = (coord[0] as num).toDouble();
        final lat = (coord[1] as num).toDouble();
        return LatLng(lat, lon);
      }).toList();

      final distanceM = (route['distance'] as num?)?.toDouble() ?? 0;
      final durationS = (route['duration'] as num?)?.toDouble() ?? 0;

      return RouteResult(
        points: points,
        distanceKm: distanceM / 1000,
        durationMinutes: durationS / 60,
      );
    } catch (e, st) {
      dev.log(
        'RoutingService.fetchRoute FAILED: $e',
        name: 'Routing',
        error: e,
        stackTrace: st,
      );
      return RouteResult.empty;
    }
  }
}
