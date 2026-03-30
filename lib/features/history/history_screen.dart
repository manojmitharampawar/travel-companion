import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/providers/app_providers.dart';

const _kAccent = Color(0xFF0D47A1);

final historyJourneysProvider =
    FutureProvider<List<EnrichedJourney>>((ref) async {
  final journeyRepo = ref.read(journeyRepositoryProvider);
  final stationRepo = ref.read(stationRepositoryProvider);

  final journeys = await journeyRepo.getJourneyHistory();

  final enriched = <EnrichedJourney>[];
  for (final journey in journeys) {
    final boarding = journey.boardingStationCode != null
        ? await stationRepo.getStationByCode(journey.boardingStationCode!)
        : null;
    final destination = journey.destinationStationCode != null
        ? await stationRepo.getStationByCode(journey.destinationStationCode!)
        : null;
    enriched.add(EnrichedJourney(
      journey: journey,
      boardingStation: boarding,
      destinationStation: destination,
    ));
  }
  return enriched;
});

final favoriteJourneysProvider =
    FutureProvider<List<EnrichedJourney>>((ref) async {
  final journeyRepo = ref.read(journeyRepositoryProvider);
  final stationRepo = ref.read(stationRepositoryProvider);

  final journeys = await journeyRepo.getFavoriteJourneys();

  final enriched = <EnrichedJourney>[];
  for (final journey in journeys) {
    final boarding = journey.boardingStationCode != null
        ? await stationRepo.getStationByCode(journey.boardingStationCode!)
        : null;
    final destination = journey.destinationStationCode != null
        ? await stationRepo.getStationByCode(journey.destinationStationCode!)
        : null;
    enriched.add(EnrichedJourney(
      journey: journey,
      boardingStation: boarding,
      destinationStation: destination,
    ));
  }
  return enriched;
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = GlassColors.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: g.bg,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Background orbs
            _HistoryBackground(),

            // Content
            Column(
              children: [
                // Glass app bar with tabs
                _buildGlassAppBarWithTabs(context),

                // Tab body
                Expanded(
                  child: TabBarView(
                    children: [
                      _HistoryTab(),
                      _FavoritesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassAppBarWithTabs(BuildContext context) {
    final g = GlassColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _kAccent.withValues(alpha: 0.5),
                g.bg.withValues(alpha: 0.9),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: g.border(0.1),
              ),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: topPad),
              // App bar row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded,
                          color: g.appBarForeground),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Journey History',
                        style: TextStyle(
                          color: g.appBarForeground,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tab bar
              TabBar(
                labelColor: g.appBarForeground,
                unselectedLabelColor: g.textAlpha(0.38),
                indicatorColor: const Color(0xFFFF9800),
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('History'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Favorites'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryBackground extends StatelessWidget {
  const _HistoryBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GlassColors.of(context).bg,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            left: -60,
            child: _GlowOrb(color: _kAccent, size: 200),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: _GlowOrb(color: GlassConstants.meshPurple, size: 180),
          ),
          Positioned(
            top: 300,
            left: -30,
            child: _GlowOrb(color: GlassConstants.meshCyan, size: 130),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.06),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// History Tab
// ─────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyJourneysProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(historyJourneysProvider),
      color: const Color(0xFFFF9800),
      backgroundColor: GlassColors.of(context).dropdownBg,
      child: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9800)),
        ),
        error: (e, _) => _GlassPlaceholder(
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFE74C3C),
          title: 'Error loading history',
          subtitle: 'Please try again later',
        ),
        data: (journeys) {
          if (journeys.isEmpty) {
            return _GlassPlaceholder(
              icon: Icons.history_rounded,
              iconColor: Colors.white.withValues(alpha: 0.3),
              title: 'No journey history yet',
              subtitle: 'Your completed journeys will appear here',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: journeys.length,
            itemBuilder: (context, index) => _GlassHistoryCard(
              enrichedJourney: journeys[index],
              onToggleFavorite: () async {
                final j = journeys[index].journey;
                await ref
                    .read(journeyRepositoryProvider)
                    .toggleFavorite(j.id!, !j.isFavorite);
                ref.invalidate(historyJourneysProvider);
                ref.invalidate(favoriteJourneysProvider);
              },
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Favorites Tab
// ─────────────────────────────────────────────

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteJourneysProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(favoriteJourneysProvider),
      color: const Color(0xFFFF9800),
      backgroundColor: GlassColors.of(context).dropdownBg,
      child: favoritesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9800)),
        ),
        error: (e, _) => _GlassPlaceholder(
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFE74C3C),
          title: 'Error loading favorites',
          subtitle: 'Please try again later',
        ),
        data: (journeys) {
          if (journeys.isEmpty) {
            return _GlassPlaceholder(
              icon: Icons.favorite_border_rounded,
              iconColor: const Color(0xFFFF5252),
              title: 'No favorite journeys yet',
              subtitle: 'Star your favorite routes to reschedule them quickly',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: journeys.length,
            itemBuilder: (context, index) {
              return _GlassFavoriteCard(
                enrichedJourney: journeys[index],
                onReschedule: () =>
                    _rescheduleJourney(context, ref, journeys[index]),
                onRemoveFavorite: () async {
                  final j = journeys[index].journey;
                  await ref
                      .read(journeyRepositoryProvider)
                      .toggleFavorite(j.id!, false);
                  ref.invalidate(favoriteJourneysProvider);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _rescheduleJourney(
    BuildContext context,
    WidgetRef ref,
    EnrichedJourney enriched,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 120)),
      helpText: 'Select new journey date',
    );

    if (picked == null) return;

    await ref
        .read(journeyRepositoryProvider)
        .rescheduleFromFavorite(enriched.journey, picked);

    ref.invalidate(upcomingJourneysProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Journey rescheduled to ${DateFormat('dd MMM yyyy').format(picked)}',
          ),
          backgroundColor: const Color(0xFF27AE60),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────
// Glass Placeholder (empty/error)
// ─────────────────────────────────────────────

class _GlassPlaceholder extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _GlassPlaceholder({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(icon, size: 48, color: iconColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: g.text,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: g.textAlpha(0.45),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Glass History Card
// ─────────────────────────────────────────────

class _GlassHistoryCard extends StatelessWidget {
  final EnrichedJourney enrichedJourney;
  final VoidCallback onToggleFavorite;

  const _GlassHistoryCard({
    required this.enrichedJourney,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final journey = enrichedJourney.journey;
    final type = journey.transportType;
    final isCompleted = journey.status == JourneyStatus.completed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF27AE60).withValues(alpha: 0.06)
                  : g.cardFill(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFF27AE60).withValues(alpha: 0.2)
                    : g.border(0.12),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: type.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: type.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(type.icon, size: 14, color: type.color),
                          if (journey.vehicleNumber != null &&
                              journey.vehicleNumber!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              journey.vehicleNumber!,
                              style: TextStyle(
                                color: type.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        journey.vehicleName ?? type.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: g.textAlpha(0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: onToggleFavorite,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          journey.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: journey.isFavorite
                              ? const Color(0xFFFF5252)
                              : g.textAlpha(0.3),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Route
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF27AE60)
                                .withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        enrichedJourney.boardingName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: g.textAlpha(0.75),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 12,
                          color: g.textAlpha(0.25)),
                    ),
                    Expanded(
                      child: Text(
                        enrichedJourney.destinationName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: g.textAlpha(0.75),
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE74C3C),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE74C3C)
                                .withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Footer
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 13,
                        color: g.textAlpha(0.4)),
                    const SizedBox(width: 6),
                    Text(
                      AppDateUtils.formatDate(journey.journeyDate),
                      style: TextStyle(
                        color: g.textAlpha(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    _GlassStatusChip(isCompleted: isCompleted),
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

class _GlassStatusChip extends StatelessWidget {
  final bool isCompleted;
  const _GlassStatusChip({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final color =
        isCompleted ? const Color(0xFF27AE60) : const Color(0xFFE74C3C);
    final text = isCompleted ? 'Completed' : 'Cancelled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Favorite Card
// ─────────────────────────────────────────────

class _GlassFavoriteCard extends StatelessWidget {
  final EnrichedJourney enrichedJourney;
  final VoidCallback onReschedule;
  final VoidCallback onRemoveFavorite;

  const _GlassFavoriteCard({
    required this.enrichedJourney,
    required this.onReschedule,
    required this.onRemoveFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final journey = enrichedJourney.journey;
    final type = journey.transportType;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: g.cardFill(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: g.border(0.12),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              const Color(0xFFFF5252).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          size: 16, color: Color(0xFFFF5252)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: type.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: type.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(type.icon, size: 14, color: type.color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        journey.vehicleName ?? '${type.label} Journey',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: g.textAlpha(0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: onRemoveFavorite,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded,
                            size: 18,
                            color: g.textAlpha(0.3)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Route
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF27AE60)
                                .withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        enrichedJourney.boardingName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: g.textAlpha(0.75),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 12,
                          color: g.textAlpha(0.25)),
                    ),
                    Expanded(
                      child: Text(
                        enrichedJourney.destinationName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: g.textAlpha(0.75),
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE74C3C),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE74C3C)
                                .withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (journey.travelClass != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.airline_seat_recline_normal_rounded,
                          size: 13,
                          color: g.textAlpha(0.4)),
                      const SizedBox(width: 6),
                      Text(
                        'Class: ${journey.travelClass}',
                        style: TextStyle(
                          color: g.textAlpha(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // Reschedule button
                GestureDetector(
                  onTap: onReschedule,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00BCD4).withValues(alpha: 0.7),
                              const Color(0xFF00BCD4).withValues(alpha: 0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00BCD4)
                                  .withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note_rounded,
                                size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Reschedule Journey',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
