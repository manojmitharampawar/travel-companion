import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/core/theme/app_theme.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/providers/app_providers.dart';
import 'package:travel_companion/features/map/widgets/glass_map_control_button.dart';
import 'package:travel_companion/features/map/widgets/pulsing_position_marker.dart';
import 'package:travel_companion/features/map/widgets/next_stop_callout.dart';

/// Railway-specific map widget for train and local-train journeys.
///
/// Layers (bottom → top):
///   1. CartoDB Voyager base map
///   2. OpenRailwayMap tile overlay (toggleable via settings)
///   3. Station-to-station route polyline (actual stop coordinates)
///   4. Station markers (color-coded by state)
///   5. Current position marker (animated pulse)
///   6. Next-stop callout bubble
class TrainJourneyMapWidget extends ConsumerStatefulWidget {
  final LocationPoint? origin;
  final LocationPoint destination;
  final Position? currentPosition;
  final List<TrainRouteStop> routeStops;

  /// Index within [routeStops] of the next upcoming stop (0-based).
  /// Stops before this index are rendered as "passed".
  final int nextStopIndex;

  /// Whether to show control overlay buttons.
  final bool showControls;

  /// Called when user taps fullscreen button. If null, button is hidden.
  final VoidCallback? onFullscreen;

  const TrainJourneyMapWidget({
    super.key,
    this.origin,
    required this.destination,
    this.currentPosition,
    this.routeStops = const [],
    this.nextStopIndex = 0,
    this.showControls = true,
    this.onFullscreen,
  });

  @override
  ConsumerState<TrainJourneyMapWidget> createState() =>
      _TrainJourneyMapWidgetState();
}

class _TrainJourneyMapWidgetState extends ConsumerState<TrainJourneyMapWidget> {
  final _mapController = MapController();
  bool _isFollowingUser = true;

