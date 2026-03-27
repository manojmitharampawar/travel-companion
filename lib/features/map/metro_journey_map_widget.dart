import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/data/models/metro_station.dart';

/// Metro-specific map widget showing metro line with stations.
/// 
/// Features:
/// - Displays all stations on a metro line
/// - Color-coded polyline between stations
/// - Station markers with custom styling
/// - Focuses on route between origin and destination
class MetroJourneyMapWidget extends StatefulWidget {
  final List<MetroStation> stations;
  final MetroStation? originStation;
  final MetroStation? destinationStation;
  final String lineColor; // e.g., "#0C60CA"

  const MetroJourneyMapWidget({
    super.key,
    required this.stations,
    this.originStation,
    this.destinationStation,
    this.lineColor = '#006BB6',
  });

  @override
  State<MetroJourneyMapWidget> createState() => _MetroJourneyMapWidgetState();
}

class _MetroJourneyMapWidgetState extends State<MetroJourneyMapWidget> {
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

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (_) {
      return const Color(0xFF006BB6);
    }
  }

  LatLng _getCenter() {
    if (widget.stations.isEmpty) {
      return const LatLng(20.5937, 78.9629); // Default to India center
    }
    
    double avgLat = 0;
    double avgLon = 0;
    for (var station in widget.stations) {
      avgLat += station.latitude;
      avgLon += station.longitude;
    }
    return LatLng(avgLat / widget.stations.length, avgLon / widget.stations.length);
  }

  double _calculateZoom() {
    if (widget.stations.length < 2) return 12;
    
    double minLat = widget.stations.first.latitude;
    double maxLat = widget.stations.first.latitude;
    double minLon = widget.stations.first.longitude;
    double maxLon = widget.stations.first.longitude;

    for (var station in widget.stations) {
      minLat = minLat > station.latitude ? station.latitude : minLat;
      maxLat = maxLat < station.latitude ? station.latitude : maxLat;
      minLon = minLon > station.longitude ? station.longitude : minLon;
      maxLon = maxLon < station.longitude ? station.longitude : maxLon;
    }

    double latDiff = maxLat - minLat;
    double lonDiff = maxLon - minLon;
    double maxDiff = latDiff > lonDiff ? latDiff : lonDiff;

    return 12 - (maxDiff * 10).clamp(0, 6).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final lineColor = _parseColor(widget.lineColor);
    final stationPoints = widget.stations
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();

    // Find indices of origin and destination
    int? originIdx;
    int? destIdx;
    if (widget.originStation != null) {
      originIdx = widget.stations.indexWhere((s) => s.code == widget.originStation!.code);
    }
    if (widget.destinationStation != null) {
      destIdx = widget.stations.indexWhere((s) => s.code == widget.destinationStation!.code);
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _getCenter(),
        initialZoom: _calculateZoom(),
      ),
      children: [
        // Base map tiles
        TileLayer(
          urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          userAgentPackageName: 'com.travel_companion.app',
          fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),

        // Metro line polyline
        if (stationPoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: stationPoints,
                strokeWidth: 4,
                color: lineColor,
                pattern: const StrokePattern.solid(),
              ),
            ],
          ),

        // Station markers
        MarkerLayer(
          markers: [
            for (int i = 0; i < widget.stations.length; i++)
              Marker(
                point: stationPoints[i],
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: _buildStationMarker(
                  widget.stations[i],
                  lineColor,
                  isOrigin: i == originIdx,
                  isDestination: i == destIdx,
                  isInRoute: originIdx != null &&
                      destIdx != null &&
                      i >= originIdx &&
                      i <= destIdx,
                ),
              ),
          ],
        ),

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

  Widget _buildStationMarker(
    MetroStation station,
    Color lineColor, {
    required bool isOrigin,
    required bool isDestination,
    required bool isInRoute,
  }) {
    Color markerColor;
    IconData icon;

    if (isOrigin) {
      markerColor = const Color(0xFF4CAF50); // Green
      icon = Icons.trip_origin;
    } else if (isDestination) {
      markerColor = const Color(0xFFFF5252); // Red
      icon = Icons.location_on;
    } else if (isInRoute) {
      markerColor = lineColor;
      icon = Icons.circle;
    } else {
      markerColor = Colors.grey.shade400;
      icon = Icons.circle_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        color: markerColor,
        shape: BoxShape.circle,
        boxShadow: isInRoute || isOrigin || isDestination
            ? [
                BoxShadow(
                  color: markerColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}

