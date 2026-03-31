import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  const BusJourneyDetailScreen({
    super.key,
    required this.enrichedJourney,
  });

  @override
  ConsumerState<BusJourneyDetailScreen> createState() =>
      _BusJourneyDetailScreenState();
}

class _BusJourneyDetailScreenState extends ConsumerState<BusJourneyDetailScreen> {
  bool _isEditingOrigin = false;
  bool _isEditingDestination = false;

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
      setState(() => _isEditingOrigin = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Origin location updated')),
      );
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
      setState(() => _isEditingDestination = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destination location updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final enrichedJourney = widget.enrichedJourney;
    final journey = enrichedJourney.journey;
    final type = TransportType.bus;
    final accentColor = type.color;
    final g = GlassColors.of(context);

    return Scaffold(
      backgroundColor: g.bg,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _DetailBackground(accentColor: accentColor),
          CustomScrollView(
            slivers: [
              Builder(builder: (ctx) {
                final topPad = MediaQuery.paddingOf(ctx).top;
                return SliverAppBar(
                  pinned: true,
                  expandedHeight: topPad + kToolbarHeight + 100,
                  backgroundColor: Colors.transparent,
                  foregroundColor: g.appBarForeground,
                  elevation: 0,
                  actions: [
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
                    background: _BusHeroBanner(
                      journey: journey,
                      enrichedJourney: enrichedJourney,
                      type: type,
                    ),
                  ),
                );
              }),
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
        ],
      ),
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
                        setState(() => _isEditingOrigin = true);
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
                        setState(() => _isEditingDestination = true);
                        _showLocationPicker(context, 'Select Destination',
                            (loc) {
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
            Icon(
              Icons.location_on_rounded,
              size: 18,
              color: color,
            ),
        ],
      ),
    );
  }

  void _showLocationPicker(BuildContext context, String title,
      Function(LocationPoint) onSelect) {
    // For now, show a snackbar placeholder. In a real implementation,
    // this would open a map picker or location search dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title - Feature coming soon'),
        duration: const Duration(seconds: 2),
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
                GlassStatusPill(status: journey.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
