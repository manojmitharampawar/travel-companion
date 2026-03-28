import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/app_theme.dart';
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeysAsync = ref.watch(upcomingJourneysProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(upcomingJourneysProvider),
        color: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          slivers: [
            // ── Modern App Bar ─────────────────────────
            SliverAppBar(
              pinned: true,
              floating: false,
              expandedHeight: 130,
              collapsedHeight: kToolbarHeight,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 2,
              actions: [
                IconButton(
                  icon: const Icon(Icons.history_rounded, size: 22),
                  tooltip: 'Journey History',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_rounded, size: 22),
                  tooltip: 'Settings',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                titlePadding: EdgeInsets.zero,
                background: Builder(builder: (ctx) {
                  return _AppBarHero(
                    journeysAsync: journeysAsync,
                  );
                }),
              ),
            ),

            // ── Content ────────────────────────────────
            journeysAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _ErrorState(onRetry: () => ref.invalidate(upcomingJourneysProvider)),
                ),
              ),
              data: (journeys) {
                if (journeys.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyState(onAdd: () => _showAddOptions(context, ref)),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _JourneyCard(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context, ref),
        backgroundColor: AppTheme.secondaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Journey',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        elevation: 4,
      ),
    );
  }

  void _showAddOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddJourneySheet(
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
    if (result == true) ref.invalidate(upcomingJourneysProvider);
  }

  void _startQuickTrip(BuildContext context, WidgetRef ref) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickTripScreen()));
    ref.invalidate(upcomingJourneysProvider);
  }
}

// ─────────────────────────────────────────────
// App Bar Hero
// ─────────────────────────────────────────────

class _AppBarHero extends StatelessWidget {
  final AsyncValue<List<EnrichedJourney>> journeysAsync;

