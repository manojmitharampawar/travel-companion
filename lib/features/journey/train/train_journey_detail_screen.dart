import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/station.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/history/history_journeys_screen.dart';
import 'package:travel_companion/features/history/favorite_journeys_screen.dart';
import 'package:travel_companion/features/journey/widgets/journey_detail_shared_widgets.dart';
import 'package:travel_companion/providers/app_providers.dart';

class TrainJourneyDetailScreen extends ConsumerStatefulWidget {
  final EnrichedJourney enrichedJourney;

  const TrainJourneyDetailScreen({
    super.key,
    required this.enrichedJourney,
  });

  @override
  ConsumerState<TrainJourneyDetailScreen> createState() =>
      _TrainJourneyDetailScreenState();
}

class _TrainJourneyDetailScreenState
    extends ConsumerState<TrainJourneyDetailScreen> {
  List<TrainRouteStop> _trainStops = [];
  bool _isLoadingStops = false;
  bool _stopsExpanded = true;
  bool _isEditingOrigin = false;
  bool _isEditingDestination = false;
  List<Station> _availableStations = [];
  List<Station> _filteredStations = [];

  @override
  void initState() {
    super.initState();
    _loadRouteStops();
  }

  Future<void> _loadRouteStops() async {
    final journey = widget.enrichedJourney.journey;

    if (journey.boardingStationCode == null ||
        journey.destinationStationCode == null ||
        journey.vehicleNumber == null) {
      return;
    }

    setState(() => _isLoadingStops = true);

    try {
      final trainRepo = ref.read(trainRepositoryProvider);
      final stops = await trainRepo.getRouteSegmentWithCoordinates(
        trainNumber: journey.vehicleNumber ?? '',
        fromStation: journey.boardingStationCode!,
        toStation: journey.destinationStationCode!,
      );
      if (mounted) setState(() => _trainStops = stops);
    } catch (_) {
      // Silently fail — stops section just won't show
    }

    if (mounted) setState(() => _isLoadingStops = false);
  }

  Future<void> _loadAvailableStations() async {
    try {
      final stationRepo = ref.read(stationRepositoryProvider);
      final stations = await stationRepo.getAllStations();
      if (mounted) {
        setState(() {
          _availableStations = stations;
          _filteredStations = stations;
        });
      }
    } catch (_) {
      // Silently fail
    }
  }

  void _filterStations(String query) {
    if (query.isEmpty) {
      setState(() => _filteredStations = _availableStations);
      return;
    }

    final lower = query.toLowerCase();
    setState(() {
      _filteredStations = _availableStations
          .where((s) =>
              s.name.toLowerCase().contains(lower) ||
              (s.code?.toLowerCase().contains(lower) ?? false))
          .toList();
    });
  }

  Future<void> _updateOriginStation(Station station) async {
    final journey = widget.enrichedJourney.journey;
    final updatedJourney = journey.copyWith(
      boardingStationCode: station.code,
      originLatitude: station.latitude,
      originLongitude: station.longitude,
    );

    await ref.read(journeyRepositoryProvider).updateJourney(updatedJourney);
    ref.invalidate(upcomingJourneysProvider);
    if (mounted) {
      setState(() => _isEditingOrigin = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Origin station updated')),
      );
      _loadRouteStops();
    }
  }

  Future<void> _updateDestinationStation(Station station) async {
    final journey = widget.enrichedJourney.journey;
    final updatedJourney = journey.copyWith(
      destinationStationCode: station.code,
      destinationLatitude: station.latitude,
      destinationLongitude: station.longitude,
    );

    await ref.read(journeyRepositoryProvider).updateJourney(updatedJourney);
    ref.invalidate(upcomingJourneysProvider);
    if (mounted) {
      setState(() => _isEditingDestination = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destination station updated')),
      );
      _loadRouteStops();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enrichedJourney = widget.enrichedJourney;
    final journey = enrichedJourney.journey;
    final type = TransportType.train;
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
                    GlassFavoriteActionButton(
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
                                  size: 18, color: g.iconAlpha(0.7)),
                              const SizedBox(width: 8),
                              Text('Cancel Journey',
                                  style:
                                      TextStyle(color: g.textAlpha(0.9))),
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
                    // Route card with editable origin/destination
                    _buildEditableRouteCard(context, ref, enrichedJourney),
                    const SizedBox(height: 12),

                    // Station list between origin and destination
                    if (_isLoadingStops)
                      _buildStopsLoadingIndicator(accentColor)
                    else if (_trainStops.isNotEmpty)
                      _buildRouteStopsCard(),

                    if (_trainStops.isNotEmpty || _isLoadingStops)
                      const SizedBox(height: 12),

                    GlassInfoGrid(journey: journey, type: type),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Sticky CTA ──────────────────────────────
      bottomNavigationBar: (journey.isUpcoming || journey.isActive)
          ? GlassBottomCta(
              journey: journey,
              enrichedJourney: enrichedJourney,
              type: type,
            )
          : null,
    );
  }

  Widget _buildEditableRouteCard(BuildContext context, WidgetRef ref,
      EnrichedJourney enrichedJourney) {
    final journey = enrichedJourney.journey;
    final g = GlassColors.of(context);
    final type = TransportType.train;

    if (_isEditingOrigin) {
      return _buildStationPickerSheet(
        context,
        'Select Origin Station',
        (station) => _updateOriginStation(station),
        () => setState(() => _isEditingOrigin = false),
      );
    }

    if (_isEditingDestination) {
      return _buildStationPickerSheet(
        context,
        'Select Destination Station',
        (station) => _updateDestinationStation(station),
        () => setState(() => _isEditingDestination = false),
      );
    }

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
            children: [
              // Origin (editable)
              GestureDetector(
                onTap: journey.isUpcoming
                    ? () {
                        _loadAvailableStations();
                        setState(() => _isEditingOrigin = true);
                      }
                    : null,
                child: _buildStationTile(
                  'FROM',
                  enrichedJourney.boardingName,
                  journey.boardingStationCode ?? '',
                  const Color(0xFF27AE60),
                  isEditable: journey.isUpcoming,
                ),
              ),
              const SizedBox(height: 16),
              // Timeline connector
              Row(
                children: [
                  const SizedBox(width: 7),
                  Container(
                    width: 2,
                    height: 30,
                    color: type.color.withValues(alpha: 0.25),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Destination (editable)
              GestureDetector(
                onTap: journey.isUpcoming
                    ? () {
                        _loadAvailableStations();
                        setState(() => _isEditingDestination = true);
                      }
                    : null,
                child: _buildStationTile(
                  'TO',
                  enrichedJourney.destinationName,
                  journey.destinationStationCode ?? '',
                  const Color(0xFFE74C3C),
                  isEditable: journey.isUpcoming,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStationTile(
    String tag,
    String name,
    String code,
    Color color, {
    required bool isEditable,
  }) {
    final g = GlassColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Column(
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
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: g.text,
                ),
              ),
              if (code.isNotEmpty)
                Text(
                  code,
                  style: TextStyle(
                    fontSize: 11,
                    color: g.textAlpha(0.6),
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (isEditable)
            Icon(
              Icons.edit_rounded,
              size: 18,
              color: color,
            ),
        ],
      ),
    );
  }

  Widget _buildStationPickerSheet(
    BuildContext context,
    String title,
    Function(Station) onSelect,
    VoidCallback onCancel,
  ) {
    final g = GlassColors.of(context);
    final TextEditingController searchController = TextEditingController();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            color: g.cardFill(),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: g.border(0.12)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: g.text,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onCancel,
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search stations...',
                    hintStyle: TextStyle(color: g.textAlpha(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: g.border()),
                    ),
                    prefixIcon: Icon(Icons.search, color: g.textAlpha(0.6)),
                  ),
                  onChanged: _filterStations,
                ),
              ),

              // Stations list
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredStations.length,
                  itemBuilder: (context, index) {
                    final station = _filteredStations[index];
                    return ListTile(
                      title: Text(station.name),
                      subtitle: Text(station.code ?? ''),
                      onTap: () => onSelect(station),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildRouteStopsCard() {
    final type = TransportType.train;
    final g = GlassColors.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: g.cardFill(),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: g.border()),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header
              InkWell(
                onTap: () => setState(() => _stopsExpanded = !_stopsExpanded),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          '${_trainStops.length} stops',
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: List.generate(_trainStops.length, (i) {
                        final stop = _trainStops[i];
                        final isFirst = i == 0;
                        final isLast = i == _trainStops.length - 1;
                        return StopTimelineItem(
                          name: stop.stationName,
                          code: stop.stationCode,
                          time: stop.timeDisplay,
                          distanceKm: stop.distanceKm?.toDouble(),
                          isFirst: isFirst,
                          isLast: isLast,
                          accentColor: type.color,
                        );
                      }),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteJourney(
      BuildContext context, WidgetRef ref, Journey journey) async {
                    try {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => GlassConfirmDialog(
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
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
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

// ═════════════════════════════════════════════
// Shared Components
// ═════════════════════════════════════════════

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
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: g.border(0.06), width: 1),
              ),
            ),
          ),
          Padding(
            padding:
                EdgeInsets.fromLTRB(20, topPad + kToolbarHeight + 6, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: g.cardFill(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: g.border(0.15)),
                      ),
                      child:
                          Icon(type.icon, size: 30, color: accentColor),
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
                              size: 11, color: g.textAlpha(0.6)),
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
                                size: 11, color: g.textAlpha(0.6)),
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

class _GlassFavoriteActionButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onToggle;

  const _GlassFavoriteActionButton({
    required this.isFavorite,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavorite ? const Color(0xFFFF5252) : g.appBarForeground,
      ),
      onPressed: onToggle,
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
    );
  }
}

class _StopTimelineItem extends StatelessWidget {
  final String name;
  final String code;
  final String? time;
  final double? distanceKm;
  final bool isFirst;
  final bool isLast;
  final Color accentColor;

  const _StopTimelineItem({
    required this.name,
    required this.code,
    required this.isFirst,
    required this.isLast,
    required this.accentColor,
    this.time,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFirst
                    ? const Color(0xFF27AE60)
                    : isLast
                        ? const Color(0xFFE74C3C)
                        : accentColor,
                boxShadow: [
                  BoxShadow(
                    color: (isFirst
                            ? const Color(0xFF27AE60)
                            : isLast
                                ? const Color(0xFFE74C3C)
                                : accentColor)
                        .withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: accentColor.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: isFirst ? 0 : 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: g.textAlpha(0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  code,
                  style: TextStyle(
                    fontSize: 11,
                    color: g.textAlpha(0.5),
                  ),
                ),
                if (time != null || distanceKm != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (time != null) ...[
                        Icon(Icons.schedule_rounded,
                            size: 10, color: g.textAlpha(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          time!,
                          style: TextStyle(
                            fontSize: 10,
                            color: g.textAlpha(0.6),
                          ),
                        ),
                      ],
                      if (distanceKm != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.location_on_rounded,
                            size: 10, color: g.textAlpha(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          '${distanceKm!.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 10,
                            color: g.textAlpha(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
    return AlertDialog(
      backgroundColor: g.cardFill(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: TextStyle(color: g.text, fontWeight: FontWeight.w700),
      ),
      content: Text(message, style: TextStyle(color: g.textAlpha(0.8))),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel', style: TextStyle(color: g.textAlpha(0.7))),
        ),
        TextButton(
          onPressed: onConfirm,
          child:
              Text(confirmLabel, style: TextStyle(color: confirmColor)),
        ),
      ],
    );
  }
}
