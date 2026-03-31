import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/core/ui/adaptive_navigation.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/journey/journey_tracking_screen.dart';

/// Shared components for journey detail screens
/// Used by train, metro, bus, and local train detail screens

// ═════════════════════════════════════════════
// Info Grid & Tiles
// ═════════════════════════════════════════════

class GlassInfoGrid extends StatelessWidget {
  final Journey journey;
  final TransportType type;

  const GlassInfoGrid({super.key, required this.journey, required this.type});

  @override
  Widget build(BuildContext context) {
    final tiles = <TileData>[
      TileData(Icons.directions_rounded, type.label, 'Transport'),
      TileData(
        Icons.calendar_today_rounded,
        AppDateUtils.relativeDay(journey.journeyDate),
        'Date',
      ),
      if (journey.scheduledTime != null)
        TileData(Icons.schedule_rounded, journey.scheduledTime!, 'Departure'),
      if (journey.pnr != null)
        TileData(Icons.confirmation_number_rounded, journey.pnr!, 'PNR'),
      if (journey.travelClass != null)
        TileData(
          Icons.airline_seat_recline_normal_rounded,
          journey.travelClass!,
          'Class',
        ),
      if (journey.berth != null)
        TileData(Icons.event_seat_rounded, journey.berth!, 'Berth / Seat'),
      if (journey.isRepeating)
        TileData(Icons.repeat_rounded, journey.repeatDaysDisplay, 'Repeats'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tiles
          .map((t) => GlassInfoTile(data: t, accentColor: type.color))
          .toList(),
    );
  }
}

class TileData {
  final IconData icon;
  final String value;
  final String label;
  const TileData(this.icon, this.value, this.label);
}

class GlassInfoTile extends StatelessWidget {
  final TileData data;
  final Color accentColor;

  const GlassInfoTile({
    super.key,
    required this.data,
    required this.accentColor,
  });

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
            border: Border.all(color: g.border(0.1)),
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
                    child: Icon(data.icon, size: 13, color: accentColor),
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

// ═════════════════════════════════════════════
// Bottom CTA Button
// ═════════════════════════════════════════════

class GlassBottomCta extends ConsumerWidget {
  final Journey journey;
  final EnrichedJourney enrichedJourney;
  final TransportType type;

  const GlassBottomCta({
    super.key,
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
            border: Border(top: BorderSide(color: g.border(0.1), width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [type.color, type.color.withValues(alpha: 0.8)],
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
                child: GestureDetector(
                  onTap: () => _startTracking(context),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          journey.isActive
                              ? CupertinoIcons.location_fill
                              : CupertinoIcons.play_arrow_solid,
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
    );
  }

  void _startTracking(BuildContext context) {
    final destPoint = enrichedJourney.destinationPoint;
    if (destPoint == null) {
      AdaptiveFeedback.showToast(
        context,
        'Destination location data not available',
        isError: true,
      );
      return;
    }
    Navigator.push(
      context,
      adaptivePageRoute(JourneyTrackingScreen(journey: journey)),
    );
  }
}

// ═════════════════════════════════════════════
// Confirm Dialog
// ═════════════════════════════════════════════

class GlassConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const GlassConfirmDialog({
    super.key,
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
          child: Text('Cancel', style: TextStyle(color: g.textAlpha(0.7))),
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

// ═════════════════════════════════════════════
// Favorite Action Button
// ═════════════════════════════════════════════

class GlassFavoriteActionButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onToggle;

  const GlassFavoriteActionButton({
    super.key,
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

// ═════════════════════════════════════════════
// Stop Timeline Item
// ═════════════════════════════════════════════

class StopTimelineItem extends StatelessWidget {
  final String name;
  final String code;
  final String? time;
  final double? distanceKm;
  final bool isFirst;
  final bool isLast;
  final Color accentColor;

  const StopTimelineItem({
    super.key,
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
    final dotColor = isFirst
        ? g.statusSuccess
        : isLast
        ? g.statusDanger
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
                            color: g.textAlpha(isFirst || isLast ? 0.9 : 0.7),
                          ),
                        ),
                        if (code.isNotEmpty)
                          Text(
                            code,
                            style: TextStyle(
                              fontSize: 10,
                              color: g.textAlpha(0.4),
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
                          color: g.textAlpha(0.5),
                        ),
                      ),
                    ),
                  if (distanceKm != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: g.cardFill(0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: g.border(0.1)),
                        ),
                        child: Text(
                          '${distanceKm!.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: g.textAlpha(0.6),
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

// ═════════════════════════════════════════════
// Status Pill
// ═════════════════════════════════════════════

class GlassStatusPill extends StatelessWidget {
  final JourneyStatus status;
  const GlassStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final (label, color) = switch (status) {
      JourneyStatus.upcoming => ('Upcoming', g.statusInfo),
      JourneyStatus.active => ('Active', g.statusSuccess),
      JourneyStatus.completed => ('Completed', g.statusNeutral),
      JourneyStatus.cancelled => ('Cancelled', g.statusDanger),
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
