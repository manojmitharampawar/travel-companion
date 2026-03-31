import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/history/history_journeys_screen.dart';
import 'package:travel_companion/features/history/favorite_journeys_screen.dart';
import 'package:travel_companion/features/journey/widgets/journey_detail_shared_widgets.dart';
import 'package:travel_companion/providers/app_providers.dart';

class BusJourneyDetailScreen extends ConsumerStatefulWidget {
  final EnrichedJourney enrichedJourney;

  const BusJourneyDetailScreen({super.key, required this.enrichedJourney});

  @override
  ConsumerState<BusJourneyDetailScreen> createState() =>
      _BusJourneyDetailScreenState();
}

class _BusJourneyDetailScreenState
    extends ConsumerState<BusJourneyDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.enrichedJourney.journey.isFavorite;
  }

  @override
  void didUpdateWidget(covariant BusJourneyDetailScreen oldWidget) {
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

  Future<void> _updateOriginLocation(LocationPoint location) async {
    final journey = widget.enrichedJourney.journey;
    final updatedJourney = journey.copyWith(
      originLatitude: location.latitude,
      originLongitude: location.longitude,
      originName: location.name,
    );

    await ref.read(journeyRepositoryProvider).updateJourney(updatedJourney);
    ref.invalidate(upcomingJourneysProvider);
    if (mounted) {
      AdaptiveFeedback.showToast(context, 'Origin location updated');
    }
  }

  Future<void> _updateDestinationLocation(LocationPoint location) async {
    final journey = widget.enrichedJourney.journey;
    final updatedJourney = journey.copyWith(
      destinationLatitude: location.latitude,
      destinationLongitude: location.longitude,
      destinationName: location.name,
    );

    await ref.read(journeyRepositoryProvider).updateJourney(updatedJourney);
    ref.invalidate(upcomingJourneysProvider);
    if (mounted) {
      AdaptiveFeedback.showToast(context, 'Destination location updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final enrichedJourney = widget.enrichedJourney;
    final journey = enrichedJourney.journey;
    final type = TransportType.bus;
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
                            child: _BusHeroBanner(
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
                                            'Bus Journey',
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
    final type = TransportType.bus;

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
                        _showLocationPicker(context, 'Select Origin', (loc) {
                          _updateOriginLocation(loc);
                        });
                      }
                    : null,
                child: _buildLocationTile(
                  'FROM',
                  enrichedJourney.boardingName,
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
                        _showLocationPicker(context, 'Select Destination', (
                          loc,
                        ) {
                          _updateDestinationLocation(loc);
                        });
                      }
                    : null,
                child: _buildLocationTile(
                  'TO',
                  enrichedJourney.destinationName,
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

  Widget _buildLocationTile(
    String tag,
    String name,
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
            ],
          ),
          const Spacer(),
          if (isEditable)
            Icon(Icons.location_on_rounded, size: 18, color: color),
        ],
      ),
    );
  }

  void _showLocationPicker(
    BuildContext context,
    String title,
    Function(LocationPoint) onSelect,
  ) {
    AdaptiveFeedback.showToast(
      context,
      '$title - Feature coming soon',
      isError: true,
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

class _BusHeroBanner extends StatelessWidget {
  final Journey journey;
  final EnrichedJourney enrichedJourney;
  final TransportType type;

  const _BusHeroBanner({
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
