import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/app_theme.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/journey/edit_journey_screen.dart';
import 'package:travel_companion/features/journey/journey_tracking_screen.dart';
import 'package:travel_companion/providers/app_providers.dart';

class JourneyDetailScreen extends ConsumerWidget {
  final EnrichedJourney enrichedJourney;

  const JourneyDetailScreen({super.key, required this.enrichedJourney});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = enrichedJourney.journey;
    final type = journey.transportType;
    final accentColor = type.color;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Hero AppBar ─────────────────────────
          Builder(builder: (ctx) {
            final topPad = MediaQuery.paddingOf(ctx).top;
            return SliverAppBar(
              pinned: true,
              expandedHeight: topPad + kToolbarHeight + 100,
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                if (journey.isUpcoming)
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    tooltip: 'Edit Journey',
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditJourneyScreen(journey: journey)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await _deleteJourney(context, ref, journey);
                      } else if (value == 'cancel') {
                        await _cancelJourney(context, ref, journey);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(children: [
                          Icon(Icons.cancel_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Cancel Journey'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppTheme.dangerColor),
                          const SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: AppTheme.dangerColor)),
                        ]),
                      ),
                    ],
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: _JourneyHeroBanner(
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
                _ModernRouteCard(enrichedJourney: enrichedJourney, journey: journey, type: type),
                const SizedBox(height: 12),
                _InfoGrid(journey: journey, type: type),
              ]),
            ),
          ),
        ],
      ),

      // ── Sticky CTA ──────────────────────────────
      bottomNavigationBar: (journey.isUpcoming || journey.isActive)
          ? _BottomCta(
              journey: journey,
              enrichedJourney: enrichedJourney,
              type: type,
            )
          : null,
    );
  }

  Future<void> _deleteJourney(BuildContext context, WidgetRef ref, Journey journey) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Journey?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(journeyRepositoryProvider).deleteJourney(journey.id!);
    ref.invalidate(upcomingJourneysProvider);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _cancelJourney(BuildContext context, WidgetRef ref, Journey journey) async {
    await ref
        .read(journeyRepositoryProvider)
        .updateJourneyStatus(journey.id!, JourneyStatus.cancelled);
    ref.invalidate(upcomingJourneysProvider);
    if (context.mounted) Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────
// Hero Banner
// ─────────────────────────────────────────────

class _JourneyHeroBanner extends StatelessWidget {
  final Journey journey;
  final EnrichedJourney enrichedJourney;
  final TransportType type;

  const _JourneyHeroBanner({
    required this.journey,
    required this.enrichedJourney,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final base = type.color;
    final dark = Color.lerp(base, Colors.black, 0.28)!;

    final vehicleName = journey.vehicleName ??
        (journey.vehicleNumber != null
            ? '${type.label} ${journey.vehicleNumber}'
            : type.label);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, dark],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + kToolbarHeight + 6, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(type.icon, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleName,
                        style: const TextStyle(
                          color: Colors.white,
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
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 11, color: Colors.white.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            AppDateUtils.relativeDay(journey.journeyDate),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (journey.scheduledTime != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.schedule_rounded,
                                size: 11, color: Colors.white.withValues(alpha: 0.8)),
                            const SizedBox(width: 4),
                            Text(
                              journey.scheduledTime!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor(journey.status).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(journey.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(JourneyStatus s) => switch (s) {
        JourneyStatus.upcoming => 'Upcoming',
        JourneyStatus.active => 'Active',
        JourneyStatus.completed => 'Completed',
        JourneyStatus.cancelled => 'Cancelled',
      };

  Color _statusColor(JourneyStatus s) => switch (s) {
        JourneyStatus.upcoming => AppTheme.infoColor,
        JourneyStatus.active => AppTheme.successColor,
        JourneyStatus.completed => Colors.grey,
        JourneyStatus.cancelled => AppTheme.dangerColor,
      };
}

// ─────────────────────────────────────────────
// Modern Route Card
// ─────────────────────────────────────────────

class _ModernRouteCard extends StatelessWidget {
  final EnrichedJourney enrichedJourney;
  final Journey journey;
  final TransportType type;

  const _ModernRouteCard({
    required this.enrichedJourney,
    required this.journey,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.successColor,
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.dangerColor,
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
                _StationLabel(
                  tag: 'FROM',
                  name: enrichedJourney.boardingName,
                  code: journey.boardingStationCode ?? '',
                  color: AppTheme.successColor,
                ),
                const SizedBox(height: 18),
                _StationLabel(
                  tag: 'TO',
                  name: enrichedJourney.destinationName,
                  code: journey.destinationStationCode ?? '',
                  color: AppTheme.dangerColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StationLabel extends StatelessWidget {
  final String tag;
  final String name;
  final String code;
  final Color color;

  const _StationLabel({
    required this.tag,
    required this.name,
    required this.code,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        if (code.isNotEmpty)
          Text(code,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Info Grid
// ─────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  final Journey journey;
  final TransportType type;

  const _InfoGrid({required this.journey, required this.type});

  @override
  Widget build(BuildContext context) {
    final tiles = <_TileData>[
      _TileData(Icons.directions_rounded, type.label, 'Transport'),
      _TileData(Icons.calendar_today_rounded,
          AppDateUtils.relativeDay(journey.journeyDate), 'Date'),
      if (journey.scheduledTime != null)
        _TileData(Icons.schedule_rounded, journey.scheduledTime!, 'Departure'),
      if (journey.pnr != null)
        _TileData(Icons.confirmation_number_rounded, journey.pnr!, 'PNR'),
      if (journey.travelClass != null)
        _TileData(Icons.airline_seat_recline_normal_rounded,
            journey.travelClass!, 'Class'),
      if (journey.berth != null)
        _TileData(Icons.event_seat_rounded, journey.berth!, 'Berth / Seat'),
      if (journey.isRepeating)
        _TileData(
            Icons.repeat_rounded, journey.repeatDaysDisplay, 'Repeats'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tiles
          .map((t) => _InfoTile(data: t, accentColor: type.color))
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

class _InfoTile extends StatelessWidget {
  final _TileData data;
  final Color accentColor;

  const _InfoTile({required this.data, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 48) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(data.icon, size: 13, color: accentColor),
              ),
              const SizedBox(width: 6),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom CTA
// ─────────────────────────────────────────────

class _BottomCta extends ConsumerWidget {
  final Journey journey;
  final EnrichedJourney enrichedJourney;
  final TransportType type;

  const _BottomCta({
    required this.journey,
    required this.enrichedJourney,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: FilledButton.icon(
            onPressed: () => _startTracking(context),
            style: FilledButton.styleFrom(
              backgroundColor: type.color,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            icon: Icon(journey.isActive
                ? Icons.gps_fixed_rounded
                : Icons.play_arrow_rounded),
            label: Text(journey.isActive
                ? 'View Live Tracking'
                : 'Start Journey Tracking'),
          ),
        ),
      ),
    );
  }

  void _startTracking(BuildContext context) {
    final destPoint = enrichedJourney.destinationPoint;
    if (destPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Destination location data not available'),
        backgroundColor: AppTheme.dangerColor,
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
