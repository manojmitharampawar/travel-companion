import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
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
import 'package:travel_companion/core/theme/app_icons.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/features/map/fullscreen_map_screen.dart';
import 'package:travel_companion/features/map/journey_map_widget.dart';
import 'package:travel_companion/features/map/train_journey_map_widget.dart';
import 'package:travel_companion/features/journey/widgets/journey_detail_shared_widgets.dart'
    as shared;
import 'package:travel_companion/features/journey/widgets/journey_destination_card.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';
import 'package:travel_companion/features/journey/widgets/journey_route_strip.dart';
import 'package:travel_companion/features/journey/widgets/journey_metric_card.dart';
import 'package:travel_companion/features/journey/widgets/journey_next_stop_card.dart';
import 'package:travel_companion/features/journey/widgets/journey_route_timeline_card.dart';
import 'package:travel_companion/features/journey/widgets/journey_simple_route_card.dart';
import 'package:travel_companion/features/journey/widgets/journey_tracking_action_bar.dart';
import 'package:travel_companion/features/journey/widgets/journey_tracking_background.dart';
import 'package:travel_companion/features/journey/widgets/journey_tracking_state_banner.dart';
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
          JourneyTrackingBackground(
            accentColor: _type.color,
            isApproaching: _trackingState == TrackingState.approaching,
          ),

          Column(
            children: [
              // ── Glass AppBar ────────────────────────
              _buildGlassAppBar(context),

              // ── State Banner ────────────────────────
              JourneyTrackingStateBanner(state: _trackingState),

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
                            child: JourneyMetricCard(
                              label: 'Distance',
                              value: '$distanceKm km',
                              icon: AppIcons.nearMeRounded,
                              accentColor: _distanceColor(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: JourneyMetricCard(
                              label: 'ETA',
                              value: etaText,
                              icon: AppIcons.scheduleRounded,
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
                        JourneyNextStopCard(
                          stop: _routeStopsWithCoords[_nextStopIndex],
                          type: _type,
                        ),
                        const SizedBox(height: 12),
                      ] else if (_destinationPoint != null) ...[
                        JourneyDestinationCard(
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
                        JourneyHorizontalRouteStrip(
                          stops: _routeStopsWithCoords,
                          nextStopIndex: _nextStopIndex,
                          type: _type,
                          scrollController: _stripScrollCtrl,
                        ),
                      ] else if (_routeStops.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        JourneyRouteTimeline(
                          routeStops: _routeStops,
                          type: _type,
                        ),
                      ] else if (_originPoint != null &&
                          _destinationPoint != null) ...[
                        const SizedBox(height: 12),
                        JourneySimpleRouteCard(
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
            child: JourneyTrackingActionBar(
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
    return TransportFormAppBar(
      title: '${_type.label} Tracking',
      subtitle: _destinationPoint != null
          ? 'To: ${_destinationPoint!.name}'
          : null,
      trailing: _trackingState == TrackingState.tracking
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
                        color: const Color(0xFF27AE60).withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Icon(
              _trackingState == TrackingState.idle
                  ? CupertinoIcons.location_slash
                  : CupertinoIcons.location_fill,
              size: 18,
              color: g.textAlpha(0.6),
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
              GestureDetector(
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
                          AppIcons.mapRounded,
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
                            ? AppIcons.expandLessRounded
                            : AppIcons.expandMoreRounded,
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
      builder: (context) => shared.GlassConfirmDialog(
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
