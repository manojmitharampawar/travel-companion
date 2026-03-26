import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/core/constants/app_constants.dart';
import 'package:travel_companion/core/services/alarm_service.dart';
import 'package:travel_companion/core/services/location_service.dart';
import 'package:travel_companion/core/services/routing_service.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/core/theme/app_theme.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/train_route.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/map/journey_map_widget.dart';
import 'package:travel_companion/features/map/train_journey_map_widget.dart';
import 'package:travel_companion/providers/app_providers.dart';

class JourneyTrackingScreen extends ConsumerStatefulWidget {
  final Journey journey;

  const JourneyTrackingScreen({super.key, required this.journey});

  @override
  ConsumerState<JourneyTrackingScreen> createState() =>
      _JourneyTrackingScreenState();
}

class _JourneyTrackingScreenState extends ConsumerState<JourneyTrackingScreen>
    with SingleTickerProviderStateMixin {
  TrackingState _trackingState = TrackingState.idle;
  double _distanceToDestination = 0;

  /// Legacy route stops (station codes only) — kept for non-train fallback
  List<TrainRoute> _routeStops = [];

  /// Enriched route stops with coordinates — used for train/local-train map
  List<TrainRouteStop> _routeStopsWithCoords = [];

  List<LatLng> _roadRoutePoints = [];
  StreamSubscription<TrackingState>? _stateSub;
  StreamSubscription<double>? _distanceSub;
  StreamSubscription<Position>? _positionSub;
  Position? _currentPosition;
  LocationPoint? _destinationPoint;
  LocationPoint? _originPoint;
  bool _mapExpanded = true; // expanded by default for trains

  /// Index of the next upcoming stop (within _routeStopsWithCoords)
  int _nextStopIndex = 0;

  // Pulse animation for "tracking" state indicator
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // ScrollController for the route strip
  final _stripScrollCtrl = ScrollController();

  TransportType get _type => widget.journey.transportType;
  bool get _isRailType =>
      _type == TransportType.train || _type == TransportType.localTrain;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _resolveLocations();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _distanceSub?.cancel();
    _positionSub?.cancel();
    _pulseController.dispose();
    _stripScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _resolveLocations() async {
    final journey = widget.journey;

    if (journey.destinationLatitude != null &&
        journey.destinationLongitude != null) {
      _destinationPoint = LocationPoint(
        name: journey.destinationName ?? 'Destination',
        latitude: journey.destinationLatitude!,
        longitude: journey.destinationLongitude!,
        stationCode: journey.destinationStationCode,
      );
    } else if (journey.destinationStationCode != null) {
      final station = await ref
          .read(stationRepositoryProvider)
          .getStationByCode(journey.destinationStationCode!);
      if (station != null) _destinationPoint = LocationPoint.fromStation(station);
    }

    if (journey.originLatitude != null && journey.originLongitude != null) {
      _originPoint = LocationPoint(
        name: journey.originName ?? 'Origin',
        latitude: journey.originLatitude!,
        longitude: journey.originLongitude!,
        stationCode: journey.boardingStationCode,
      );
    } else if (journey.boardingStationCode != null) {
      final station = await ref
          .read(stationRepositoryProvider)
          .getStationByCode(journey.boardingStationCode!);
      if (station != null) _originPoint = LocationPoint.fromStation(station);
    }

    if (_destinationPoint == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Destination location data not available')),
        );
      }
      return;
    }
    await _startTracking();
  }

  Future<void> _startTracking() async {
    final alarmService = ref.read(alarmServiceProvider);

    _stateSub = alarmService.stateStream.listen((state) {
      if (mounted) setState(() => _trackingState = state);
    });
    _distanceSub = alarmService.distanceStream.listen((distance) {
      if (mounted) {
        setState(() {
          _distanceToDestination = distance;
          _updateNextStopIndex();
        });
      }
    });
    _positionSub = alarmService.positionStream.listen((position) {
      if (mounted) setState(() => _currentPosition = position);
    });

    if (_isRailType) {
      final j = widget.journey;
      if (j.vehicleNumber != null &&
          j.boardingStationCode != null &&
          j.destinationStationCode != null) {
        // Load enriched stops with coordinates for map rendering
        final stopsWithCoords = await ref
            .read(trainRepositoryProvider)
            .getRouteSegmentWithCoordinates(
              trainNumber: j.vehicleNumber!,
              fromStation: j.boardingStationCode!,
              toStation: j.destinationStationCode!,
            );

        // Also load legacy stops for AlarmService compatibility
        final legacyStops = await ref
            .read(trainRepositoryProvider)
            .getRouteBetweenStations(
              trainNumber: j.vehicleNumber!,
              fromStation: j.boardingStationCode!,
              toStation: j.destinationStationCode!,
            );

        if (mounted) {
          setState(() {
            _routeStopsWithCoords = stopsWithCoords;
            _routeStops = legacyStops;
          });
        }
      }
    }

    // For bus journeys: fetch the actual road route polyline from OSRM.
    if (_type == TransportType.bus &&
        _originPoint != null &&
        _destinationPoint != null) {
      final roadPoints = await RoutingService.fetchRoute(
        origin: LatLng(_originPoint!.latitude, _originPoint!.longitude),
        destination:
            LatLng(_destinationPoint!.latitude, _destinationPoint!.longitude),
        profile: 'driving',
      );
      if (mounted && roadPoints.isNotEmpty) {
        setState(() => _roadRoutePoints = roadPoints);
      }
    }

    await alarmService.startJourneyTracking(
      journey: widget.journey,
      destination: _destinationPoint!,
      origin: _originPoint,
      routeStops: _routeStops,
    );
    if (mounted) setState(() => _trackingState = TrackingState.tracking);
  }

  /// Determines which stop in the route is the "next" one based on
  /// distance from current position to each stop's location.
  void _updateNextStopIndex() {
    if (_routeStopsWithCoords.isEmpty || _currentPosition == null) return;

    // Find the first upcoming stop closer than 3 km (near mode) to advance
    for (var i = _nextStopIndex; i < _routeStopsWithCoords.length - 1; i++) {
      final stop = _routeStopsWithCoords[i];
      final distToStop = LocationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        stop.latitude,
        stop.longitude,
      );
      // If we're within 1.5 km of a stop and it's before the destination,
      // advance the next-stop pointer past it
      if (distToStop < 1500 && i == _nextStopIndex) {
        _nextStopIndex = (i + 1).clamp(0, _routeStopsWithCoords.length - 1);
        _scrollStripToIndex(_nextStopIndex);
        break;
      }
    }
  }

  void _scrollStripToIndex(int index) {
    if (!_stripScrollCtrl.hasClients) return;
    const itemWidth = 80.0;
    final offset = (index * itemWidth - 80).clamp(
        0.0, _stripScrollCtrl.position.maxScrollExtent);
    _stripScrollCtrl.animateTo(offset,
        duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  Color _distanceColor() {
    if (_distanceToDestination <= AppConstants.alertNear(_type)) {
      return AppTheme.dangerColor;
    }
    if (_distanceToDestination <= AppConstants.alertFar(_type)) {
      return AppTheme.warningColor;
    }
    return AppTheme.successColor;
  }

  Color _appBarColor() => _trackingState == TrackingState.approaching
      ? AppTheme.dangerColor
      : _type.color;

  @override
  Widget build(BuildContext context) {
    final distanceKm = (_distanceToDestination / 1000).toStringAsFixed(1);
    final eta = LocationService.estimateTimeToReach(
      _distanceToDestination,
      type: _type,
    );
    final etaText = AppDateUtils.formatDuration(eta);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: _appBarColor(),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_type.label} Tracking',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            if (_destinationPoint != null)
              Text(
                _destinationPoint!.name,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8)),
              ),
          ],
        ),
        actions: [
          // GPS status dot
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _trackingState == TrackingState.tracking
                  ? AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, _) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Icon(
                      _trackingState == TrackingState.idle
                          ? Icons.gps_off_rounded
                          : Icons.gps_fixed_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── State Banner ────────────────────────
          _TrackingStateBanner(state: _trackingState),

          // ── Scrollable Content ──────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  // Dashboard: Distance + ETA side by side
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Distance',
                          value: '$distanceKm km',
                          icon: Icons.near_me_rounded,
                          accentColor: _distanceColor(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          label: 'ETA',
                          value: etaText,
                          icon: Icons.schedule_rounded,
                          accentColor: _type.color,
                          subLabel: 'approx.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Next stop card (rail journeys with coord data)
                  if (_isRailType &&
                      _routeStopsWithCoords.isNotEmpty &&
                      _nextStopIndex < _routeStopsWithCoords.length - 1) ...[
                    _NextStopCard(
                      stop: _routeStopsWithCoords[_nextStopIndex],
                      type: _type,
                    ),
                    const SizedBox(height: 12),
                  ] else if (_destinationPoint != null) ...[
                    _DestinationCard(
                      point: _destinationPoint!,
                      type: _type,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Map section
                  if (_destinationPoint != null) _buildMapSection(),

                  // Horizontal route strip (trains with coord data)
                  if (_isRailType && _routeStopsWithCoords.length > 1) ...[
                    const SizedBox(height: 12),
                    _HorizontalRouteStrip(
                      stops: _routeStopsWithCoords,
                      nextStopIndex: _nextStopIndex,
                      type: _type,
                      scrollController: _stripScrollCtrl,
                    ),
                  ]
                  // Legacy vertical timeline fallback
                  else if (_routeStops.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ModernRouteTimeline(
                        routeStops: _routeStops, type: _type),
                  ] else if (_originPoint != null &&
                      _destinationPoint != null) ...[
                    const SizedBox(height: 12),
                    _SimpleRouteCard(
                      origin: _originPoint!,
                      destination: _destinationPoint!,
                      type: _type,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Sticky Action Bar ───────────────────────
      bottomNavigationBar: _StickyActionBar(
        state: _trackingState,
        type: _type,
        onDismiss: _dismissAlarm,
        onStop: _stopTracking,
      ),
    );
  }

  Widget _buildMapSection() {
    final useTrainMap =
        _isRailType && _routeStopsWithCoords.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Toggle header
          InkWell(
            onTap: () => setState(() => _mapExpanded = !_mapExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _type.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.map_rounded, size: 16, color: _type.color),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _mapExpanded ? 'Hide Map' : 'Show Map',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _type.color),
                  ),
                  if (useTrainMap) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Railway',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _mapExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: _type.color,
                  ),
                ],
              ),
            ),
          ),
          if (_mapExpanded)
            SizedBox(
              height: 300,
              child: useTrainMap
                  ? TrainJourneyMapWidget(
                      origin: _originPoint,
                      destination: _destinationPoint!,
                      currentPosition: _currentPosition,
                      routeStops: _routeStopsWithCoords,
                      nextStopIndex: _nextStopIndex,
                    )
                  : JourneyMapWidget(
                      origin: _originPoint,
                      destination: _destinationPoint!,
                      currentPosition: _currentPosition,
                      routeStops: _routeStops,
                      transportType: _type,
                      roadRoutePoints: _roadRoutePoints,
                    ),
            ),
        ],
      ),
    );
  }

  Future<void> _dismissAlarm() async {
    await ref.read(alarmServiceProvider).stopAlarmSound();
  }

  Future<void> _stopTracking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Stop Tracking?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'You will no longer receive arrival alerts for this journey.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Tracking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('Stop'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(alarmServiceProvider).stopTracking();
      if (mounted) Navigator.pop(context);
    }
  }
}

