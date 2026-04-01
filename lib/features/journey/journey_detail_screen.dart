import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/ui/adaptive_navigation.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/local_train_schedule.dart';
import 'package:travel_companion/data/models/metro_station.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/features/journey/application/actions/journey_detail_actions.dart';
import 'package:travel_companion/features/home/home_provider.dart';

import 'package:travel_companion/features/journey/edit_journey_screen.dart';
import 'package:travel_companion/features/journey/widgets/journey_detail_background.dart';
import 'package:travel_companion/features/journey/widgets/journey_detail_shared_widgets.dart'
    as shared;
import 'package:travel_companion/features/journey/widgets/journey_route_card.dart';
import 'package:travel_companion/features/journey/widgets/journey_sliver_header.dart';
import 'package:travel_companion/features/journey/widgets/journey_stop_timeline_item.dart';
import 'package:travel_companion/providers/app_providers.dart';

class JourneyDetailScreen extends ConsumerStatefulWidget {
  final EnrichedJourney enrichedJourney;

  const JourneyDetailScreen({super.key, required this.enrichedJourney});

  @override
  ConsumerState<JourneyDetailScreen> createState() =>
      _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends ConsumerState<JourneyDetailScreen> {
  // Route stops data for train/metro/local train
  List<TrainRouteStop> _trainStops = [];
  List<MetroStation> _metroStops = [];
  List<LocalTrainStation> _localTrainStops = [];
  bool _isLoadingStops = false;
  bool _stopsExpanded = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.enrichedJourney.journey.isFavorite;
    _loadRouteStops();
  }

