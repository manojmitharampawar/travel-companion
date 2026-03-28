import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/local_train_line.dart';
import 'package:travel_companion/data/models/local_train_schedule.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/local_train/local_train_journey_notifier.dart';

class AddLocalTrainJourneyScreen extends ConsumerWidget {
  const AddLocalTrainJourneyScreen({super.key});

  static const _accent = Color(0xFFE65100);
  static const _accentLight = Color(0xFFFF8A50);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localTrainJourneyNotifierProvider);
    final notifier = ref.read(localTrainJourneyNotifierProvider.notifier);

    ref.listen<LocalTrainJourneyState>(localTrainJourneyNotifierProvider,
        (prev, next) {
      if (next.savedSuccessfully) Navigator.pop(context, true);
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: GlassColors.of(context).bg,
      body: GlassMeshBackground(
        primaryColor: _accent,
        child: CustomScrollView(
          slivers: [
            // ── Glass App Bar ──
            SliverAppBar(
              pinned: true,
              expandedHeight: MediaQuery.paddingOf(context).top +
                  kToolbarHeight +
                  80,
              backgroundColor: Colors.transparent,
              foregroundColor: GlassColors.of(context).appBarForeground,
              elevation: 0,
              scrolledUnderElevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: GlassAppBarHero(
                  primaryColor: _accent,
                  secondaryColor: _accentLight,
                  icon: TransportType.localTrain.icon,
                  title: 'Local Train Schedule',
                  subtitle: 'Find next trains & start tracking',
                ),
              ),
            ),

            // ── Step indicator ──
            SliverToBoxAdapter(
              child: GlassStepIndicator(
                currentStep: state.currentStep,
                labels: const ['Select Line', 'Pick Stations', 'Choose Train'],
                accent: _accent,
              ),
            ),

            // ── Content ──
            SliverPadding(
              padding: const EdgeInsets.only(top: 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // STEP 0: Line selection
                  if (state.currentStep == 0)
                    _GlassLineSelection(
                      lines: state.availableLines,
                      isLoading: state.isLoadingLines,
                      onSelect: notifier.selectLine,
                      accent: _accent,
                    ),

                  // STEP 1+: Show selected line chip
                  if (state.currentStep >= 1)
                    _GlassSelectedLineChip(
                      line: state.selectedLine!,
                      onChangePressed: notifier.goBackToLineSelection,
                    ),

                  // STEP 1: Station selection
                  if (state.currentStep >= 1)
                    _GlassStationSelection(
                      stations: state.lineStations,
                      isLoading: state.isLoadingStations,
                      sourceStation: state.sourceStation,
                      destStation: state.destStation,
                      onSourceChanged: notifier.setSourceStation,
                      onDestChanged: notifier.setDestStation,
                      onSwap: notifier.swapStations,
                      accent: _accent,
                    ),

                  // STEP 2: Schedule + save
                  if (state.currentStep >= 2) ...[
                    _GlassScheduleResults(
                      trains: state.upcomingTrains,
                      isLoading: state.isLoadingSchedule,
                      selectedTrain: state.selectedTrain,
                      onTrainSelected: notifier.selectTrain,
                      onRefresh: notifier.fetchUpcomingTrains,
                      accent: _accent,
                    ),
                    if (state.selectedTrain != null) ...[
                      GlassSectionCard(
                        title: 'OPTIONS',
                        icon: Icons.tune,
                        accentColor: _accent,
                        children: [
                          GlassDropdownField<String>(
                            label: 'Class (optional)',
                            prefixIcon:
                                Icons.airline_seat_recline_normal_outlined,
                            prefixIconColor:
                                Colors.white.withValues(alpha: 0.5),
                            value: (state.travelClass == null ||
                                    state.travelClass!.isEmpty)
                                ? null
                                : state.travelClass,
                            items: const [
                              DropdownMenuItem(
                                  value: 'FC',
                                  child: Text('First Class \u2014 FC')),
                              DropdownMenuItem(
                                  value: 'SC',
                                  child: Text('Second Class \u2014 SC')),
                              DropdownMenuItem(
                                  value: 'Ladies',
                                  child: Text('Ladies Coach')),
                              DropdownMenuItem(
                                  value: 'Divyang',
                                  child: Text('Divyang Coach')),
                            ],
                            onChanged: notifier.setTravelClass,
                          ),
                        ],
                      ),
                      GlassButton(
                        label: 'Start Journey & Track',
                        icon: Icons.play_arrow_rounded,
                        accentColor: _accent,
                        isLoading: state.isSaving,
                        onPressed: () => notifier.save(),
                      ),
                    ],
                  ],

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Line Selection
// ─────────────────────────────────────────────

class _GlassLineSelection extends StatelessWidget {
  final List<LocalTrainLine> lines;
  final bool isLoading;
  final ValueChanged<LocalTrainLine> onSelect;
  final Color accent;

  const _GlassLineSelection({
    required this.lines,
    required this.isLoading,
    required this.onSelect,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
            child: CircularProgressIndicator(color: Colors.white70)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              'Choose your line',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          ...lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(16),
                  onTap: () => onSelect(line),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 44,
                        decoration: BoxDecoration(
                          color: line.lineColor,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: line.lineColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.lineName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${line.startStation ?? ''} \u2192 ${line.endStation ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: line.lineColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: line.lineColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          line.lineCode,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: line.lineColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right,
                          color: Colors.white.withValues(alpha: 0.3)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Selected Line Chip
// ─────────────────────────────────────────────

class _GlassSelectedLineChip extends StatelessWidget {
  final LocalTrainLine line;
  final VoidCallback onChangePressed;

  const _GlassSelectedLineChip({
    required this.line,
    required this.onChangePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 22,
            decoration: BoxDecoration(
              color: line.lineColor,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: line.lineColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            line.lineName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: line.lineColor,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onChangePressed,
            icon: Icon(Icons.swap_horiz,
                size: 16, color: Colors.white.withValues(alpha: 0.6)),
            label: Text('Change',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6))),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Station Selection
// ─────────────────────────────────────────────

class _GlassStationSelection extends StatelessWidget {
  final List<LocalTrainStation> stations;
  final bool isLoading;
  final LocalTrainStation? sourceStation;
  final LocalTrainStation? destStation;
  final ValueChanged<LocalTrainStation?> onSourceChanged;
  final ValueChanged<LocalTrainStation?> onDestChanged;
  final VoidCallback onSwap;
  final Color accent;

  const _GlassStationSelection({
    required this.stations,
    required this.isLoading,
    required this.sourceStation,
    required this.destStation,
    required this.onSourceChanged,
    required this.onDestChanged,
    required this.onSwap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
            child: CircularProgressIndicator(color: Colors.white70)),
      );
    }

    final srcFiltered = destStation != null
        ? stations.where((s) => s.id != destStation!.id).toList()
        : stations;
    final dstFiltered = sourceStation != null
        ? stations.where((s) => s.id != sourceStation!.id).toList()
        : stations;

    return GlassSectionCard(
      title: 'SELECT STATIONS',
      icon: Icons.alt_route,
      accentColor: accent,
      children: [
        GlassDropdownField<int>(
          label: 'From (Source)',
          prefixIcon: Icons.trip_origin,
          prefixIconColor: Colors.greenAccent,
          value: sourceStation?.id,
          items: srcFiltered
              .map((s) => DropdownMenuItem<int>(
                    value: s.id,
                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (id) {
            if (id == null) return onSourceChanged(null);
            onSourceChanged(stations.firstWhere((s) => s.id == id));
          },
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: onSwap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.swap_vert,
                      size: 20, color: accent),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GlassDropdownField<int>(
          label: 'To (Destination)',
          prefixIcon: Icons.place,
          prefixIconColor: Colors.redAccent.shade100,
          value: destStation?.id,
          items: dstFiltered
              .map((s) => DropdownMenuItem<int>(
                    value: s.id,
                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (id) {
            if (id == null) return onDestChanged(null);
            onDestChanged(stations.firstWhere((s) => s.id == id));
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Schedule Results
// ─────────────────────────────────────────────

class _GlassScheduleResults extends StatelessWidget {
  final List<UpcomingTrain> trains;
  final bool isLoading;
  final UpcomingTrain? selectedTrain;
  final ValueChanged<UpcomingTrain> onTrainSelected;
  final VoidCallback onRefresh;
  final Color accent;

  const _GlassScheduleResults({
    required this.trains,
    required this.isLoading,
    required this.selectedTrain,
    required this.onTrainSelected,
    required this.onRefresh,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSectionCard(
      title: 'NEXT TRAINS',
      icon: Icons.schedule,
      accentColor: accent,
      children: [
        // Refresh row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: onRefresh,
              child: Row(
                children: [
                  Icon(Icons.refresh,
                      size: 16, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
                child: CircularProgressIndicator(color: Colors.white70)),
          )
        else if (trains.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.train_outlined,
                      size: 40, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Text('No more trains today',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5))),
                  const SizedBox(height: 4),
                  Text('Try swapping direction or check tomorrow',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.3))),
                ],
              ),
            ),
          )
        else
          ...trains.map((t) => GlassTrainCard(
                formattedDeparture: t.formattedDeparture,
                formattedArrival: t.formattedArrival,
                travelDuration: t.travelDuration,
                stopsCount: t.stopsCount,
                trainTypeLabel: t.trainTypeLabel,
                isFast:
                    t.trainType == 'FAST' || t.trainType == 'SEMI_FAST',
                lineColor: t.lineColor,
                isSelected:
                    selectedTrain?.schedule.id == t.schedule.id,
                onTap: () => onTrainSelected(t),
                accent: accent,
              )),
      ],
    );
  }
}
