import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/core/theme/app_theme.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/train_route.dart';
import 'package:travel_companion/data/models/transport_type.dart';

class JourneyMapWidget extends StatelessWidget {
  final LocationPoint? origin;
  final LocationPoint destination;
  final Position? currentPosition;
  final List<TrainRoute> routeStops;
  final TransportType transportType;

  /// When provided, drawn as the primary route polyline (road-following).
  /// Falls back to a straight line when null or empty.
  final List<LatLng> roadRoutePoints;

  const JourneyMapWidget({
    super.key,
    this.origin,
    required this.destination,
    this.currentPosition,
    this.routeStops = const [],
    this.transportType = TransportType.train,
    this.roadRoutePoints = const [],
  });

  @override
  Widget build(BuildContext context) {
    final destLatLng = LatLng(destination.latitude, destination.longitude);
    final markers = <Marker>[];
    final boundsPoints = <LatLng>[];

    // Origin marker
    if (origin != null) {
      final originLatLng = LatLng(origin!.latitude, origin!.longitude);
      markers.add(
        Marker(
          point: originLatLng,
          width: 36,
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      );
      boundsPoints.add(originLatLng);
    }

    // Current position marker
    if (currentPosition != null) {
      final curLatLng =
          LatLng(currentPosition!.latitude, currentPosition!.longitude);
      markers.add(
        Marker(
          point: curLatLng,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.6), width: 1.5),
            ),
            child:
                const Center(child: Icon(Icons.navigation, size: 22, color: Colors.blue)),
          ),
        ),
      );
      boundsPoints.add(curLatLng);
    }

    // Destination marker
    markers.add(
      Marker(
        point: destLatLng,
        width: 36,
        height: 36,
        alignment: Alignment.topCenter,
        child: const Icon(Icons.location_on_rounded,
            size: 36, color: AppTheme.dangerColor),
      ),
    );
    boundsPoints.add(destLatLng);

    // Build the polyline points — prefer road route, fall back to straight line
    final hasRoadRoute = roadRoutePoints.length >= 2;
    final List<LatLng> polylinePoints;
    if (hasRoadRoute) {
      polylinePoints = roadRoutePoints;
    } else {
      polylinePoints = [];
      if (origin != null) {
        polylinePoints.add(LatLng(origin!.latitude, origin!.longitude));
      }
      if (currentPosition != null) {
        polylinePoints.add(
            LatLng(currentPosition!.latitude, currentPosition!.longitude));
      }
      polylinePoints.add(destLatLng);
    }

    final center = _resolveCenter(destLatLng);
    final zoom = _calculateZoom(boundsPoints);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
      ),
      children: [
        // CartoDB Voyager — Google Maps-like basemap
        TileLayer(
          urlTemplate:
              'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          userAgentPackageName: 'com.travel_companion.app',
          fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),

        // Route polyline
        if (polylinePoints.length >= 2)
          PolylineLayer(
            polylines: [
              // Road route: solid, transport color
              if (hasRoadRoute)
                Polyline(
                  points: polylinePoints,
                  strokeWidth: 5,
                  color: transportType.color,
                  pattern: const StrokePattern.solid(),
                )
              // Fallback straight-line: dashed
              else
                Polyline(
                  points: polylinePoints,
                  strokeWidth: 3.5,
                  color: transportType.color.withValues(alpha: 0.7),
                  pattern: StrokePattern.dashed(segments: [10, 6]),
                ),
            ],
          ),

        MarkerLayer(markers: markers),

        // Attribution
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution('© OpenStreetMap contributors'),
            TextSourceAttribution('© CARTO'),
          ],
        ),
      ],
    );
  }

  LatLng _resolveCenter(LatLng destLatLng) {
    if (currentPosition != null) {
      return LatLng(currentPosition!.latitude, currentPosition!.longitude);
    }
    if (origin != null) {
      return LatLng(
        (origin!.latitude + destination.latitude) / 2,
        (origin!.longitude + destination.longitude) / 2,
      );
    }
    return destLatLng;
  }

  double _calculateZoom(List<LatLng> points) {
    if (points.length < 2) return 13;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    if (maxDiff < 0.01) return 15;
    if (maxDiff < 0.05) return 13;
    if (maxDiff < 0.1) return 12;
    if (maxDiff < 0.5) return 10;
    if (maxDiff < 1) return 9;
    if (maxDiff < 3) return 7;
    if (maxDiff < 5) return 6;
    return 5;
  }
}