  @override
  void didUpdateWidget(TrainJourneyMapWidget oldWidget) {
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
        _isFollowingUser ? 14.0 : _mapController.camera.zoom,
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
        14.0,
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
    final destLatLng = LatLng(
      widget.destination.latitude,
      widget.destination.longitude,
    );
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
    points.add(destLatLng);
    for (final s in widget.routeStops) {
      points.add(s.latLng);
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final showRailwayOverlay = ref.watch(railwayOverlayProvider);

    final destLatLng = LatLng(
      widget.destination.latitude,
      widget.destination.longitude,
    );

    // ── Markers ─────────────────────────────
    final markers = <Marker>[];

    // Station markers
    for (var i = 0; i < widget.routeStops.length; i++) {
      final stop = widget.routeStops[i];
      final isFirst = i == 0;
      final isLast = i == widget.routeStops.length - 1;
      final isPassed = i < widget.nextStopIndex;
      final isNext = i == widget.nextStopIndex && !isLast;

      markers.add(
        _stationMarker(
          point: stop.latLng,
          stop: stop,
          isFirst: isFirst,
          isLast: isLast,
          isPassed: isPassed,
          isNext: isNext,
        ),
      );
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
    }

    // ── Bounds ──────────────────────────────
    final boundsPoints = <LatLng>[destLatLng];
    if (widget.origin != null) {
      boundsPoints.add(
        LatLng(widget.origin!.latitude, widget.origin!.longitude),
      );
    }
    if (widget.currentPosition != null) {
      boundsPoints.add(
        LatLng(
          widget.currentPosition!.latitude,
          widget.currentPosition!.longitude,
        ),
      );
    }
    for (final s in widget.routeStops) {
      boundsPoints.add(s.latLng);
    }

    final center = _resolveCenter(destLatLng);
    final zoom = _isFollowingUser && widget.currentPosition != null
        ? 14.0
        : _calculateZoom(boundsPoints);

    // ── Route polyline ───────────────────────
    final routePoints = widget.routeStops.isNotEmpty
        ? widget.routeStops.map((s) => s.latLng).toList()
        : _fallbackPoints(destLatLng);

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
            // 1. Base map
            TileLayer(
              urlTemplate:
                  'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
              userAgentPackageName: 'com.travel_companion.app',
              fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),

            // 2. OpenRailwayMap overlay
            if (showRailwayOverlay)
              TileLayer(
                urlTemplate:
                    'https://{s}.tiles.openrailwaymap.org/standard/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.travel_companion.app',
                tileProvider: NetworkTileProvider(),
              ),

            // 3. Route polyline
            if (routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  // Passed segment: gray
                  if (widget.nextStopIndex > 0 &&
                      widget.nextStopIndex < widget.routeStops.length)
                    Polyline(
                      points: widget.routeStops
                          .sublist(
                            0,
                            (widget.nextStopIndex + 1).clamp(
                              0,
                              widget.routeStops.length,
                            ),
                          )
                          .map((s) => s.latLng)
                          .toList(),
                      strokeWidth: 3,
                      color: const Color(0xFFBDBDBD),
                      pattern: const StrokePattern.solid(),
                    ),
                  // Upcoming segment: railway blue
                  Polyline(
                    points: widget.routeStops.isNotEmpty
                        ? widget.routeStops
                              .sublist(
                                widget.nextStopIndex.clamp(
                                  0,
                                  widget.routeStops.length,
                                ),
                              )
                              .map((s) => s.latLng)
                              .toList()
                        : routePoints,
                    strokeWidth: 4.5,
                    color: const Color(0xFF1565C0),
                    pattern: const StrokePattern.solid(),
                  ),
                ],
              ),

            // 4 + 5. Station markers + current position
            MarkerLayer(markers: markers),

            // 6. Attribution
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
                TextSourceAttribution('© CARTO'),
                if (showRailwayOverlay)
                  TextSourceAttribution('© OpenRailwayMap'),
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

  Marker _stationMarker({
    required LatLng point,
    required TrainRouteStop stop,
    required bool isFirst,
    required bool isLast,
    required bool isPassed,
    required bool isNext,
  }) {
    if (isNext) {
      return Marker(
        point: point,
        width: 120,
        height: 60,
        alignment: Alignment.bottomCenter,
        child: NextStopCallout(stop: stop),
      );
    }

    if (isLast) {
      return Marker(
        point: point,
        width: 36,
        height: 36,
        alignment: Alignment.topCenter,
        child: const Icon(
          CupertinoIcons.location_solid,
          size: 36,
          color: AppTheme.dangerColor,
        ),
      );
    }

    final color = isPassed
        ? const Color(0xFFBDBDBD)
        : isFirst
        ? const Color(0xFF2E7D32)
        : const Color(0xFF1565C0).withValues(alpha: 0.7);

    final size = (isFirst || isLast) ? 12.0 : (isPassed ? 6.0 : 8.0);

    return Marker(
      point: point,
      width: size + 8,
      height: size + 8,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: CupertinoColors.white,
            width: isPassed ? 1 : 1.5,
          ),
          boxShadow: isPassed
              ? null
              : [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
        ),
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

  List<LatLng> _fallbackPoints(LatLng destLatLng) {
    final pts = <LatLng>[];
    if (widget.origin != null) {
      pts.add(LatLng(widget.origin!.latitude, widget.origin!.longitude));
    }
    if (widget.currentPosition != null) {
      pts.add(
        LatLng(
          widget.currentPosition!.latitude,
          widget.currentPosition!.longitude,
        ),
      );
    }
    pts.add(destLatLng);
    return pts;
  }

  double _calculateZoom(List<LatLng> points) {
    if (points.length < 2) return 12;

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

    final maxDiff = (maxLat - minLat) > (maxLng - minLng)
        ? (maxLat - minLat)
        : (maxLng - minLng);

    if (maxDiff < 0.01) return 14;
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
