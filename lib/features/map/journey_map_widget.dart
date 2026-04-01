import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/train_route.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/map/widgets/glass_map_control_button.dart';
import 'package:travel_companion/features/map/widgets/pulsing_position_marker.dart';

class JourneyMapWidget extends StatefulWidget {
  final LocationPoint? origin;
  final LocationPoint destination;
  final Position? currentPosition;
  final List<TrainRoute> routeStops;
  final TransportType transportType;

  /// When provided, drawn as the primary route polyline (road-following).
  /// Falls back to a straight line when null or empty.
  final List<LatLng> roadRoutePoints;

  /// Whether to show the map control overlay buttons (recenter, zoom out).
  final bool showControls;

  /// Called when user taps fullscreen button. If null, button is hidden.
  final VoidCallback? onFullscreen;

  const JourneyMapWidget({
    super.key,
    this.origin,
    required this.destination,
    this.currentPosition,
    this.routeStops = const [],
    this.transportType = TransportType.train,
    this.roadRoutePoints = const [],
    this.showControls = true,
    this.onFullscreen,
  });

  @override
  State<JourneyMapWidget> createState() => _JourneyMapWidgetState();
}

class _JourneyMapWidgetState extends State<JourneyMapWidget> {
  final _mapController = MapController();
  bool _isFollowingUser = true;

  @override
  void didUpdateWidget(JourneyMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-pan to current position when it updates (if following)
    if (widget.currentPosition != null &&
        widget.currentPosition != oldWidget.currentPosition &&
        _isFollowingUser) {
      _mapController.move(
        LatLng(
          widget.currentPosition!.latitude,
          widget.currentPosition!.longitude,
        ),
        _isFollowingUser ? 15.0 : _mapController.camera.zoom,
      );
    }
  }

  void _zoomToCurrentLocation() {
    if (widget.currentPosition != null) {
      setState(() => _isFollowingUser = true);
      _mapController.move(
        LatLng(
          widget.currentPosition!.latitude,
          widget.currentPosition!.longitude,
        ),
        15.0,
      );
    }
  }

  void _zoomToFullRoute() {
    setState(() => _isFollowingUser = false);
    final boundsPoints = _allBoundsPoints();
    if (boundsPoints.length < 2) return;

    final bounds = LatLngBounds.fromPoints(boundsPoints);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
    );
  }

  List<LatLng> _allBoundsPoints() {
    final points = <LatLng>[];
    if (widget.origin != null) {
      points.add(LatLng(widget.origin!.latitude, widget.origin!.longitude));
    }
    if (widget.currentPosition != null) {
      points.add(
        LatLng(
          widget.currentPosition!.latitude,
          widget.currentPosition!.longitude,
        ),
      );
    }
    points.add(
      LatLng(widget.destination.latitude, widget.destination.longitude),
    );
    for (final p in widget.roadRoutePoints) {
      points.add(p);
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final destLatLng = LatLng(
      widget.destination.latitude,
      widget.destination.longitude,
    );
    final markers = <Marker>[];
    final boundsPoints = <LatLng>[];

    // Origin marker
    if (widget.origin != null) {
      final originLatLng = LatLng(
        widget.origin!.latitude,
        widget.origin!.longitude,
      );
      markers.add(
        Marker(
          point: originLatLng,
          width: 36,
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8),
              shape: BoxShape.circle,
              border: Border.all(color: CupertinoColors.white, width: 2.5),
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
    if (widget.currentPosition != null) {
      final curLatLng = LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      );
      markers.add(
        Marker(
          point: curLatLng,
          width: 52,
          height: 52,
          child: const PulsingPositionMarker(),
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
        child: const Icon(
          CupertinoIcons.location_solid,
          size: 36,
          color: Color(0xFFE74C3C),
        ),
      ),
    );
    boundsPoints.add(destLatLng);

    // Build the polyline points
    final hasRoadRoute = widget.roadRoutePoints.length >= 2;
    final List<LatLng> polylinePoints;
    if (hasRoadRoute) {
      polylinePoints = widget.roadRoutePoints;
    } else {
      polylinePoints = [];
      if (widget.origin != null) {
        polylinePoints.add(
          LatLng(widget.origin!.latitude, widget.origin!.longitude),
        );
      }
      if (widget.currentPosition != null) {
        polylinePoints.add(
          LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
        );
      }
      polylinePoints.add(destLatLng);
    }

    final center = _resolveCenter(destLatLng);
    final zoom = _isFollowingUser && widget.currentPosition != null
        ? 15.0
        : _calculateZoom(boundsPoints);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags:
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.doubleTapZoom,
            ),
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture && _isFollowingUser) {
                setState(() => _isFollowingUser = false);
              }
            },
          ),
          children: [
            // CartoDB Voyager basemap
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
                  if (hasRoadRoute)
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 5,
                      color: widget.transportType.color,
                      pattern: const StrokePattern.solid(),
                    )
                  else
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 3.5,
                      color: widget.transportType.color.withValues(alpha: 0.7),
                      pattern: StrokePattern.dashed(segments: [10, 6]),
                    ),
                ],
              ),

            MarkerLayer(markers: markers),

            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
                TextSourceAttribution('© CARTO'),
              ],
            ),
          ],
        ),

        // Map control overlay
        if (widget.showControls) _buildControlOverlay(),
      ],
    );
  }

  Widget _buildControlOverlay() {
    return Positioned(
      right: 12,
      bottom: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fullscreen button
          if (widget.onFullscreen != null)
            GlassMapControlButton(
              icon: CupertinoIcons.fullscreen,
              onTap: widget.onFullscreen!,
            ),
          if (widget.onFullscreen != null) const SizedBox(height: 8),

          // Zoom to full route
          GlassMapControlButton(
            icon: CupertinoIcons.arrow_up_left_arrow_down_right,
            onTap: _zoomToFullRoute,
          ),
          const SizedBox(height: 8),

          // Recenter on current location
          GlassMapControlButton(
            icon: _isFollowingUser
                ? CupertinoIcons.location_fill
                : CupertinoIcons.scope,
            onTap: _zoomToCurrentLocation,
            isActive: _isFollowingUser,
          ),
        ],
      ),
    );
  }

  LatLng _resolveCenter(LatLng destLatLng) {
    if (widget.currentPosition != null) {
      return LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      );
    }
    if (widget.origin != null) {
      return LatLng(
        (widget.origin!.latitude + widget.destination.latitude) / 2,
        (widget.origin!.longitude + widget.destination.longitude) / 2,
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

// ─────────────────────────────────────────────
// Glass Map Button
// ─────────────────────────────────────────────
