import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/train_route.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/map/journey_map_widget.dart';
import 'package:travel_companion/features/map/train_journey_map_widget.dart';
import 'package:travel_companion/features/map/widgets/fullscreen_map_close_button.dart';
import 'package:travel_companion/features/map/widgets/fullscreen_map_transport_badge.dart';

class FullscreenMapScreen extends StatefulWidget {
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

  final LocationPoint? origin;
  final LocationPoint destination;
  final Position? currentPosition;
  final TransportType transportType;
  final List<TrainRoute> routeStops;
  final List<LatLng> roadRoutePoints;
  final List<TrainRouteStop> trainRouteStops;
  final int nextStopIndex;
  final bool useTrainMap;

  @override
  State<FullscreenMapScreen> createState() => _FullscreenMapScreenState();
}

class _FullscreenMapScreenState extends State<FullscreenMapScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = GlassColors.of(context);

    return CupertinoPageScaffold(
      backgroundColor: colors.bg,
      child: Stack(
        children: [
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: FullscreenMapCloseButton(
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 0,
            right: 0,
            child: Center(
              child: FullscreenMapTransportBadge(
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
