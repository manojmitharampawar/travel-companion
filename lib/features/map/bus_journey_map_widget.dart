import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/core/services/tile_cache_service.dart';
import 'package:travel_companion/data/models/location_point.dart';

const _kTileUrl =
    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';

class BusJourneyMapWidget extends StatefulWidget {
  final LocationPoint? origin;
  final LocationPoint destination;
  final List<LatLng> roadRoutePoints;
  final Color accentColor;

  const BusJourneyMapWidget({
    super.key,
    this.origin,
    required this.destination,
    this.roadRoutePoints = const [],
    this.accentColor = const Color(0xFFFF6B00),
  });

  @override
  State<BusJourneyMapWidget> createState() => _BusJourneyMapWidgetState();
}

class _BusJourneyMapWidgetState extends State<BusJourneyMapWidget> {
  late final MapController _mapController;

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

    for (final point in widget.roadRoutePoints) {
      minLat = minLat > point.latitude ? point.latitude : minLat;
      maxLat = maxLat < point.latitude ? point.latitude : maxLat;
      minLon = minLon > point.longitude ? point.longitude : minLon;
      maxLon = maxLon < point.longitude ? point.longitude : maxLon;
    }

    final latDiff = maxLat - minLat;
    final lonDiff = maxLon - minLon;
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;

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
        TileLayer(
          urlTemplate: _kTileUrl,
          tileProvider: CachedTileProvider(urlTemplate: _kTileUrl),
        ),
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
        MarkerLayer(
          markers: [
            if (widget.origin != null)
              Marker(
                point: LatLng(
                  widget.origin!.latitude,
                  widget.origin!.longitude,
                ),
                width: 45,
                height: 45,
                alignment: Alignment.center,
                child: _buildMarker(
                  icon: CupertinoIcons.circle_fill,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            Marker(
              point: LatLng(
                widget.destination.latitude,
                widget.destination.longitude,
              ),
              width: 45,
              height: 45,
              alignment: Alignment.center,
              child: _buildMarker(
                icon: CupertinoIcons.location_solid,
                color: const Color(0xFFFF5252),
              ),
            ),
          ],
        ),
        RichAttributionWidget(
          attributions: [
            const TextSourceAttribution('OpenStreetMap contributors'),
            const TextSourceAttribution('CARTO'),
            if (hasRoute) const TextSourceAttribution('OSRM'),
          ],
        ),
      ],
    );
  }

  Widget _buildMarker({required IconData icon, required Color color}) {
    return Container(
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
      child: Icon(icon, color: CupertinoColors.white, size: 20),
    );
  }
}
