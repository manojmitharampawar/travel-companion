import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/core/constants/app_constants.dart';
import 'package:travel_companion/core/services/alarm_service.dart';
import 'package:travel_companion/core/services/location_service.dart';
import 'package:travel_companion/core/services/routing_service.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/core/ui/adaptive_navigation.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/train_route.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/features/map/fullscreen_map_screen.dart';
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

  List<TrainRoute> _routeStops = [];
  List<TrainRouteStop> _routeStopsWithCoords = [];
  List<LatLng> _roadRoutePoints = [];
  StreamSubscription<TrackingState>? _stateSub;
  StreamSubscription<double>? _distanceSub;
  StreamSubscription<Position>? _positionSub;
  Position? _currentPosition;
  LocationPoint? _destinationPoint;
  LocationPoint? _originPoint;
  bool _mapExpanded = true;

  int _nextStopIndex = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

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
      if (station != null) {
        _destinationPoint = LocationPoint.fromStation(station);
      }
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
        AdaptiveFeedback.showToast(
          context,
          'Destination location data not available',
          isError: true,
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
        final stopsWithCoords = await ref
            .read(trainRepositoryProvider)
            .getRouteSegmentWithCoordinates(
              trainNumber: j.vehicleNumber!,
              fromStation: j.boardingStationCode!,
              toStation: j.destinationStationCode!,
            );

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

    if (_type == TransportType.bus &&
        _originPoint != null &&
        _destinationPoint != null) {
      final routeResult = await RoutingService.fetchRoute(
        origin: LatLng(_originPoint!.latitude, _originPoint!.longitude),
        destination: LatLng(
          _destinationPoint!.latitude,
          _destinationPoint!.longitude,
        ),
        profile: 'driving',
      );
      if (mounted && routeResult.isNotEmpty) {
        setState(() => _roadRoutePoints = routeResult.points);
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

  void _updateNextStopIndex() {
    if (_routeStopsWithCoords.isEmpty || _currentPosition == null) return;

    for (var i = _nextStopIndex; i < _routeStopsWithCoords.length - 1; i++) {
      final stop = _routeStopsWithCoords[i];
      final distToStop = LocationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        stop.latitude,
        stop.longitude,
      );
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
      0.0,
      _stripScrollCtrl.position.maxScrollExtent,
    );
    _stripScrollCtrl.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  Color _distanceColor() {
    if (_distanceToDestination <= AppConstants.alertNear(_type)) {
      return const Color(0xFFE74C3C);
    }
    if (_distanceToDestination <= AppConstants.alertFar(_type)) {
      return const Color(0xFFF39C12);
    }
    return const Color(0xFF27AE60);
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = (_distanceToDestination / 1000).toStringAsFixed(1);
    final eta = LocationService.estimateTimeToReach(
      _distanceToDestination,
      type: _type,
    );
    final etaText = AppDateUtils.formatDuration(eta);

    final g = GlassColors.of(context);

    return CupertinoPageScaffold(
      backgroundColor: g.bg,
      child: Stack(
        children: [
          // Background orbs
          _TrackingBackground(
            accentColor: _type.color,
            isApproaching: _trackingState == TrackingState.approaching,
          ),

          Column(
            children: [
              // ── Glass AppBar ────────────────────────
              _buildGlassAppBar(context),

              // ── State Banner ────────────────────────
              _GlassTrackingStateBanner(state: _trackingState),

              // ── Scrollable Content ──────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    children: [
                      // Dashboard: Distance + ETA
                      Row(
                        children: [
                          Expanded(
                            child: _GlassMetricCard(
                              label: 'Distance',
                              value: '$distanceKm km',
                              icon: Icons.near_me_rounded,
                              accentColor: _distanceColor(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _GlassMetricCard(
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
                          _nextStopIndex <
                              _routeStopsWithCoords.length - 1) ...[
                        _GlassNextStopCard(
                          stop: _routeStopsWithCoords[_nextStopIndex],
                          type: _type,
                        ),
                        const SizedBox(height: 12),
                      ] else if (_destinationPoint != null) ...[
                        _GlassDestinationCard(
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
                        _GlassHorizontalRouteStrip(
                          stops: _routeStopsWithCoords,
                          nextStopIndex: _nextStopIndex,
                          type: _type,
                          scrollController: _stripScrollCtrl,
                        ),
                      ] else if (_routeStops.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _GlassRouteTimeline(
                          routeStops: _routeStops,
                          type: _type,
                        ),
                      ] else if (_originPoint != null &&
                          _destinationPoint != null) ...[
                        const SizedBox(height: 12),
                        _GlassSimpleRouteCard(
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _GlassStickyActionBar(
              state: _trackingState,
              type: _type,
              onDismiss: _dismissAlarm,
              onStop: _stopTracking,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar(BuildContext context) {
    final g = GlassColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(8, topPad, 8, 8),
          decoration: BoxDecoration(
            color: _trackingState == TrackingState.approaching
                ? const Color(0xFFE74C3C).withValues(alpha: 0.15)
                : _type.color.withValues(alpha: 0.1),
            border: Border(bottom: BorderSide(color: g.border(0.08), width: 1)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: g.appBarForeground),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_type.label} Tracking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: g.appBarForeground,
                      ),
                    ),
                    if (_destinationPoint != null)
                      Text(
                        _destinationPoint!.name,
                        style: TextStyle(fontSize: 12, color: g.textAlpha(0.6)),
                      ),
                  ],
                ),
              ),
              // GPS status dot
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _trackingState == TrackingState.tracking
                    ? AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, _) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF27AE60),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF27AE60,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        _trackingState == TrackingState.idle
                            ? Icons.gps_off_rounded
                            : Icons.gps_fixed_rounded,
                        size: 18,
                        color: g.textAlpha(0.6),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullscreenMap({required bool useTrainMap}) {
    Navigator.of(context).push(
      adaptivePageRoute(
        FullscreenMapScreen(
          origin: _originPoint,
          destination: _destinationPoint!,
          currentPosition: _currentPosition,
          transportType: _type,
          useTrainMap: useTrainMap,
          routeStops: _routeStops,
          roadRoutePoints: _roadRoutePoints,
          trainRouteStops: _routeStopsWithCoords,
          nextStopIndex: _nextStopIndex,
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    final useTrainMap = _isRailType && _routeStopsWithCoords.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: GlassColors.of(context).cardFill(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GlassColors.of(context).border(0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Toggle header
              InkWell(
                onTap: () => setState(() => _mapExpanded = !_mapExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _type.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.map_rounded,
                          size: 16,
                          color: _type.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _mapExpanded ? 'Hide Map' : 'Show Map',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _type.color,
                        ),
                      ),
                      if (useTrainMap) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1565C0,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(
                                0xFF1565C0,
                              ).withValues(alpha: 0.3),
                            ),
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
                          onFullscreen: () =>
                              _openFullscreenMap(useTrainMap: true),
                        )
                      : JourneyMapWidget(
                          origin: _originPoint,
                          destination: _destinationPoint!,
                          currentPosition: _currentPosition,
                          routeStops: _routeStops,
                          transportType: _type,
                          roadRoutePoints: _roadRoutePoints,
                          onFullscreen: () =>
                              _openFullscreenMap(useTrainMap: false),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _dismissAlarm() async {
    await ref.read(alarmServiceProvider).stopAlarmSound();
  }

  Future<void> _stopTracking() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => _GlassConfirmDialog(
        title: 'Stop Tracking?',
        message: 'You will no longer receive arrival alerts for this journey.',
        confirmLabel: 'Stop',
        confirmColor: const Color(0xFFE74C3C),
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirm == true) {
      await ref.read(alarmServiceProvider).stopTracking();
      if (mounted) Navigator.pop(context);
    }
  }
}

// ─────────────────────────────────────────────
// Background Orbs
// ─────────────────────────────────────────────

class _TrackingBackground extends StatelessWidget {
  final Color accentColor;
  final bool isApproaching;

  const _TrackingBackground({
    required this.accentColor,
    this.isApproaching = false,
  });

  @override
  Widget build(BuildContext context) {
    final alertColor = isApproaching ? const Color(0xFFE74C3C) : accentColor;
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -80,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  alertColor.withValues(alpha: 0.15),
                  alertColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          left: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accentColor.withValues(alpha: 0.08),
                  accentColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        if (isApproaching)
          Positioned(
            bottom: 80,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE74C3C).withValues(alpha: 0.12),
                    const Color(0xFFE74C3C).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Glass Tracking State Banner
// ─────────────────────────────────────────────

class _GlassTrackingStateBanner extends StatelessWidget {
  final TrackingState state;
  const _GlassTrackingStateBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final (color, icon, text) = switch (state) {
      TrackingState.idle => (
        Colors.grey.shade600,
        Icons.gps_off_rounded,
        'Initializing...',
      ),
      TrackingState.tracking => (
        const Color(0xFF27AE60),
        Icons.gps_fixed_rounded,
        'Tracking your journey',
      ),
      TrackingState.approaching => (
        const Color(0xFFE74C3C),
        Icons.warning_rounded,
        'APPROACHING DESTINATION!',
      ),
      TrackingState.arrived => (
        const Color(0xFF3498DB),
        Icons.check_circle_rounded,
        'You have arrived!',
      ),
    };

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            border: Border(
              bottom: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(icon, color: color, size: 17, key: ValueKey(state)),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Metric Card
// ─────────────────────────────────────────────

class _GlassMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subLabel;

  const _GlassMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: g.cardFill(),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: g.border(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: g.textAlpha(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      subLabel!,
                      style: TextStyle(fontSize: 10, color: g.textAlpha(0.3)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Next Stop Card
// ─────────────────────────────────────────────

class _GlassNextStopCard extends StatelessWidget {
  final TrainRouteStop stop;
  final TransportType type;

  const _GlassNextStopCard({required this.stop, required this.type});

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final orangeAccent = g.statusWarning;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: orangeAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: orangeAccent.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: orangeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.train_rounded, size: 20, color: orangeAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Stop',
                      style: TextStyle(
                        fontSize: 11,
                        color: GlassColors.of(context).textAlpha(0.5),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      stop.stationName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: GlassColors.of(context).textAlpha(0.9),
                      ),
                    ),
                    Text(
                      stop.stationCode,
                      style: TextStyle(
                        fontSize: 12,
                        color: GlassColors.of(context).textAlpha(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (stop.timeDisplay.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Arr.',
                      style: TextStyle(
                        fontSize: 10,
                        color: GlassColors.of(context).textAlpha(0.4),
                      ),
                    ),
                    const Text('', style: TextStyle(fontSize: 0)),
                    Text(
                      stop.timeDisplay,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: orangeAccent,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Destination Card
// ─────────────────────────────────────────────

class _GlassDestinationCard extends StatelessWidget {
  final LocationPoint point;
  final TransportType type;

  const _GlassDestinationCard({required this.point, required this.type});

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final dangerColor = g.statusDanger;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: dangerColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: dangerColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: dangerColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.place_rounded, size: 20, color: dangerColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Destination',
                      style: TextStyle(
                        fontSize: 11,
                        color: GlassColors.of(context).textAlpha(0.5),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      point.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: GlassColors.of(context).textAlpha(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Horizontal Route Strip
// ─────────────────────────────────────────────

class _GlassHorizontalRouteStrip extends StatelessWidget {
  final List<TrainRouteStop> stops;
  final int nextStopIndex;
  final TransportType type;
  final ScrollController scrollController;

  const _GlassHorizontalRouteStrip({
    required this.stops,
    required this.nextStopIndex,
    required this.type,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: g.cardFill(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: g.border(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.route_rounded,
                      size: 14,
                      color: type.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Route · ${stops.length} stops',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: type.color,
                    ),
                  ),
                  const Spacer(),
                  if (nextStopIndex > 0)
                    Text(
                      '$nextStopIndex passed',
                      style: TextStyle(fontSize: 11, color: g.textAlpha(0.4)),
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

                    return _GlassStripNode(
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
        ),
      ),
    );
  }
}

class _GlassStripNode extends StatelessWidget {
  final TrainRouteStop stop;
  final bool isPassed;
  final bool isNext;
  final bool isFirst;
  final bool isLast;
  final Color accentColor;

  const _GlassStripNode({
    required this.stop,
    required this.isPassed,
    required this.isNext,
    required this.isFirst,
    required this.isLast,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final orangeAccent = g.statusWarning;
    final dotColor = isNext
        ? orangeAccent
        : isPassed
        ? Colors.white.withValues(alpha: 0.25)
        : isFirst
        ? g.statusSuccess
        : isLast
        ? g.statusDanger
        : accentColor.withValues(alpha: 0.6);

    final dotSize = isNext || isFirst || isLast ? 12.0 : 8.0;

    final labelColor = isNext
        ? orangeAccent
        : isPassed
        ? Colors.white.withValues(alpha: 0.3)
        : isFirst || isLast
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.5);

    return SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isFirst)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isPassed
                        ? Colors.white.withValues(alpha: 0.15)
                        : accentColor.withValues(alpha: 0.2),
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
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        )
                      : null,
                  boxShadow: isNext
                      ? [
                          BoxShadow(
                            color: orangeAccent.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isPassed
                        ? Colors.white.withValues(alpha: 0.15)
                        : accentColor.withValues(alpha: 0.2),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            stop.stationCode,
            style: TextStyle(
              fontSize: isNext ? 11 : 10,
              fontWeight: isNext || isFirst || isLast
                  ? FontWeight.w700
                  : FontWeight.w500,
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
                color: orangeAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Route Timeline (legacy fallback)
// ─────────────────────────────────────────────

class _GlassRouteTimeline extends StatelessWidget {
  final List<TrainRoute> routeStops;
  final TransportType type;

  const _GlassRouteTimeline({required this.routeStops, required this.type});

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: g.cardFill(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: g.border(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.route_rounded,
                      size: 14,
                      color: type.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Route · ${routeStops.length} stops',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: type.color,
                    ),
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
                                      ? const Color(0xFF27AE60)
                                      : isLast
                                      ? const Color(0xFFE74C3C)
                                      : Colors.white.withValues(alpha: 0.25),
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
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                                if (stop.departureTime != null ||
                                    stop.arrivalTime != null)
                                  Text(
                                    stop.departureTime ?? stop.arrivalTime!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
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
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Simple Route Card (non-train)
// ─────────────────────────────────────────────

class _GlassSimpleRouteCard extends StatelessWidget {
  final LocationPoint origin;
  final LocationPoint destination;
  final TransportType type;

  const _GlassSimpleRouteCard({
    required this.origin,
    required this.destination,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: g.cardFill(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: g.border(0.1)),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF27AE60),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF27AE60).withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 30,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE74C3C),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE74C3C).withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      origin.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: g.textAlpha(0.9),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      destination.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: g.textAlpha(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(type.icon, size: 20, color: type.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Sticky Action Bar
// ─────────────────────────────────────────────

class _GlassStickyActionBar extends StatelessWidget {
  final TrackingState state;
  final TransportType type;
  final VoidCallback onDismiss;
  final VoidCallback onStop;

  const _GlassStickyActionBar({
    required this.state,
    required this.type,
    required this.onDismiss,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: g.bg.withValues(alpha: 0.85),
            border: Border(top: BorderSide(color: g.border(0.1), width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state == TrackingState.approaching) ...[
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFE74C3C,
                            ).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: onDismiss,
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.bell_slash_fill,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "I'm Awake! Dismiss Alarm",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: type.color.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: onStop,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.stop_circle, color: type.color),
                            const SizedBox(width: 8),
                            Text(
                              'Stop Tracking',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: type.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Confirm Dialog
// ─────────────────────────────────────────────

class _GlassConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _GlassConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return CupertinoAlertDialog(
      title: Text(
        title,
        style: TextStyle(color: g.text, fontWeight: FontWeight.w700),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message, style: TextStyle(color: g.textAlpha(0.8))),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: onCancel,
          child: Text(
            'Keep Tracking',
            style: TextStyle(color: g.textAlpha(0.7)),
          ),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: onConfirm,
          child: Text(confirmLabel, style: TextStyle(color: confirmColor)),
        ),
      ],
    );
  }
}