  const _AppBarHero({required this.journeysAsync});

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
    final activeCount = journeys.where((j) => j.journey.status == JourneyStatus.active).length;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
        ),
      ),
      // Decorative background circles
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -30,
            child: CircleAvatar(
              radius: 72,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -20,
            child: CircleAvatar(
              radius: 56,
              backgroundColor: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          // Content row
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            top: topPad + kToolbarHeight - 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                if (journeys.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.train_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          '${journeys.length}',
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
                            decoration: const BoxDecoration(
                              color: AppTheme.successColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$activeCount active',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Journey Card — compact with left accent strip
// ─────────────────────────────────────────────

class _JourneyCard extends ConsumerWidget {
  final EnrichedJourney enrichedJourney;

  const _JourneyCard({required this.enrichedJourney});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = enrichedJourney.journey;
    final isActive = journey.status == JourneyStatus.active;
    final isToday = journey.isToday;
    final type = journey.transportType;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JourneyDetailScreen(enrichedJourney: enrichedJourney),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isActive
                  ? AppTheme.successColor.withValues(alpha: 0.04)
                  : Colors.white,
              border: Border.all(
                color: isActive
                    ? AppTheme.successColor.withValues(alpha: 0.4)
                    : Colors.grey.shade200,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left accent strip
                    Container(width: 4, color: type.color),

                    // Card body
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row 1: type badge + vehicle name + status
                            Row(
                              children: [
                                _TypeBadge(type: type, vehicleNumber: journey.vehicleNumber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    journey.vehicleName ??
                                        (journey.vehicleNumber != null
                                            ? '${type.label} ${journey.vehicleNumber}'
                                            : type.label),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _StatusBadge(status: journey.status),
                                const SizedBox(width: 4),
                                _FavoriteButton(
                                  isFavorite: journey.isFavorite,
                                  onToggle: () async {
                                    final repo = ref.read(journeyRepositoryProvider);
                                    await repo.toggleFavorite(journey.id!, !journey.isFavorite);
                                    ref.invalidate(upcomingJourneysProvider);
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Row 2: horizontal origin → destination
                            Row(
                              children: [
                                Icon(Icons.circle, size: 7, color: AppTheme.successColor),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    enrichedJourney.boardingName,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(Icons.arrow_forward_rounded,
                                      size: 13, color: Colors.grey.shade400),
                                ),
                                Expanded(
                                  child: Text(
                                    enrichedJourney.destinationName,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(Icons.location_on, size: 7, color: AppTheme.dangerColor),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Row 3: chips in a horizontal scroll
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                spacing: 6,
                                children: [
                                  _InfoChip(
                                    icon: Icons.calendar_today_rounded,
                                    label: AppDateUtils.relativeDay(journey.journeyDate),
                                    highlight: isToday,
                                  ),
                                  if (journey.scheduledTime != null)
                                    _InfoChip(
                                      icon: Icons.schedule_rounded,
                                      label: journey.scheduledTime!,
                                    ),
                                  if (journey.travelClass != null)
                                    _InfoChip(
                                      icon: Icons.airline_seat_recline_normal_rounded,
                                      label: journey.travelClass!,
                                    ),
                                  if (journey.pnr != null)
                                    _InfoChip(
                                      icon: Icons.confirmation_number_outlined,
                                      label: 'PNR: ${journey.pnr}',
                                    ),
                                  if (journey.isRepeating)
                                    _InfoChip(
                                      icon: Icons.repeat_rounded,
                                      label: journey.repeatDaysDisplay,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right arrow indicator
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Center(
                        child: Icon(Icons.chevron_right_rounded,
                            size: 20, color: Color(0xFFBDBDBD)),
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

class _TypeBadge extends StatelessWidget {
  final TransportType type;
  final String? vehicleNumber;

  const _TypeBadge({required this.type, required this.vehicleNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: type.color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 12, color: Colors.white),
          if (vehicleNumber != null && vehicleNumber!.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              vehicleNumber!,
              style: const TextStyle(
                color: Colors.white,
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = highlight
        ? AppTheme.warningColor.withValues(alpha: 0.12)
        : Colors.grey.shade100;
    final fgColor = highlight ? AppTheme.warningColor : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: highlight
            ? Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fgColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final JourneyStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (status) {
      JourneyStatus.upcoming => (AppTheme.infoColor, 'Upcoming'),
      JourneyStatus.active => (AppTheme.successColor, 'Active'),
      JourneyStatus.completed => (Colors.grey, 'Done'),
      JourneyStatus.cancelled => (AppTheme.dangerColor, 'Cancelled'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onToggle;

  const _FavoriteButton({required this.isFavorite, required this.onToggle});

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
          color: isFavorite ? Colors.redAccent : Colors.grey.shade400,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add Journey Bottom Sheet
// ─────────────────────────────────────────────

class _AddJourneySheet extends StatelessWidget {
  final void Function(TransportType) onSelected;
  final VoidCallback onQuickTrip;

  const _AddJourneySheet({required this.onSelected, required this.onQuickTrip});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: Colors.grey.shade300,
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
                    Text(
                      'Add New Journey',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose your mode of transport',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary),
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
                  return _TransportTile(
                    type: type,
                    onTap: () => onSelected(type),
                  );
                }).toList(),
              ),

              const SizedBox(height: 10),

              // Quick trip full-width
              _QuickTripTile(onTap: onQuickTrip),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransportTile extends StatelessWidget {
  final TransportType type;
  final VoidCallback onTap;

  const _TransportTile({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: type.color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: type.color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
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
    );
  }
}

class _QuickTripTile extends StatelessWidget {
  final VoidCallback onTap;
  const _QuickTripTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.successColor, Color.lerp(AppTheme.successColor, Colors.teal, 0.4)!],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flash_on_rounded, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Trip',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.white)),
                    Text('Start tracking right away',
                        style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty & Error States
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.08),
                  AppTheme.secondaryColor.withValues(alpha: 0.06),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.train_rounded, size: 64, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 32),
          const Text(
            'No Upcoming Journeys',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Add your first journey to start receiving GPS arrival alerts for trains, buses, metro, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Your First Journey'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded,
                size: 52, color: AppTheme.dangerColor),
          ),
          const SizedBox(height: 24),
          const Text(
            'Something went wrong',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
