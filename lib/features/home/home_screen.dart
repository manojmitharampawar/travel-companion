import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/providers/app_providers.dart';
import 'package:travel_companion/features/journey/bus/add_bus_journey_screen.dart';
import 'package:travel_companion/features/journey/journey_detail_screen.dart';
import 'package:travel_companion/features/journey/local_train/add_local_train_journey_screen.dart';
import 'package:travel_companion/features/journey/metro/add_metro_journey_screen.dart';
import 'package:travel_companion/features/journey/train/add_train_journey_screen.dart';
import 'package:travel_companion/features/journey/quick_trip_screen.dart';
import 'package:travel_companion/features/history/history_screen.dart';
import 'package:travel_companion/features/settings/settings_screen.dart';

// Glass design constants for home screen
const _kBgColor = Color(0xFF0A0E21);
const _kAccent = Color(0xFF0D47A1);
const _kSecondaryAccent = Color(0xFFFF9800);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeysAsync = ref.watch(upcomingJourneysProvider);

    return Scaffold(
      backgroundColor: _kBgColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Gradient mesh background with orbs
          const _HomeBackground(),

          // Main scrollable content
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(upcomingJourneysProvider);
              ref.invalidate(historyJourneysProvider);
            },
            color: _kSecondaryAccent,
            backgroundColor: const Color(0xFF1A2340),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Glass App Bar
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  expandedHeight: 150,
                  collapsedHeight: kToolbarHeight,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    titlePadding: EdgeInsets.zero,
                    background: _GlassAppBarContent(journeysAsync: journeysAsync),
                  ),
                  actions: [
                    _GlassIconButton(
                      icon: Icons.history_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      ),
                    ),
                    _GlassIconButton(
                      icon: Icons.settings_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // Content
                journeysAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: _kSecondaryAccent),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _GlassErrorState(
                        onRetry: () => ref.invalidate(upcomingJourneysProvider),
                      ),
                    ),
                  ),
                  data: (journeys) {
                    if (journeys.isEmpty) {
                      return SliverFillRemaining(
                        child: _GlassEmptyState(
                          onAdd: () => _showAddOptions(context, ref),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _GlassJourneyCard(
                            enrichedJourney: journeys[index],
                          ),
                          childCount: journeys.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),

      // Glass FAB
      floatingActionButton: _GlassFab(
        onTap: () => _showAddOptions(context, ref),
      ),
    );
  }

  void _showAddOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => _GlassAddJourneySheet(
        onSelected: (type) {
          Navigator.pop(context);
          _addJourney(context, ref, type);
        },
        onQuickTrip: () {
          Navigator.pop(context);
          _startQuickTrip(context, ref);
        },
      ),
    );
  }

  void _addJourney(BuildContext context, WidgetRef ref, TransportType type) async {
    final Widget screen = switch (type) {
      TransportType.train => const AddTrainJourneyScreen(),
      TransportType.bus => const AddBusJourneyScreen(),
      TransportType.metro => const AddMetroJourneyScreen(),
      TransportType.localTrain => const AddLocalTrainJourneyScreen(),
    };
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (result == true) {
      ref.invalidate(upcomingJourneysProvider);
      ref.invalidate(historyJourneysProvider);
    }
  }

  void _startQuickTrip(BuildContext context, WidgetRef ref) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickTripScreen()));
    ref.invalidate(upcomingJourneysProvider);
    ref.invalidate(historyJourneysProvider);
  }
}

// ─────────────────────────────────────────────
// Background with gradient orbs
// ─────────────────────────────────────────────

