import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/train_route.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/transport_type.dart';

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
            widget.currentPosition!.latitude, widget.currentPosition!.longitude),
        _isFollowingUser ? 15.0 : _mapController.camera.zoom,
      );
    }
  }

  void _zoomToCurrentLocation() {
    if (widget.currentPosition != null) {
      setState(() => _isFollowingUser = true);
      _mapController.move(
        LatLng(
            widget.currentPosition!.latitude, widget.currentPosition!.longitude),
        15.0,
      );
    }
  }

  void _zoomToFullRoute() {
    setState(() => _isFollowingUser = false);
    final boundsPoints = _allBoundsPoints();
    if (boundsPoints.length < 2) return;

    final bounds = LatLngBounds.fromPoints(boundsPoints);
    _mapController.fitCamera(CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.all(40),
    ));
  }

  List<LatLng> _allBoundsPoints() {
    final points = <LatLng>[];
    if (widget.origin != null) {
      points.add(LatLng(widget.origin!.latitude, widget.origin!.longitude));
    }
    if (widget.currentPosition != null) {
      points.add(LatLng(
          widget.currentPosition!.latitude, widget.currentPosition!.longitude));
    }
    points
        .add(LatLng(widget.destination.latitude, widget.destination.longitude));
    for (final p in widget.roadRoutePoints) {
      points.add(p);
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final destLatLng =
        LatLng(widget.destination.latitude, widget.destination.longitude);
    final markers = <Marker>[];
    final boundsPoints = <LatLng>[];

    // Origin marker
    if (widget.origin != null) {
      final originLatLng =
          LatLng(widget.origin!.latitude, widget.origin!.longitude);
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
    if (widget.currentPosition != null) {
      final curLatLng = LatLng(
          widget.currentPosition!.latitude, widget.currentPosition!.longitude);
      markers.add(
        Marker(
          point: curLatLng,
          width: 52,
          height: 52,
          child: _PulsingPositionMarker(),
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
            size: 36, color: Color(0xFFE74C3C)),
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
        polylinePoints
            .add(LatLng(widget.origin!.latitude, widget.origin!.longitude));
      }
      if (widget.currentPosition != null) {
        polylinePoints.add(LatLng(widget.currentPosition!.latitude,
            widget.currentPosition!.longitude));
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
              flags: InteractiveFlag.pinchZoom |
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
              fallbackUrl:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                      color: widget.transportType.color
                          .withValues(alpha: 0.7),
                      pattern:
                          StrokePattern.dashed(segments: [10, 6]),
                    ),
                ],
              ),

            MarkerLayer(markers: markers),

            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                    '© OpenStreetMap contributors'),
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
            _GlassMapButton(
              icon: Icons.fullscreen_rounded,
              onTap: widget.onFullscreen!,
              tooltip: 'Fullscreen',
            ),
          if (widget.onFullscreen != null) const SizedBox(height: 8),

          // Zoom to full route
          _GlassMapButton(
            icon: Icons.zoom_out_map_rounded,
            onTap: _zoomToFullRoute,
            tooltip: 'View full route',
          ),
          const SizedBox(height: 8),

          // Recenter on current location
          _GlassMapButton(
            icon: _isFollowingUser
                ? Icons.my_location_rounded
                : Icons.location_searching_rounded,
            onTap: _zoomToCurrentLocation,
            isActive: _isFollowingUser,
            tooltip: 'My location',
          ),
        ],
      ),
    );
  }

  LatLng _resolveCenter(LatLng destLatLng) {
    if (widget.currentPosition != null) {
      return LatLng(
          widget.currentPosition!.latitude, widget.currentPosition!.longitude);
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

class _GlassMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final String? tooltip;

  const _GlassMapButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: Tooltip(
            message: tooltip ?? '',
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF3498DB).withValues(alpha: 0.2)
                      : g.isDark ? const Color(0xFF0A0E21).withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF3498DB).withValues(alpha: 0.4)
                        : g.border(0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? const Color(0xFF3498DB)
                      : g.textAlpha(0.8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Pulsing current-position marker
// ─────────────────────────────────────────────

class _PulsingPositionMarker extends StatefulWidget {
  @override
  State<_PulsingPositionMarker> createState() =>
      _PulsingPositionMarkerState();
}

class _PulsingPositionMarkerState extends State<_PulsingPositionMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44 * _anim.value,
            height: 44 * _anim.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue
                  .withValues(alpha: 0.15 * _anim.value),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade700,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade700
                      .withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
