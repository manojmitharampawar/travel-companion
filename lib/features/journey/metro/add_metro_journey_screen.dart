import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/metro_line.dart';
import 'package:travel_companion/data/models/metro_schedule.dart';
import 'package:travel_companion/data/models/metro_station.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/metro/metro_journey_notifier.dart';

class AddMetroJourneyScreen extends ConsumerWidget {
  const AddMetroJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = GlassColors.of(context);
    final accent = g.metroAccent;
    final accentLight = g.metroAccentLight;
    final state = ref.watch(metroJourneyNotifierProvider);
    final notifier = ref.read(metroJourneyNotifierProvider.notifier);

    ref.listen<MetroJourneyState>(metroJourneyNotifierProvider, (prev, next) {
      if (next.savedSuccessfully) Navigator.pop(context, true);
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        AdaptiveFeedback.showToast(context, next.errorMessage!, isError: true);
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: GlassColors.of(context).bg,
      child: GlassMeshBackground(
        primaryColor: accent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Builder(
                builder: (ctx) {
                  final g = GlassColors.of(ctx);
                  final topPad = MediaQuery.paddingOf(ctx).top;
                  final height = topPad + kToolbarHeight + 80;
                  return SizedBox(
                    height: height,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GlassAppBarHero(
                            primaryColor: accent,
                            secondaryColor: accentLight,
                            icon: TransportType.metro.icon,
                            title: 'Metro Schedule',
                            subtitle: 'Find next metro & start tracking',
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
                                          'Metro Schedule',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 44),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Step indicator ──
            SliverToBoxAdapter(
              child: GlassStepIndicator(
                currentStep: state.currentStep,
                labels: const ['City', 'Line', 'Stations', 'Schedule'],
                accent: accent,
              ),
            ),

            // ── Content ──
            SliverPadding(
              padding: const EdgeInsets.only(top: 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // STEP 0: City selection
                  if (state.currentStep == 0)
                    _GlassCitySelection(
                      cities: state.availableCities,
                      isLoading: state.isLoadingCities,
                      onSelect: notifier.setCity,
                      accent: accent,
                    ),

                  // STEP 1+: City chip
                  if (state.currentStep >= 1)
                    _GlassSelectedChip(
                      icon: Icons.location_city,
                      label: state.city,
                      color: accent,
                      onChangePressed: notifier.goBackToCitySelection,
                    ),

                  // STEP 1: Line selection
                  if (state.currentStep == 1)
                    _GlassMetroLineSelection(
                      lines: state.availableLines,
                      isLoading: state.isLoadingLines,
                      onSelect: notifier.selectLine,
                    ),

                  // STEP 2+: Line chip
                  if (state.currentStep >= 2)
                    _GlassSelectedLineChip(
                      line: state.selectedLine!,
                      onChangePressed: notifier.goBackToLineSelection,
                    ),

                  // STEP 2: Station selection
                  if (state.currentStep >= 2)
                    _GlassStationSelection(
                      stations: state.stationsOnLine,
                      isLoading: state.isLoadingStations,
                      sourceStation: state.sourceStation,
                      destStation: state.destStation,
                      onSourceChanged: notifier.setSourceStation,
                      onDestChanged: notifier.setDestStation,
                      onSwap: notifier.swapStations,
                      accent: accent,
                    ),

                  // STEP 3: Schedule + save
                  if (state.currentStep >= 3) ...[
                    _GlassScheduleResults(
                      trains: state.upcomingTrains,
                      isLoading: state.isLoadingSchedule,
                      selectedTrain: state.selectedTrain,
                      onTrainSelected: notifier.selectTrain,
                      onRefresh: notifier.fetchUpcomingTrains,
                      accent: accent,
                    ),
                    if (state.selectedTrain != null)
                      GlassButton(
                        label: 'Start Journey & Track',
                        icon: Icons.play_arrow_rounded,
                        accentColor: accent,
                        isLoading: state.isSaving,
                        onPressed: () => notifier.save(),
                      ),
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
// City Selection
// ─────────────────────────────────────────────

class _GlassCitySelection extends StatelessWidget {
  final List<String> cities;
  final bool isLoading;
  final ValueChanged<String> onSelect;
  final Color accent;

  const _GlassCitySelection({
    required this.cities,
    required this.isLoading,
    required this.onSelect,
    required this.accent,
  });

  static const _cityIcons = <String, IconData>{
    'Delhi': Icons.account_balance,
    'Mumbai': Icons.location_city,
    'Bangalore': Icons.apartment,
    'Kolkata': Icons.temple_hindu,
    'Chennai': Icons.temple_buddhist,
    'Hyderabad': Icons.mosque,
  };

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(color: g.textAlpha(0.7)),
        ),
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
              'Choose your city',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: g.textAlpha(0.9),
              ),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cities.map((city) {
              return GestureDetector(
                onTap: () => onSelect(city),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: g.cardFill(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: g.border(0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _cityIcons[city] ?? Icons.location_city,
                            size: 18,
                            color: accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            city,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: g.text,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Selected Chip (generic)
// ─────────────────────────────────────────────

class _GlassSelectedChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onChangePressed;

  const _GlassSelectedChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onChangePressed,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onChangePressed,
            icon: Icon(Icons.swap_horiz, size: 16, color: g.textAlpha(0.6)),
            label: Text(
              'Change',
              style: TextStyle(fontSize: 12, color: g.textAlpha(0.6)),
            ),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Line Selection
// ─────────────────────────────────────────────

class _GlassMetroLineSelection extends StatelessWidget {
  final List<MetroLine> lines;
  final bool isLoading;
  final ValueChanged<MetroLine> onSelect;

  const _GlassMetroLineSelection({
    required this.lines,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(color: g.textAlpha(0.7)),
        ),
      );
    }

    if (lines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No metro lines available',
            style: TextStyle(color: g.textAlpha(0.5)),
          ),
        ),
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
              'Select metro line',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: g.textAlpha(0.9),
              ),
            ),
          ),
          ...lines.map(
            (line) => Padding(
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
                        color: line.color,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: line.color.withValues(alpha: 0.5),
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
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: g.text,
                            ),
                          ),
                          if (line.lineCode != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              line.lineCode!,
                              style: TextStyle(
                                fontSize: 12,
                                color: g.textAlpha(0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: line.color.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.directions_subway,
                        size: 16,
                        color: line.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: g.textAlpha(0.3)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSelectedLineChip extends StatelessWidget {
  final MetroLine line;
  final VoidCallback onChangePressed;

  const _GlassSelectedLineChip({
    required this.line,
    required this.onChangePressed,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 22,
            decoration: BoxDecoration(
              color: line.color,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: line.color.withValues(alpha: 0.5),
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
              color: line.color,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onChangePressed,
            icon: Icon(Icons.swap_horiz, size: 16, color: g.textAlpha(0.6)),
            label: Text(
              'Change',
              style: TextStyle(fontSize: 12, color: g.textAlpha(0.6)),
            ),
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
  final List<MetroStation> stations;
  final bool isLoading;
  final MetroStation? sourceStation;
  final MetroStation? destStation;
  final ValueChanged<MetroStation?> onSourceChanged;
  final ValueChanged<MetroStation?> onDestChanged;
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
    final g = GlassColors.of(context);
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(color: g.loadingIndicator),
        ),
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
              .map(
                (s) => DropdownMenuItem<int>(
                  value: s.id,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                ),
              )
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
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.swap_vert, size: 20, color: accent),
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
              .map(
                (s) => DropdownMenuItem<int>(
                  value: s.id,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                ),
              )
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
  final List<UpcomingMetro> trains;
  final bool isLoading;
  final UpcomingMetro? selectedTrain;
  final ValueChanged<UpcomingMetro> onTrainSelected;
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
    final g = GlassColors.of(context);
    return GlassSectionCard(
      title: 'NEXT METROS',
      icon: Icons.schedule,
      accentColor: accent,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: onRefresh,
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 16, color: g.textAlpha(0.5)),
                  const SizedBox(width: 4),
                  Text(
                    'Refresh',
                    style: TextStyle(fontSize: 11, color: g.textAlpha(0.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isLoading)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: g.textAlpha(0.7)),
            ),
          )
        else if (trains.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.directions_subway_outlined,
                    size: 40,
                    color: g.textAlpha(0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No more metros today',
                    style: TextStyle(color: g.textAlpha(0.5)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try swapping direction or check tomorrow',
                    style: TextStyle(fontSize: 12, color: g.textAlpha(0.3)),
                  ),
                ],
              ),
            ),
          )
        else
          ...trains.map(
            (t) => GlassTrainCard(
              formattedDeparture: t.formattedDeparture,
              formattedArrival: t.formattedArrival,
              travelDuration: t.travelDuration,
              stopsCount: t.stopsCount,
              lineColor: t.lineColor,
              isSelected: selectedTrain?.schedule.id == t.schedule.id,
              onTap: () => onTrainSelected(t),
              accent: accent,
            ),
          ),
      ],
    );
  }
}
