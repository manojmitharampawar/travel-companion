import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Fetches a road-following polyline from the OSRM public routing API.
/// No API key required.  Rate-limit: reasonable fair use.
class RoutingService {
  RoutingService._();

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent': 'TravelCompanionApp/1.0 (contact@travelcompanion.app)',
    },
  ));

  /// Returns an ordered list of [LatLng] that follows the road network
  /// between [origin] and [destination].
  ///
  /// [profile] can be `'driving'` (default), `'walking'`, or `'cycling'`.
  /// Falls back to an empty list on any error so callers can degrade
  /// gracefully to a straight-line polyline.
  static Future<List<LatLng>> fetchRoute({
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

      final resp = await _dio.get<Map<String, dynamic>>(url);
      final data = resp.data;
      if (data == null) return [];

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return [];

      final geometry = routes[0]['geometry'] as Map<String, dynamic>?;
      if (geometry == null) return [];

      final coordinates = geometry['coordinates'] as List<dynamic>?;
      if (coordinates == null) return [];

      return coordinates.map((c) {
        final coord = c as List<dynamic>;
        // GeoJSON order is [longitude, latitude]
        final lon = (coord[0] as num).toDouble();
        final lat = (coord[1] as num).toDouble();
        return LatLng(lat, lon);
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
