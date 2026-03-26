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
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/map/journey_map_widget.dart';
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
  List<TrainRoute> _routeStops = [];
  List<LatLng> _roadRoutePoints = [];
  StreamSubscription<TrackingState>? _stateSub;
  StreamSubscription<double>? _distanceSub;
  StreamSubscription<Position>? _positionSub;
  Position? _currentPosition;
  LocationPoint? _destinationPoint;
  LocationPoint? _originPoint;
  bool _mapExpanded = false;

  // Pulse animation for "tracking" state indicator
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  TransportType get _type => widget.journey.transportType;

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
      if (mounted) setState(() => _distanceToDestination = distance);
    });
    _positionSub = alarmService.positionStream.listen((position) {
      if (mounted) setState(() => _currentPosition = position);
    });

    if (_type == TransportType.train || _type == TransportType.localTrain) {
      final j = widget.journey;
      if (j.vehicleNumber != null &&
          j.boardingStationCode != null &&
          j.destinationStationCode != null) {
        final stops = await ref.read(trainRepositoryProvider).getRouteBetweenStations(
              trainNumber: j.vehicleNumber!,
              fromStation: j.boardingStationCode!,
              toStation: j.destinationStationCode!,
            );
        if (mounted) setState(() => _routeStops = stops);
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

                  // Destination card
                  if (_destinationPoint != null)
                    _DestinationCard(
                      point: _destinationPoint!,
                      type: _type,
                    ),
                  const SizedBox(height: 12),

                  // Map section (expandable)
                  if (_destinationPoint != null) _buildMapSection(),

                  // Route timeline
                  if (_routeStops.isNotEmpty) ...[
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
              height: 280,
              child: JourneyMapWidget(
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
      TrackingState.idle => (Colors.grey.shade600, Icons.gps_off_rounded, 'Initializing...'),
      TrackingState.tracking => (AppTheme.successColor, Icons.gps_fixed_rounded, 'Tracking your journey'),
      TrackingState.approaching => (AppTheme.dangerColor, Icons.warning_rounded, 'APPROACHING DESTINATION!'),
      TrackingState.arrived => (AppTheme.primaryColor, Icons.check_circle_rounded, 'You have arrived!'),
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
                      fontSize: 10, color: AppTheme.textSecondary.withValues(alpha: 0.6)),
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
// Modern Route Timeline
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
                      shape: BoxShape.circle,
                      color: AppTheme.successColor)),
              Container(
                  width: 2,
                  height: 30,
                  color: Colors.grey.shade300),
              Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.dangerColor)),
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