  @override
  void didUpdateWidget(covariant JourneyDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enrichedJourney.journey.isFavorite !=
        widget.enrichedJourney.journey.isFavorite) {
      _isFavorite = widget.enrichedJourney.journey.isFavorite;
    }
  }

  Future<void> _toggleFavorite(Journey journey) async {
    final next = await JourneyDetailActions.toggleFavorite(
      ref: ref,
      journey: journey,
      currentValue: _isFavorite,
    );

    if (!mounted) return;
    setState(() => _isFavorite = next);
  }

  Future<void> _loadRouteStops() async {
    final journey = widget.enrichedJourney.journey;
    final type = journey.transportType;

    if (journey.boardingStationCode == null ||
        journey.destinationStationCode == null) {
      return;
    }

    setState(() => _isLoadingStops = true);

    try {
      if (type == TransportType.train ||
          type == TransportType.localTrain && journey.vehicleNumber != null) {
        if (type == TransportType.train) {
          // Train: use train repository to get route segment
          final trainRepo = ref.read(trainRepositoryProvider);
          final stops = await trainRepo.getRouteSegmentWithCoordinates(
            trainNumber: journey.vehicleNumber ?? '',
            fromStation: journey.boardingStationCode!,
            toStation: journey.destinationStationCode!,
          );
          if (mounted) setState(() => _trainStops = stops);
        }
      }

      if (type == TransportType.metro) {
        // Metro: look up boarding station to get lineId, then get route
        final metroRepo = ref.read(metroRepositoryProvider);
        final boardingStation = await metroRepo.getStationByCode(
          journey.boardingStationCode!,
        );
        if (boardingStation != null) {
          final stops = await metroRepo.getStationRoute(
            lineId: boardingStation.lineId,
            startCode: journey.boardingStationCode!,
            endCode: journey.destinationStationCode!,
          );
          if (mounted) setState(() => _metroStops = stops);
        }
      }

      if (type == TransportType.localTrain) {
        // Local train: look up station to get lineId, then get all stations and slice
        final localRepo = ref.read(localTrainRepositoryProvider);
        // Search for the boarding station to find its lineId
        final stations = await localRepo.searchStations(
          journey.boardingStationCode!,
        );
        if (stations.isNotEmpty) {
          final lineId = stations.first.lineId;
          final allStations = await localRepo.getStationsForLine(lineId);

          // Find indices for boarding and destination
          int? fromIdx, toIdx;
          for (var i = 0; i < allStations.length; i++) {
            if (allStations[i].code == journey.boardingStationCode) {
              fromIdx = i;
            }
            if (allStations[i].code == journey.destinationStationCode) {
              toIdx = i;
            }
          }
          if (fromIdx != null && toIdx != null) {
            if (fromIdx > toIdx) {
              final tmp = fromIdx;
              fromIdx = toIdx;
              toIdx = tmp;
            }
            final stops = allStations.sublist(fromIdx, toIdx + 1);
            if (mounted) setState(() => _localTrainStops = stops);
          }
        }
      }
    } catch (_) {
      // Silently fail — stops section just won't show
    }

    if (mounted) setState(() => _isLoadingStops = false);
  }

  bool get _hasRouteStops =>
      _trainStops.isNotEmpty ||
      _metroStops.isNotEmpty ||
      _localTrainStops.isNotEmpty;

  int get _stopsCount {
    if (_trainStops.isNotEmpty) return _trainStops.length;
    if (_metroStops.isNotEmpty) return _metroStops.length;
    if (_localTrainStops.isNotEmpty) return _localTrainStops.length;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final enrichedJourney = widget.enrichedJourney;
    final journey = enrichedJourney.journey;
    final type = journey.transportType;
    final accentColor = type.color;

    final g = GlassColors.of(context);

    return CupertinoPageScaffold(
      backgroundColor: g.bg,
      child: Stack(
        children: [
          // Background orbs
          JourneyDetailBackground(accentColor: accentColor),

          CustomScrollView(
            slivers: [
              // ── Glass Compact AppBar ──────────────────
              JourneySliverHeader(
                title:
                    journey.vehicleName ??
                    (journey.vehicleNumber != null
                        ? '${type.label} ${journey.vehicleNumber}'
                        : type.label),
                subtitle: AppDateUtils.relativeDay(journey.journeyDate),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    shared.GlassFavoriteActionButton(
                      isFavorite: _isFavorite,
                      onToggle: () => _toggleFavorite(journey),
                    ),
                    if (journey.isUpcoming)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            adaptivePageRoute(
                              EditJourneyScreen(journey: journey),
                            ),
                          );
                          if (result == true && context.mounted) {
                            ref.invalidate(upcomingJourneysProvider);
                            Navigator.pop(context);
                          }
                        },
                        child: Icon(
                          CupertinoIcons.pencil,
                          color: g.text,
                          size: 20,
                        ),
                      ),
                    if (journey.isUpcoming)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: () =>
                            JourneyDetailActions.showJourneyActions(
                              context: context,
                              ref: ref,
                              journey: journey,
                              cancelLabel: 'Cancel Journey',
                            ),
                        child: Icon(
                          CupertinoIcons.ellipsis_circle,
                          color: g.text,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    JourneyRouteCard(
                      enrichedJourney: enrichedJourney,
                      journey: journey,
                      type: type,
                    ),
                    const SizedBox(height: 12),

                    // Route Stops section (train/metro/local train)
                    if (_isLoadingStops)
                      _buildStopsLoadingIndicator(accentColor)
                    else if (_hasRouteStops)
                      _buildRouteStopsCard(journey, type),

                    if (_hasRouteStops || _isLoadingStops)
                      const SizedBox(height: 12),

                    shared.GlassInfoGrid(journey: journey, type: type),
                  ]),
                ),
              ),
            ],
          ),
          if (journey.isUpcoming || journey.isActive)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: shared.GlassBottomCta(
                journey: journey,
                enrichedJourney: enrichedJourney,
                type: type,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStopsLoadingIndicator(Color accentColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: GlassColors.of(context).cardFill(),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GlassColors.of(context).border()),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CupertinoActivityIndicator(
                  color: accentColor,
                  radius: 8,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading route stops...',
                style: TextStyle(
                  fontSize: 13,
                  color: GlassColors.of(context).textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteStopsCard(Journey journey, TransportType type) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: GlassColors.of(context).cardFill(),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GlassColors.of(context).border()),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _stopsExpanded = !_stopsExpanded),
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
                          color: type.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          CupertinoIcons.map_pin_ellipse,
                          size: 16,
                          color: type.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ROUTE STOPS',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: type.color,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: type.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: type.color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$_stopsCount stops',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: type.color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _stopsExpanded
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        color: type.color,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Stops list
              if (_stopsExpanded)
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  child: _buildStopsList(journey, type),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStopsList(Journey journey, TransportType type) {
    if (_trainStops.isNotEmpty) {
      return _buildTrainStopsList(type);
    } else if (_metroStops.isNotEmpty) {
      return _buildMetroStopsList(type);
    } else if (_localTrainStops.isNotEmpty) {
      return _buildLocalTrainStopsList(type);
    }
    return const SizedBox.shrink();
  }

  Widget _buildTrainStopsList(TransportType type) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: List.generate(_trainStops.length, (i) {
          final stop = _trainStops[i];
          final isFirst = i == 0;
          final isLast = i == _trainStops.length - 1;
          return JourneyStopTimelineItem(
            name: stop.stationName,
            code: stop.stationCode,
            time: stop.timeDisplay,
            distanceKm: stop.distanceKm,
            isFirst: isFirst,
            isLast: isLast,
            accentColor: type.color,
          );
        }),
      ),
    );
  }

  Widget _buildMetroStopsList(TransportType type) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: List.generate(_metroStops.length, (i) {
          final stop = _metroStops[i];
          final isFirst = i == 0;
          final isLast = i == _metroStops.length - 1;
          return JourneyStopTimelineItem(
            name: stop.name,
            code: stop.code,
            isFirst: isFirst,
            isLast: isLast,
            accentColor: type.color,
          );
        }),
      ),
    );
  }

  Widget _buildLocalTrainStopsList(TransportType type) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: List.generate(_localTrainStops.length, (i) {
          final stop = _localTrainStops[i];
          final isFirst = i == 0;
          final isLast = i == _localTrainStops.length - 1;
          return JourneyStopTimelineItem(
            name: stop.name,
            code: stop.code,
            isFirst: isFirst,
            isLast: isLast,
            accentColor: type.color,
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Background Orbs
// ─────────────────────────────────────────────