// ─────────────────────────────────────────────
// Tracking State Banner (animated)
// ─────────────────────────────────────────────

class _TrackingStateBanner extends StatelessWidget {
  final TrackingState state;
  const _TrackingStateBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final (color, icon, text) = switch (state) {
      TrackingState.idle =>
        (Colors.grey.shade600, Icons.gps_off_rounded, 'Initializing...'),
      TrackingState.tracking => (
          AppTheme.successColor,
          Icons.gps_fixed_rounded,
          'Tracking your journey'
        ),
      TrackingState.approaching => (
          AppTheme.dangerColor,
          Icons.warning_rounded,
          'APPROACHING DESTINATION!'
        ),
      TrackingState.arrived => (
          AppTheme.primaryColor,
          Icons.check_circle_rounded,
          'You have arrived!'
        ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(icon, color: Colors.white, size: 17, key: ValueKey(state)),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Metric Card (Distance / ETA)
// ─────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subLabel;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
              if (subLabel != null) ...[
                const SizedBox(width: 4),
                Text(
                  subLabel!,
                  style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Next Stop Card (rail journeys)
// ─────────────────────────────────────────────

class _NextStopCard extends StatelessWidget {
  final TrainRouteStop stop;
  final TransportType type;

  const _NextStopCard({required this.stop, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.train_rounded, size: 20, color: Colors.orange.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Next Stop',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4)),
                Text(
                  stop.stationName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  stop.stationCode,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (stop.timeDisplay.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Arr.',
                    style: TextStyle(
                        fontSize: 10, color: AppTheme.textSecondary)),
                Text(
                  stop.timeDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Destination Card
// ─────────────────────────────────────────────

class _DestinationCard extends StatelessWidget {
  final LocationPoint point;
  final TransportType type;

  const _DestinationCard({required this.point, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.place_rounded,
                size: 20, color: AppTheme.dangerColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Destination',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4)),
                Text(
                  point.name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Horizontal Route Strip
// ─────────────────────────────────────────────

class _HorizontalRouteStrip extends StatelessWidget {
  final List<TrainRouteStop> stops;
  final int nextStopIndex;
  final TransportType type;
  final ScrollController scrollController;

  const _HorizontalRouteStrip({
    required this.stops,
    required this.nextStopIndex,
    required this.type,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.route_rounded, size: 14, color: type.color),
              ),
              const SizedBox(width: 8),
              Text(
                'Route · ${stops.length} stops',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: type.color),
              ),
              const Spacer(),
              if (nextStopIndex > 0)
                Text(
                  '$nextStopIndex passed',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(stops.length, (i) {
                final stop = stops[i];
                final isPassed = i < nextStopIndex;
                final isNext = i == nextStopIndex;
                final isFirst = i == 0;
                final isLast = i == stops.length - 1;

                return _StripNode(
                  stop: stop,
                  isPassed: isPassed,
                  isNext: isNext,
                  isFirst: isFirst,
                  isLast: isLast,
                  accentColor: type.color,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripNode extends StatelessWidget {
  final TrainRouteStop stop;
  final bool isPassed;
  final bool isNext;
  final bool isFirst;
  final bool isLast;
  final Color accentColor;

  const _StripNode({
    required this.stop,
    required this.isPassed,
    required this.isNext,
    required this.isFirst,
    required this.isLast,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isNext
        ? Colors.orange.shade700
        : isPassed
            ? Colors.grey.shade400
            : isFirst
                ? Colors.green.shade600
                : isLast
                    ? AppTheme.dangerColor
                    : accentColor.withValues(alpha: 0.6);

    final dotSize = isNext || isFirst || isLast ? 12.0 : 8.0;

    final labelColor = isNext
        ? Colors.orange.shade700
        : isPassed
            ? Colors.grey.shade400
            : isFirst || isLast
                ? Colors.black87
                : Colors.grey.shade700;

    return SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Connector row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isFirst)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isPassed
                        ? Colors.grey.shade300
                        : accentColor.withValues(alpha: 0.25),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  border: (isNext || isFirst || isLast)
                      ? Border.all(color: Colors.white, width: 1.5)
                      : null,
                  boxShadow: isNext
                      ? [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.4),
                            blurRadius: 6,
                          )
                        ]
                      : null,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isPassed
                        ? Colors.grey.shade300
                        : accentColor.withValues(alpha: 0.25),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 6),
          // Station code
          Text(
            stop.stationCode,
            style: TextStyle(
              fontSize: isNext ? 11 : 10,
              fontWeight:
                  isNext || isFirst || isLast ? FontWeight.w700 : FontWeight.w500,
              color: labelColor,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          if (isNext)
            Text(
              '← Next',
              style: TextStyle(
                  fontSize: 9,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Modern Route Timeline (legacy / no-coord fallback)
// ─────────────────────────────────────────────

class _ModernRouteTimeline extends StatelessWidget {
  final List<TrainRoute> routeStops;
  final TransportType type;

  const _ModernRouteTimeline({required this.routeStops, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.route_rounded, size: 14, color: type.color),
              ),
              const SizedBox(width: 8),
              Text(
                'Route · ${routeStops.length} stops',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: type.color),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: routeStops.length,
            itemBuilder: (_, i) {
              final stop = routeStops[i];
              final isFirst = i == 0;
              final isLast = i == routeStops.length - 1;
              final isTerminal = isFirst || isLast;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 20,
                      child: Column(
                        children: [
                          Container(
                            width: isTerminal ? 12 : 8,
                            height: isTerminal ? 12 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFirst
                                  ? AppTheme.successColor
                                  : isLast
                                      ? AppTheme.dangerColor
                                      : Colors.grey.shade300,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: type.color.withValues(alpha: 0.18),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                stop.stationCode,
                                style: TextStyle(
                                  fontSize: isTerminal ? 14 : 13,
                                  fontWeight: isTerminal
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isTerminal
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            if (stop.departureTime != null ||
                                stop.arrivalTime != null)
                              Text(
                                stop.departureTime ?? stop.arrivalTime!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Simple Route Card (non-train)
// ─────────────────────────────────────────────

class _SimpleRouteCard extends StatelessWidget {
  final LocationPoint origin;
  final LocationPoint destination;
  final TransportType type;

  const _SimpleRouteCard({
    required this.origin,
    required this.destination,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppTheme.successColor)),
              Container(width: 2, height: 30, color: Colors.grey.shade300),
              Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppTheme.dangerColor)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(origin.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 18),
                Text(destination.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: type.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(type.icon, size: 20, color: type.color),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sticky Action Bar
// ─────────────────────────────────────────────

class _StickyActionBar extends StatelessWidget {
  final TrackingState state;
  final TransportType type;
  final VoidCallback onDismiss;
  final VoidCallback onStop;

  const _StickyActionBar({
    required this.state,
    required this.type,
    required this.onDismiss,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state == TrackingState.approaching) ...[
                FilledButton.icon(
                  onPressed: onDismiss,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.dangerColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.alarm_off_rounded),
                  label: const Text("I'm Awake! Dismiss Alarm"),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: onStop,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: type.color, width: 1.5),
                  foregroundColor: type.color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Stop Tracking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
