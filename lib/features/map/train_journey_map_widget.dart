import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/core/theme/app_theme.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/providers/app_providers.dart';

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

  const TrainJourneyMapWidget({
    super.key,
    this.origin,
    required this.destination,
    this.currentPosition,
    this.routeStops = const [],
    this.nextStopIndex = 0,
  });

  @override
  ConsumerState<TrainJourneyMapWidget> createState() =>
      _TrainJourneyMapWidgetState();
}

class _TrainJourneyMapWidgetState
    extends ConsumerState<TrainJourneyMapWidget> {
  final _mapController = MapController();

  @override
  void didUpdateWidget(TrainJourneyMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-pan to current position when it updates
    if (widget.currentPosition != null &&
        widget.currentPosition != oldWidget.currentPosition) {
      _mapController.move(
        LatLng(widget.currentPosition!.latitude,
            widget.currentPosition!.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showRailwayOverlay = ref.watch(railwayOverlayProvider);

    final destLatLng =
        LatLng(widget.destination.latitude, widget.destination.longitude);

    // ── Markers ─────────────────────────────
    final markers = <Marker>[];

    // Station markers (only when route stops are available)
    for (var i = 0; i < widget.routeStops.length; i++) {
      final stop = widget.routeStops[i];
      final isFirst = i == 0;
      final isLast = i == widget.routeStops.length - 1;
      final isPassed = i < widget.nextStopIndex;
      final isNext = i == widget.nextStopIndex && !isLast;

      markers.add(_stationMarker(
        point: stop.latLng,
        stop: stop,
        isFirst: isFirst,
        isLast: isLast,
        isPassed: isPassed,
        isNext: isNext,
      ));
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
    }

    // ── Bounds ──────────────────────────────
    final boundsPoints = <LatLng>[destLatLng];
    if (widget.origin != null) {
      boundsPoints.add(LatLng(widget.origin!.latitude, widget.origin!.longitude));
    }
    if (widget.currentPosition != null) {
      boundsPoints.add(LatLng(
          widget.currentPosition!.latitude, widget.currentPosition!.longitude));
    }
    for (final s in widget.routeStops) {
      boundsPoints.add(s.latLng);
    }

    final center = _resolveCenter(destLatLng);
    final zoom = _calculateZoom(boundsPoints);

    // ── Route polyline ───────────────────────
    final routePoints = widget.routeStops.isNotEmpty
        ? widget.routeStops.map((s) => s.latLng).toList()
        : _fallbackPoints(destLatLng);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom |
              InteractiveFlag.drag |
              InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        // 1. Base map
        TileLayer(
          urlTemplate:
              'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          userAgentPackageName: 'com.travel_companion.app',
          fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),

        // 2. OpenRailwayMap overlay (actual railway tracks)
        if (showRailwayOverlay)
          TileLayer(
            urlTemplate:
                'https://{s}.tiles.openrailwaymap.org/standard/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.travel_companion.app',
            opacity: 0.65,
            tileProvider: NetworkTileProvider(),
          ),

        // 3. Route polyline (station-to-station)
        if (routePoints.length >= 2)
          PolylineLayer(
            polylines: [
              // Passed segment: gray
              if (widget.nextStopIndex > 0 &&
                  widget.nextStopIndex < widget.routeStops.length)
                Polyline(
                  points: widget.routeStops
                      .sublist(0,
                          (widget.nextStopIndex + 1).clamp(0, widget.routeStops.length))
                      .map((s) => s.latLng)
                      .toList(),
                  strokeWidth: 3,
                  color: Colors.grey.shade400,
                  pattern: const StrokePattern.solid(),
                ),
              // Upcoming segment: railway blue
              Polyline(
                points: widget.routeStops.isNotEmpty
                    ? widget.routeStops
                        .sublist(widget.nextStopIndex
                            .clamp(0, widget.routeStops.length))
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
      // Next stop: orange callout bubble
      return Marker(
        point: point,
        width: 120,
        height: 60,
        alignment: Alignment.bottomCenter,
        child: _NextStopCallout(stop: stop),
      );
    }

    if (isLast) {
      // Destination: red pin
      return Marker(
        point: point,
        width: 36,
        height: 36,
        alignment: Alignment.topCenter,
        child: const Icon(Icons.location_on_rounded,
            size: 36, color: AppTheme.dangerColor),
      );
    }

    // Regular stop dot
    final color = isPassed
        ? Colors.grey.shade400
        : isFirst
            ? Colors.green.shade600
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
          border: Border.all(color: Colors.white, width: isPassed ? 1 : 1.5),
          boxShadow: isPassed
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 4,
                  )
                ],
        ),
      ),
    );
  }

  LatLng _resolveCenter(LatLng destLatLng) {
    if (widget.currentPosition != null) {
      return LatLng(widget.currentPosition!.latitude,
          widget.currentPosition!.longitude);
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
      pts.add(LatLng(widget.currentPosition!.latitude,
          widget.currentPosition!.longitude));
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
// Next-stop callout bubble
// ─────────────────────────────────────────────

class _NextStopCallout extends StatelessWidget {
  final TrainRouteStop stop;

  const _NextStopCallout({required this.stop});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.shade700.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                stop.stationCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              if (stop.timeDisplay.isNotEmpty)
                Text(
                  stop.timeDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        // Callout tail
        CustomPaint(
          size: const Size(10, 6),
          painter: _CalloutTailPainter(color: Colors.orange.shade700),
        ),
        // Dot at station point
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.shade700,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }
}

class _CalloutTailPainter extends CustomPainter {
  final Color color;
  const _CalloutTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CalloutTailPainter old) => old.color != color;
}

// ─────────────────────────────────────────────
// Pulsing current-position marker
// ─────────────────────────────────────────────

class _PulsingPositionMarker extends StatefulWidget {
  @override
  State<_PulsingPositionMarker> createState() => _PulsingPositionMarkerState();
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
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          Container(
            width: 44 * _anim.value,
            height: 44 * _anim.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.15 * _anim.value),
            ),
          ),
          // Inner dot
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade700,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade700.withValues(alpha: 0.5),
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
