import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/local_train_schedule.dart';
import 'package:travel_companion/data/models/metro_station.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/history/history_journeys_screen.dart';
import 'package:travel_companion/features/history/favorite_journeys_screen.dart';
import 'package:travel_companion/features/journey/edit_journey_screen.dart';
import 'package:travel_companion/features/journey/journey_tracking_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadRouteStops();
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
      if (type == TransportType.train || type == TransportType.localTrain && journey.vehicleNumber != null) {
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
        final boardingStation =
            await metroRepo.getStationByCode(journey.boardingStationCode!);
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
        final stations =
            await localRepo.searchStations(journey.boardingStationCode!);
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

    return Scaffold(
      backgroundColor: g.bg,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background orbs
          _DetailBackground(accentColor: accentColor),

          CustomScrollView(
            slivers: [
              // ── Glass Hero AppBar ─────────────────────
              Builder(builder: (ctx) {
                final topPad = MediaQuery.paddingOf(ctx).top;
                return SliverAppBar(
                  pinned: true,
                  expandedHeight: topPad + kToolbarHeight + 100,
                  backgroundColor: Colors.transparent,
                  foregroundColor: g.appBarForeground,
                  elevation: 0,
                  actions: [
                    // Favourite toggle
                    _GlassFavoriteActionButton(
                      isFavorite: journey.isFavorite,
                      onToggle: () async {
                        final repo = ref.read(journeyRepositoryProvider);
                        await repo.toggleFavorite(
                            journey.id!, !journey.isFavorite);
                        ref.invalidate(upcomingJourneysProvider);
                        ref.invalidate(historyJourneysProvider);
                        ref.invalidate(favoriteJourneysProvider);
                        if (mounted) setState(() {});
                      },
                    ),
                    if (journey.isUpcoming)
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        tooltip: 'Edit Journey',
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    EditJourneyScreen(journey: journey)),
                          );
                          if (result == true && context.mounted) {
                            ref.invalidate(upcomingJourneysProvider);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    if (journey.isUpcoming)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        color: g.dropdownBg,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) async {
                          if (value == 'delete') {
                            await _deleteJourney(context, ref, journey);
                          } else if (value == 'cancel') {
                            await _cancelJourney(context, ref, journey);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'cancel',
                            child: Row(children: [
                              Icon(Icons.cancel_outlined,
                                  size: 18,
                                  color: g.iconAlpha(0.7)),
                              const SizedBox(width: 8),
                              Text('Cancel Journey',
                                  style: TextStyle(
                                      color: g.textAlpha(0.9))),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Color(0xFFE74C3C)),
                              const SizedBox(width: 8),
                              const Text('Delete',
                                  style:
                                      TextStyle(color: Color(0xFFE74C3C))),
                            ]),
                          ),
                        ],
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: _GlassJourneyHeroBanner(
                      journey: journey,
                      enrichedJourney: enrichedJourney,
                      type: type,
                    ),
                  ),
                );
              }),

              // ── Body ────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _GlassRouteCard(
                        enrichedJourney: enrichedJourney,
                        journey: journey,
                        type: type),
                    const SizedBox(height: 12),

                    // Route Stops section (train/metro/local train)
                    if (_isLoadingStops)
                      _buildStopsLoadingIndicator(accentColor)
                    else if (_hasRouteStops)
                      _buildRouteStopsCard(journey, type),

                    if (_hasRouteStops || _isLoadingStops)
                      const SizedBox(height: 12),

                    _GlassInfoGrid(journey: journey, type: type),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Sticky CTA ──────────────────────────────
      bottomNavigationBar: (journey.isUpcoming || journey.isActive)
          ? _GlassBottomCta(
              journey: journey,
              enrichedJourney: enrichedJourney,
              type: type,
            )
          : null,
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
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
              InkWell(
                onTap: () => setState(() => _stopsExpanded = !_stopsExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: type.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.route_rounded,
                            size: 16, color: type.color),
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
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: type.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: type.color.withValues(alpha: 0.3)),
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
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
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
          return _StopTimelineItem(
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
          return _StopTimelineItem(
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
          return _StopTimelineItem(
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

  Future<void> _deleteJourney(
      BuildContext context, WidgetRef ref, Journey journey) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _GlassConfirmDialog(
        title: 'Delete Journey?',
        message: 'This action cannot be undone.',
        confirmLabel: 'Delete',
        confirmColor: const Color(0xFFE74C3C),
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );
    if (confirm != true) return;
    await ref.read(journeyRepositoryProvider).deleteJourney(journey.id!);
    ref.invalidate(upcomingJourneysProvider);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _cancelJourney(
      BuildContext context, WidgetRef ref, Journey journey) async {
    await ref
        .read(journeyRepositoryProvider)
        .updateJourneyStatus(journey.id!, JourneyStatus.cancelled);
    ref.invalidate(upcomingJourneysProvider);
    if (context.mounted) Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────
// Background Orbs
// ─────────────────────────────────────────────

class _DetailBackground extends StatelessWidget {
  final Color accentColor;
  const _DetailBackground({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  g.orbAlpha(accentColor, 0.15),
                  accentColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  g.orbAlpha(accentColor, 0.08),
                  accentColor.withValues(alpha: 0.0),
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
// Glass Hero Banner
// ─────────────────────────────────────────────

class _GlassJourneyHeroBanner extends StatelessWidget {
  final Journey journey;
  final EnrichedJourney enrichedJourney;
  final TransportType type;

  const _GlassJourneyHeroBanner({
    required this.journey,
    required this.enrichedJourney,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final accentColor = type.color;

    final vehicleName = journey.vehicleName ??
        (journey.vehicleNumber != null
            ? '${type.label} ${journey.vehicleNumber}'
            : type.label);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.15),
            g.bg,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: g.border(0.06), width: 1),
              ),
            ),
          ),
          Padding(
            padding:
                EdgeInsets.fromLTRB(20, topPad + kToolbarHeight + 6, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Glass icon container
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: g.cardFill(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: g.border(0.15)),
                      ),
                      child: Icon(type.icon, size: 30, color: accentColor),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleName,
                        style: TextStyle(
                          color: g.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (journey.vehicleNumber != null &&
                          journey.vehicleNumber!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          journey.vehicleNumber!,
                          style: TextStyle(
                            color: g.textAlpha(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 11,
                              color: g.textAlpha(0.6)),
                          const SizedBox(width: 4),
                          Text(
                            AppDateUtils.relativeDay(journey.journeyDate),
                            style: TextStyle(
                              color: g.textAlpha(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (journey.scheduledTime != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.schedule_rounded,
                                size: 11,
                                color: g.textAlpha(0.6)),
                            const SizedBox(width: 4),
                            Text(
                              journey.scheduledTime!,
                              style: TextStyle(
                                color: g.textAlpha(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Status pill
                _GlassStatusPill(status: journey.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassStatusPill extends StatelessWidget {
  final JourneyStatus status;
  const _GlassStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      JourneyStatus.upcoming => ('Upcoming', const Color(0xFF3498DB)),
      JourneyStatus.active => ('Active', const Color(0xFF27AE60)),
      JourneyStatus.completed => ('Completed', Colors.grey),
      JourneyStatus.cancelled => ('Cancelled', const Color(0xFFE74C3C)),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Route Card
// ─────────────────────────────────────────────

class _GlassRouteCard extends StatelessWidget {
  final EnrichedJourney enrichedJourney;
  final Journey journey;
  final TransportType type;

  const _GlassRouteCard({
    required this.enrichedJourney,
    required this.journey,
    required this.type,
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
            border:
                Border.all(color: g.border(0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline dots + connector
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF27AE60),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF27AE60)
                              .withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 44,
                    color: type.color.withValues(alpha: 0.25),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE74C3C),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE74C3C)
                              .withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Station labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GlassStationLabel(
                      tag: 'FROM',
                      name: enrichedJourney.boardingName,
                      code: journey.boardingStationCode ?? '',
                      color: const Color(0xFF27AE60),
                    ),
                    const SizedBox(height: 18),
                    _GlassStationLabel(
                      tag: 'TO',
                      name: enrichedJourney.destinationName,
                      code: journey.destinationStationCode ?? '',
                      color: const Color(0xFFE74C3C),
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

class _GlassStationLabel extends StatelessWidget {
  final String tag;
  final String name;
  final String code;
  final Color color;

  const _GlassStationLabel({
    required this.tag,
    required this.name,
    required this.code,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tag,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(name,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: g.textAlpha(0.9))),
        if (code.isNotEmpty)
          Text(code,
              style: TextStyle(
                  fontSize: 12,
                  color: g.textAlpha(0.5))),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Glass Info Grid
// ─────────────────────────────────────────────

class _GlassInfoGrid extends StatelessWidget {
  final Journey journey;
  final TransportType type;

  const _GlassInfoGrid({required this.journey, required this.type});

  @override
  Widget build(BuildContext context) {
    final tiles = <_TileData>[
      _TileData(Icons.directions_rounded, type.label, 'Transport'),
      _TileData(Icons.calendar_today_rounded,
          AppDateUtils.relativeDay(journey.journeyDate), 'Date'),
      if (journey.scheduledTime != null)
        _TileData(
            Icons.schedule_rounded, journey.scheduledTime!, 'Departure'),
      if (journey.pnr != null)
        _TileData(
            Icons.confirmation_number_rounded, journey.pnr!, 'PNR'),
      if (journey.travelClass != null)
        _TileData(Icons.airline_seat_recline_normal_rounded,
            journey.travelClass!, 'Class'),
      if (journey.berth != null)
        _TileData(
            Icons.event_seat_rounded, journey.berth!, 'Berth / Seat'),
      if (journey.isRepeating)
        _TileData(
            Icons.repeat_rounded, journey.repeatDaysDisplay, 'Repeats'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tiles
          .map((t) => _GlassInfoTile(data: t, accentColor: type.color))
          .toList(),
    );
  }
}

class _TileData {
  final IconData icon;
  final String value;
  final String label;
  const _TileData(this.icon, this.value, this.label);
}

class _GlassInfoTile extends StatelessWidget {
  final _TileData data;
  final Color accentColor;

  const _GlassInfoTile({required this.data, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final width = (MediaQuery.sizeOf(context).width - 48) / 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: g.cardFill(0.06),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: g.border(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child:
                        Icon(data.icon, size: 13, color: accentColor),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: g.textAlpha(0.5),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: g.textAlpha(0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Bottom CTA
// ─────────────────────────────────────────────

class _GlassBottomCta extends ConsumerWidget {
  final Journey journey;
  final EnrichedJourney enrichedJourney;
  final TransportType type;

  const _GlassBottomCta({
    required this.journey,
    required this.enrichedJourney,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = GlassColors.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: g.bg.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                  color: g.border(0.1), width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      type.color,
                      type.color.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: type.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _startTracking(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            journey.isActive
                                ? Icons.gps_fixed_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            journey.isActive
                                ? 'View Live Tracking'
                                : 'Start Journey Tracking',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startTracking(BuildContext context) {
    final destPoint = enrichedJourney.destinationPoint;
    if (destPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Destination location data not available'),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => JourneyTrackingScreen(journey: journey)),
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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: g.bg.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: g.border(0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: g.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    color: g.textAlpha(0.6),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: onCancel,
                        style: TextButton.styleFrom(
                          foregroundColor: g.textAlpha(0.7),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: confirmColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  confirmColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: onConfirm,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                          ),
                          child: Text(confirmLabel),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Favourite Action Button (AppBar)
// ─────────────────────────────────────────────

class _GlassFavoriteActionButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onToggle;

  const _GlassFavoriteActionButton({
    required this.isFavorite,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(isFavorite),
          color: isFavorite
              ? const Color(0xFFFF5252)
              : GlassColors.of(context).textAlpha(0.7),
        ),
      ),
      tooltip: isFavorite ? 'Remove from favourites' : 'Add to favourites',
      onPressed: onToggle,
    );
  }
}

// ─────────────────────────────────────────────
// Stop Timeline Item
// ─────────────────────────────────────────────

class _StopTimelineItem extends StatelessWidget {
  final String name;
  final String code;
  final String? time;
  final int? distanceKm;
  final bool isFirst;
  final bool isLast;
  final Color accentColor;

  const _StopTimelineItem({
    required this.name,
    required this.code,
    this.time,
    this.distanceKm,
    required this.isFirst,
    required this.isLast,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isFirst
        ? const Color(0xFF27AE60)
        : isLast
            ? const Color(0xFFE74C3C)
            : accentColor.withValues(alpha: 0.7);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 28,
            child: Column(
              children: [
                // Top connector line
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: accentColor.withValues(alpha: 0.2),
                    ),
                  ),
                // Dot
                Container(
                  width: isFirst || isLast ? 12 : 8,
                  height: isFirst || isLast ? 12 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: (isFirst || isLast)
                        ? [
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                    border: (isFirst || isLast)
                        ? null
                        : Border.all(
                            color: accentColor.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                  ),
                ),
                // Bottom connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: accentColor.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Station info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: isFirst || isLast ? 13 : 12,
                            fontWeight: isFirst || isLast
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: GlassColors.of(context).textAlpha(
                                isFirst || isLast ? 0.9 : 0.7),
                          ),
                        ),
                        if (code.isNotEmpty)
                          Text(
                            code,
                            style: TextStyle(
                              fontSize: 10,
                              color: GlassColors.of(context).textAlpha(0.4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Time / distance info
                  if (time != null && time!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        time!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: GlassColors.of(context).textAlpha(0.5),
                        ),
                      ),
                    ),
                  if (distanceKm != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: GlassColors.of(context).cardFill(0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$distanceKm km',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: GlassColors.of(context).textAlpha(0.4),
                          ),
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
  }
}
