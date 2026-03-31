import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/local_train_schedule.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/history/history_journeys_screen.dart';
import 'package:travel_companion/features/history/favorite_journeys_screen.dart';
import 'package:travel_companion/features/journey/widgets/journey_detail_shared_widgets.dart';
import 'package:travel_companion/providers/app_providers.dart';

class LocalTrainJourneyDetailScreen extends ConsumerStatefulWidget {
  final EnrichedJourney enrichedJourney;

  const LocalTrainJourneyDetailScreen({
    super.key,
    required this.enrichedJourney,
  });

  @override
  ConsumerState<LocalTrainJourneyDetailScreen> createState() =>
      _LocalTrainJourneyDetailScreenState();
}

class _LocalTrainJourneyDetailScreenState
    extends ConsumerState<LocalTrainJourneyDetailScreen> {
  List<LocalTrainStation> _localTrainStops = [];
  bool _isLoadingStops = false;
  bool _stopsExpanded = true;
  bool _isEditingOrigin = false;
  bool _isEditingDestination = false;
  bool _isFavorite = false;
  List<LocalTrainStation> _availableStations = [];
  List<LocalTrainStation> _filteredStations = [];

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.enrichedJourney.journey.isFavorite;
    _loadRouteStops();
  }

  @override
  void didUpdateWidget(covariant LocalTrainJourneyDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enrichedJourney.journey.isFavorite !=
        widget.enrichedJourney.journey.isFavorite) {
      _isFavorite = widget.enrichedJourney.journey.isFavorite;
    }
  }

  Future<void> _toggleFavorite(Journey journey) async {
    final id = journey.id;
    if (id == null) return;

    final next = !_isFavorite;
    final repo = ref.read(journeyRepositoryProvider);
    await repo.toggleFavorite(id, next);

    if (!mounted) return;
    setState(() => _isFavorite = next);
    ref.invalidate(upcomingJourneysProvider);
    ref.invalidate(historyJourneysProvider);
    ref.invalidate(favoriteJourneysProvider);
  }

  Future<void> _loadRouteStops() async {
    final journey = widget.enrichedJourney.journey;

    if (journey.boardingStationCode == null ||
        journey.destinationStationCode == null) {
      return;
    }

    setState(() => _isLoadingStops = true);

    try {
      final localRepo = ref.read(localTrainRepositoryProvider);
      final stations = await localRepo.searchStations(
        journey.boardingStationCode!,
      );
      if (stations.isNotEmpty) {
        final lineId = stations.first.lineId;
        final allStations = await localRepo.getStationsForLine(lineId);

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
    } catch (_) {
      // Silently fail
    }

    if (mounted) setState(() => _isLoadingStops = false);
  }

  Future<void> _loadAvailableStations() async {
    try {
      final journey = widget.enrichedJourney.journey;
      final localRepo = ref.read(localTrainRepositoryProvider);

      if (journey.boardingStationCode != null) {
        final stations = await localRepo.searchStations(
          journey.boardingStationCode!,
        );
        if (stations.isNotEmpty) {
          final lineId = stations.first.lineId;
          final allStations = await localRepo.getStationsForLine(lineId);
          if (mounted) {
            setState(() {
              _availableStations = allStations;
              _filteredStations = allStations;
            });
          }
        }
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
          .where(
            (s) =>
                s.name.toLowerCase().contains(lower) ||
                s.code.toLowerCase().contains(lower),
          )
          .toList();
    });
  }

  Future<void> _updateOriginStation(LocalTrainStation station) async {
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
      AdaptiveFeedback.showToast(context, 'Origin station updated');
      _loadRouteStops();
    }
  }

  Future<void> _updateDestinationStation(LocalTrainStation station) async {
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
      AdaptiveFeedback.showToast(context, 'Destination station updated');
      _loadRouteStops();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enrichedJourney = widget.enrichedJourney;
    final journey = enrichedJourney.journey;
    final type = TransportType.localTrain;
    final accentColor = type.color;
    final g = GlassColors.of(context);

    return CupertinoPageScaffold(
      backgroundColor: g.bg,
      child: Stack(
        children: [
          _DetailBackground(accentColor: accentColor),
          CustomScrollView(
            slivers: [
              Builder(
                builder: (ctx) {
                  final topPad = MediaQuery.paddingOf(ctx).top;
                  final headerHeight = topPad + kToolbarHeight + 100;
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: headerHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _LocalTrainHeroBanner(
                              journey: journey,
                              enrichedJourney: enrichedJourney,
                              type: type,
                            ),
                          ),
                          SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 12,
                                    sigmaY: 12,
                                  ),
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: g.cardFill(0.12),
                                      border: Border.all(color: g.border(0.15)),
                                    ),
                                    child: Row(
                                      children: [
                                        CupertinoButton(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          minimumSize: const Size(32, 32),
                                          onPressed: () =>
                                              Navigator.maybePop(context),
                                          child: Icon(
                                            CupertinoIcons.back,
                                            color: g.appBarForeground,
                                            size: 20,
                                          ),
                                        ),
                                        const Expanded(
                                          child: Text(
                                            'Local Train Journey',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                        GlassFavoriteActionButton(
                                          isFavorite: _isFavorite,
                                          onToggle: () =>
                                              _toggleFavorite(journey),
                                        ),
                                        if (journey.isUpcoming)
                                          IconButton(
                                            icon: const Icon(
                                              CupertinoIcons.ellipsis_circle,
                                            ),
                                            tooltip: 'Journey actions',
                                            onPressed: () =>
                                                _showJourneyActions(
                                                  context,
                                                  ref,
                                                  journey,
                                                ),
                                          ),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildEditableRouteCard(context, ref, enrichedJourney),
                    const SizedBox(height: 12),
                    if (_isLoadingStops)
                      _buildStopsLoadingIndicator(accentColor)
                    else if (_localTrainStops.isNotEmpty)
                      _buildRouteStopsCard(),
                    if (_localTrainStops.isNotEmpty || _isLoadingStops)
                      const SizedBox(height: 12),
                    GlassInfoGrid(journey: journey, type: type),
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
              child: GlassBottomCta(
                journey: journey,
                enrichedJourney: enrichedJourney,
                type: type,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditableRouteCard(
    BuildContext context,
    WidgetRef ref,
    EnrichedJourney enrichedJourney,
  ) {
    final journey = enrichedJourney.journey;
    final g = GlassColors.of(context);
    final type = TransportType.localTrain;

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
                  style: TextStyle(fontSize: 11, color: g.textAlpha(0.6)),
                ),
            ],
          ),
          const Spacer(),
          if (isEditable) Icon(Icons.edit_rounded, size: 18, color: color),
        ],
      ),
    );
  }

  Widget _buildStationPickerSheet(
    BuildContext context,
    String title,
    Function(LocalTrainStation) onSelect,
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
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredStations.length,
                  itemBuilder: (context, index) {
                    final station = _filteredStations[index];
                    return ListTile(
                      title: Text(station.name),
                      subtitle: Text(station.code),
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
    final type = TransportType.localTrain;
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
              InkWell(
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
                          Icons.route_rounded,
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
                          '${_localTrainStops.length} stops',
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
              if (_stopsExpanded)
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: List.generate(_localTrainStops.length, (i) {
                        final stop = _localTrainStops[i];
                        final isFirst = i == 0;
                        final isLast = i == _localTrainStops.length - 1;
                        return StopTimelineItem(
                          name: stop.name,
                          code: stop.code,
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

  Future<void> _showJourneyActions(
    BuildContext context,
    WidgetRef ref,
    Journey journey,
  ) async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) {
        final g = GlassColors.of(sheetContext);
        return CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(sheetContext, 'cancel'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.xmark_circle,
                    size: 18,
                    color: g.iconAlpha(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cancel Journey',
                    style: TextStyle(color: g.textAlpha(0.9)),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(sheetContext, 'delete'),
              child: const Text('Delete'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('Dismiss'),
          ),
        );
      },
    );

    if (!mounted) return;

    if (action == 'delete') {
      await _deleteJourney(this.context, ref, journey);
    } else if (action == 'cancel') {
      await _cancelJourney(this.context, ref, journey);
    }
  }

  Future<void> _deleteJourney(
    BuildContext context,
    WidgetRef ref,
    Journey journey,
  ) async {
    try {
      final confirm = await showCupertinoDialog<bool>(
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
        AdaptiveFeedback.showToast(context, 'Error: $e', isError: true);
      }
    }
  }

  Future<void> _cancelJourney(
    BuildContext context,
    WidgetRef ref,
    Journey journey,
  ) async {
    await ref
        .read(journeyRepositoryProvider)
        .updateJourneyStatus(journey.id!, JourneyStatus.cancelled);
    ref.invalidate(upcomingJourneysProvider);
    if (context.mounted) Navigator.pop(context);
  }
}

// Helper widgets
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

class _LocalTrainHeroBanner extends StatelessWidget {
  final Journey journey;
  final EnrichedJourney enrichedJourney;
  final TransportType type;

  const _LocalTrainHeroBanner({
    required this.journey,
    required this.enrichedJourney,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final accentColor = type.color;

    final vehicleName =
        journey.vehicleName ??
        (journey.vehicleNumber != null
            ? '${type.label} ${journey.vehicleNumber}'
            : type.label);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor.withValues(alpha: 0.15), g.bg],
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
            padding: EdgeInsets.fromLTRB(
              20,
              topPad + kToolbarHeight + 6,
              20,
              20,
            ),
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
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: g.textAlpha(0.6),
                          ),
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
                            Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: g.textAlpha(0.6),
                            ),
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
                GlassStatusPill(status: journey.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