class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBgColor,
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(color: _kAccent, size: 250),
          ),
          Positioned(
            bottom: 120,
            left: -70,
            child: _GlowOrb(color: GlassConstants.meshPurple, size: 200),
          ),
          Positioned(
            top: 350,
            right: -40,
            child: _GlowOrb(color: GlassConstants.meshCyan, size: 150),
          ),
          Positioned(
            bottom: -40,
            right: 60,
            child: _GlowOrb(color: _kSecondaryAccent, size: 120),
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
// Glass Icon Button (app bar actions)
// ─────────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass App Bar Content (hero area)
// ─────────────────────────────────────────────

class _GlassAppBarContent extends StatelessWidget {
  final AsyncValue<List<EnrichedJourney>> journeysAsync;
  const _GlassAppBarContent({required this.journeysAsync});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final journeys = journeysAsync.valueOrNull ?? [];
    final activeCount =
        journeys.where((j) => j.journey.status == JourneyStatus.active).length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kAccent.withValues(alpha: 0.6),
            _kBgColor,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative blurred orbs inside header
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _kSecondaryAccent.withValues(alpha: 0.1),
                    _kSecondaryAccent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            top: topPad + kToolbarHeight - 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Glass icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(Icons.navigation_rounded,
                          size: 28, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Your Journeys',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (journeys.isNotEmpty) _JourneySummaryBadge(
                  total: journeys.length,
                  activeCount: activeCount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneySummaryBadge extends StatelessWidget {
  final int total;
  final int activeCount;
  const _JourneySummaryBadge({required this.total, required this.activeCount});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.route_rounded,
                  size: 14, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 5),
              Text(
                '$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if (activeCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF27AE60).withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$activeCount active',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Journey Card
// ─────────────────────────────────────────────

class _GlassJourneyCard extends ConsumerWidget {
  final EnrichedJourney enrichedJourney;
  const _GlassJourneyCard({required this.enrichedJourney});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = enrichedJourney.journey;
    final isActive = journey.status == JourneyStatus.active;
    final isToday = journey.isToday;
    final type = journey.transportType;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                JourneyDetailScreen(enrichedJourney: enrichedJourney),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF27AE60).withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF27AE60).withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.15),
                  width: isActive ? 1.5 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF27AE60).withValues(alpha: 0.12),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left accent strip with gradient
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            type.color,
                            type.color.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),

                    // Card body
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row 1: type badge + vehicle name + status + fav
                            Row(
                              children: [
                                _GlassTypeBadge(
                                  type: type,
                                  vehicleNumber: journey.vehicleNumber,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    journey.vehicleName ??
                                        (journey.vehicleNumber != null
                                            ? '${type.label} ${journey.vehicleNumber}'
                                            : type.label),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.92),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _GlassStatusBadge(status: journey.status),
                                const SizedBox(width: 4),
                                _GlassFavoriteButton(
                                  isFavorite: journey.isFavorite,
                                  onToggle: () async {
                                    final repo = ref.read(journeyRepositoryProvider);
                                    await repo.toggleFavorite(
                                        journey.id!, !journey.isFavorite);
                                    ref.invalidate(upcomingJourneysProvider);
                                    ref.invalidate(historyJourneysProvider);
                                    ref.invalidate(favoriteJourneysProvider);
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Row 2: origin → destination
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
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
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(Icons.arrow_forward_rounded,
                                      size: 13,
                                      color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                Expanded(
                                  child: Text(
                                    enrichedJourney.destinationName,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
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

                            const SizedBox(height: 10),

                            // Row 3: glass info chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _GlassInfoChip(
                                    icon: Icons.calendar_today_rounded,
                                    label: AppDateUtils.relativeDay(
                                        journey.journeyDate),
                                    highlight: isToday,
                                  ),
                                  if (journey.scheduledTime != null) ...[
                                    const SizedBox(width: 6),
                                    _GlassInfoChip(
                                      icon: Icons.schedule_rounded,
                                      label: journey.scheduledTime!,
                                    ),
                                  ],
                                  if (journey.travelClass != null) ...[
                                    const SizedBox(width: 6),
                                    _GlassInfoChip(
                                      icon:
                                          Icons.airline_seat_recline_normal_rounded,
                                      label: journey.travelClass!,
                                    ),
                                  ],
                                  if (journey.pnr != null) ...[
                                    const SizedBox(width: 6),
                                    _GlassInfoChip(
                                      icon: Icons.confirmation_number_outlined,
                                      label: 'PNR: ${journey.pnr}',
                                    ),
                                  ],
                                  if (journey.isRepeating) ...[
                                    const SizedBox(width: 6),
                                    _GlassInfoChip(
                                      icon: Icons.repeat_rounded,
                                      label: journey.repeatDaysDisplay,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right chevron
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Center(
                        child: Icon(Icons.chevron_right_rounded,
                            size: 20,
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTypeBadge extends StatelessWidget {
  final TransportType type;
  final String? vehicleNumber;
  const _GlassTypeBadge({required this.type, required this.vehicleNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: type.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 12, color: type.color),
          if (vehicleNumber != null && vehicleNumber!.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              vehicleNumber!,
              style: TextStyle(
                color: type.color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GlassStatusBadge extends StatelessWidget {
  final JourneyStatus status;
  const _GlassStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (status) {
      JourneyStatus.upcoming => (const Color(0xFF3498DB), 'Upcoming'),
      JourneyStatus.active => (const Color(0xFF27AE60), 'Active'),
      JourneyStatus.completed => (Colors.grey, 'Done'),
      JourneyStatus.cancelled => (const Color(0xFFE74C3C), 'Cancelled'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GlassInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;
  const _GlassInfoChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = highlight
        ? const Color(0xFFFFA726)
        : Colors.white.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFFFA726).withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? const Color(0xFFFFA726).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: chipColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassFavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onToggle;
  const _GlassFavoriteButton({required this.isFavorite, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 18,
          color: isFavorite
              ? const Color(0xFFFF5252)
              : Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Floating Action Button
// ─────────────────────────────────────────────

class _GlassFab extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kSecondaryAccent,
                  _kSecondaryAccent.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kSecondaryAccent.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'Add Journey',
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
    );
  }
}

// ─────────────────────────────────────────────
// Glass Add Journey Bottom Sheet
// ─────────────────────────────────────────────

class _GlassAddJourneySheet extends StatelessWidget {
  final void Function(TransportType) onSelected;
  final VoidCallback onQuickTrip;
  const _GlassAddJourneySheet({
    required this.onSelected,
    required this.onQuickTrip,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E21).withValues(alpha: 0.92),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.2,
              ),
              left: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              right: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add New Journey',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose your mode of transport',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2x2 transport grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: TransportType.values.map((type) {
                      return _GlassTransportTile(
                        type: type,
                        onTap: () => onSelected(type),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),

                  // Quick trip
                  _GlassQuickTripTile(onTap: onQuickTrip),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTransportTile extends StatelessWidget {
  final TransportType type;
  final VoidCallback onTap;
  const _GlassTransportTile({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: type.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: type.color.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: type.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(type.icon, size: 20, color: type.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    type.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: type.color,
                    ),
                    overflow: TextOverflow.ellipsis,
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

class _GlassQuickTripTile extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassQuickTripTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF27AE60).withValues(alpha: 0.8),
                  const Color(0xFF009688).withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF27AE60).withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flash_on_rounded,
                      size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Trip',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Start tracking right away',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded,
                    color: Colors.white.withValues(alpha: 0.7), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Empty & Error States
// ─────────────────────────────────────────────

class _GlassEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _GlassEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glass icon circle
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _kAccent.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(Icons.train_rounded,
                    size: 56, color: _kAccent.withValues(alpha: 0.8)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'No Upcoming Journeys',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Add your first journey to start receiving\nGPS arrival alerts for trains, buses,\nmetro, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          GestureDetector(
            onTap: onAdd,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kAccent, _kAccent.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kAccent.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add Your First Journey',
                        style: TextStyle(
                          fontSize: 15,
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
        ],
      ),
    );
  }
}

class _GlassErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _GlassErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
                  color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE74C3C).withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(Icons.error_outline_rounded,
                    size: 48, color: Color(0xFFE74C3C)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRetry,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.8)),
                      const SizedBox(width: 8),
                      Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
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
    );
  }
}
