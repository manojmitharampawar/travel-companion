import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/train_route.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/map/journey_map_widget.dart';
import 'package:travel_companion/features/map/train_journey_map_widget.dart';

/// Fullscreen map screen that shows the journey map edge-to-edge.
///
/// Supports both the generic [JourneyMapWidget] and rail-specific
/// [TrainJourneyMapWidget] depending on the parameters provided.
class FullscreenMapScreen extends StatefulWidget {
  final LocationPoint? origin;
  final LocationPoint destination;
  final Position? currentPosition;
  final TransportType transportType;

  // For generic (bus/metro) map
  final List<TrainRoute> routeStops;
  final List<LatLng> roadRoutePoints;

  // For train/local-train map
  final List<TrainRouteStop> trainRouteStops;
  final int nextStopIndex;
  final bool useTrainMap;

  const FullscreenMapScreen({
    super.key,
    this.origin,
    required this.destination,
    this.currentPosition,
    this.transportType = TransportType.train,
    this.routeStops = const [],
    this.roadRoutePoints = const [],
    this.trainRouteStops = const [],
    this.nextStopIndex = 0,
    this.useTrainMap = false,
  });

  @override
  State<FullscreenMapScreen> createState() => _FullscreenMapScreenState();
}

class _FullscreenMapScreenState extends State<FullscreenMapScreen> {
  @override
  void initState() {
    super.initState();
    // Hide system UI for true fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Stack(
        children: [
          // Full-screen map
          Positioned.fill(
            child: widget.useTrainMap
                ? TrainJourneyMapWidget(
                    origin: widget.origin,
                    destination: widget.destination,
                    currentPosition: widget.currentPosition,
                    routeStops: widget.trainRouteStops,
                    nextStopIndex: widget.nextStopIndex,
                    showControls: true,
                  )
                : JourneyMapWidget(
                    origin: widget.origin,
                    destination: widget.destination,
                    currentPosition: widget.currentPosition,
                    routeStops: widget.routeStops,
                    transportType: widget.transportType,
                    roadRoutePoints: widget.roadRoutePoints,
                    showControls: true,
                  ),
          ),

          // Close button (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: _GlassCloseButton(
              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          // Transport badge (top-center)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 0,
            right: 0,
            child: Center(
              child: _GlassTransportBadge(
                transportType: widget.transportType,
                destination: widget.destination.name,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Close Button
// ─────────────────────────────────────────────

class _GlassCloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GlassCloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: Tooltip(
            message: 'Exit fullscreen',
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E21).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
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
                  Icons.fullscreen_exit_rounded,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.8),
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
// Glass Transport Badge
// ─────────────────────────────────────────────

class _GlassTransportBadge extends StatelessWidget {
  final TransportType transportType;
  final String destination;

  const _GlassTransportBadge({
    required this.transportType,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E21).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: transportType.color.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                transportType.icon,
                size: 16,
                color: transportType.color,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  destination,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
