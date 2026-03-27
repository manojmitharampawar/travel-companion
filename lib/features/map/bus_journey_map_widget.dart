import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/data/models/location_point.dart';

/// Bus-specific map widget showing road-based route with OSRM routing.
/// 
/// Features:
/// - Google Maps-style road routing via OSRM
/// - Origin and destination markers
/// - Road path polyline
/// - CartoDB Voyager basemap for road network clarity
class BusJourneyMapWidget extends StatefulWidget {
  final LocationPoint? origin;
  final LocationPoint destination;
  final List<LatLng> roadRoutePoints; // Road-following polyline from OSRM
  final Color accentColor;

  const BusJourneyMapWidget({
    super.key,
    this.origin,
    required this.destination,
    this.roadRoutePoints = const [],
    this.accentColor = const Color(0xFFFF6B00), // Bus orange
  });

  @override
  State<BusJourneyMapWidget> createState() => _BusJourneyMapWidgetState();
}

class _BusJourneyMapWidgetState extends State<BusJourneyMapWidget> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng _getCenter() {
    if (widget.roadRoutePoints.isNotEmpty) {
      return widget.roadRoutePoints[widget.roadRoutePoints.length ~/ 2];
    }
    if (widget.origin != null) {
      return LatLng(widget.origin!.latitude, widget.origin!.longitude);
    }
    return LatLng(widget.destination.latitude, widget.destination.longitude);
  }

  double _calculateZoom() {
    if (widget.roadRoutePoints.length < 2) return 13;
    
    double minLat = widget.roadRoutePoints.first.latitude;
    double maxLat = widget.roadRoutePoints.first.latitude;
    double minLon = widget.roadRoutePoints.first.longitude;
    double maxLon = widget.roadRoutePoints.first.longitude;

    for (var point in widget.roadRoutePoints) {
      minLat = minLat > point.latitude ? point.latitude : minLat;
      maxLat = maxLat < point.latitude ? point.latitude : maxLat;
      minLon = minLon > point.longitude ? point.longitude : minLon;
      maxLon = maxLon < point.longitude ? point.longitude : maxLon;
    }

    double latDiff = maxLat - minLat;
    double lonDiff = maxLon - minLon;
    double maxDiff = latDiff > lonDiff ? latDiff : lonDiff;

    return (12 - (maxDiff * 10).clamp(0, 6)).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final hasRoute = widget.roadRoutePoints.length >= 2;
    final polylinePoints = hasRoute
        ? widget.roadRoutePoints
        : <LatLng>[
            if (widget.origin != null)
              LatLng(widget.origin!.latitude, widget.origin!.longitude),
            LatLng(widget.destination.latitude, widget.destination.longitude),
          ];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _getCenter(),
        initialZoom: _calculateZoom(),
      ),
      children: [
        // CartoDB Voyager basemap (Google Maps-like)
        TileLayer(
          urlTemplate:
              'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          userAgentPackageName: 'com.travel_companion.app',
          fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),

        // Road route polyline (solid)
        if (polylinePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                strokeWidth: 5,
                color: widget.accentColor,
                pattern: const StrokePattern.solid(),
              ),
            ],
          ),

        // Route markers
        MarkerLayer(
          markers: [
            // Origin marker (if available)
            if (widget.origin != null)
              Marker(
                point: LatLng(widget.origin!.latitude, widget.origin!.longitude),
                width: 45,
                height: 45,
                alignment: Alignment.center,
                child: _buildMarker(
                  icon: Icons.trip_origin,
                  color: const Color(0xFF4CAF50), // Green
                  label: 'Start',
                ),
              ),

            // Destination marker
            Marker(
              point: LatLng(widget.destination.latitude, widget.destination.longitude),
              width: 45,
              height: 45,
              alignment: Alignment.center,
              child: _buildMarker(
                icon: Icons.location_on,
                color: const Color(0xFFFF5252), // Red
                label: 'End',
              ),
            ),
          ],
        ),

        // Attribution
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution('© OpenStreetMap contributors'),
            TextSourceAttribution('© CARTO'),
            if (hasRoute) TextSourceAttribution('© OSRM'),
          ],
        ),
      ],
    );
  }

  Widget _buildMarker({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Tooltip(
      message: label,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

