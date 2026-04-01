import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/journey/application/actions/journey_detail_actions.dart';

import 'package:travel_companion/features/journey/widgets/journey_hero_banner.dart';
import 'package:travel_companion/features/journey/widgets/journey_detail_background.dart';
import 'package:travel_companion/features/journey/widgets/journey_detail_shared_widgets.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';
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
    final next = await JourneyDetailActions.toggleFavorite(
      ref: ref,
      journey: journey,
      currentValue: _isFavorite,
    );

    if (!mounted) return;
    setState(() => _isFavorite = next);
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
          JourneyDetailBackground(accentColor: accentColor),
          CustomScrollView(
            slivers: [
              Builder(
                builder: (ctx) {
                  final topPad = MediaQuery.paddingOf(ctx).top;
                  final headerHeight = topPad + 44 + 100;
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: headerHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: JourneyHeroBanner(
                              journey: journey,
                              type: type,
                            ),
                          ),
                          TransportFormAppBar(
                            title: 'Bus Journey',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GlassFavoriteActionButton(
                                  isFavorite: _isFavorite,
                                  onToggle: () => _toggleFavorite(journey),
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
                                      color: g.textSecondary,
                                    ),
                                  ),
                              ],
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
            Icon(CupertinoIcons.location_solid, size: 18, color: color),
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
}
