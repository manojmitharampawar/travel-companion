import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/data/models/local_train_line.dart';
import 'package:travel_companion/data/models/local_train_schedule.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/local_train/local_train_journey_notifier.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';

class AddLocalTrainJourneyScreen extends ConsumerStatefulWidget {
  const AddLocalTrainJourneyScreen({super.key});

  @override
  ConsumerState<AddLocalTrainJourneyScreen> createState() =>
      _AddLocalTrainJourneyScreenState();
}

class _AddLocalTrainJourneyScreenState
    extends ConsumerState<AddLocalTrainJourneyScreen> {
  static const _type = TransportType.localTrain;
  static const _accent = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localTrainJourneyNotifierProvider);
    final notifier = ref.read(localTrainJourneyNotifierProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    ref.listen<LocalTrainJourneyState>(localTrainJourneyNotifierProvider,
        (prev, next) {
      if (next.savedSuccessfully) {
        Navigator.pop(context, true);
      }
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          Builder(builder: (ctx) {
            final topPad = MediaQuery.paddingOf(ctx).top;
            return SliverAppBar(
              pinned: true,
              expandedHeight: topPad + kToolbarHeight + 80,
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: TransportHeroHeader(
                  type: _type,
                  title: 'Local Train Schedule',
                  subtitle: 'Find next trains & start tracking',
                ),
              ),
            );
          }),

          // ── Step indicator ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: _StepIndicator(
                currentStep: state.currentStep,
                accent: _accent,
              ),
            ),
          ),

          // ── Content based on step ──
          SliverPadding(
            padding: const EdgeInsets.only(top: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── STEP 0: Line selection ──
                if (state.currentStep == 0) ...[
                  _LineSelectionSection(
                    lines: state.availableLines,
                    isLoading: state.isLoadingLines,
                    onSelect: notifier.selectLine,
                  ),
                ],

                // ── STEP 1: Station selection ──
                if (state.currentStep >= 1) ...[
                  _SelectedLineChip(
                    line: state.selectedLine!,
                    onChangePressed: notifier.goBackToLineSelection,
                  ),
                  _StationSelectionSection(
                    stations: state.lineStations,
                    isLoading: state.isLoadingStations,
                    sourceStation: state.sourceStation,
                    destStation: state.destStation,
                    onSourceChanged: notifier.setSourceStation,
                    onDestChanged: notifier.setDestStation,
                    onSwap: notifier.swapStations,
                    accent: _accent,
                  ),
                ],

                // ── STEP 2: Schedule results + save ──
                if (state.currentStep >= 2) ...[
                  _ScheduleResultsSection(
                    trains: state.upcomingTrains,
                    isLoading: state.isLoadingSchedule,
                    selectedTrain: state.selectedTrain,
                    onTrainSelected: notifier.selectTrain,
                    onRefresh: notifier.fetchUpcomingTrains,
                    accent: _accent,
                  ),
                  if (state.selectedTrain != null) ...[
                    // Class selector
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: FormSectionCard(
                        title: 'OPTIONS',
                        icon: Icons.tune,
                        accentColor: _accent,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: (state.travelClass == null ||
                                    state.travelClass!.isEmpty)
                                ? null
                                : state.travelClass,
                            decoration: InputDecoration(
                              labelText: 'Class (optional)',
                              prefixIcon: const Icon(
                                  Icons.airline_seat_recline_normal_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ],
                      ),
                    ),
                    SaveJourneyButton(
                      isSaving: state.isSaving,
                      accentColor: _accent,
                      label: 'Start Journey & Track',
                      onPressed: () => notifier.save(),
                    ),
                  ],
                ],

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step Indicator
// ─────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final Color accent;

  const _StepIndicator({required this.currentStep, required this.accent});

  @override
  Widget build(BuildContext context) {
    const labels = ['Select Line', 'Pick Stations', 'Choose Train'];
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(3, (i) {
        final isActive = i <= currentStep;
        final isCurrent = i == currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isActive ? accent : scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: accent, width: 2.5)
                      : null,
                ),
                child: Center(
                  child: isActive && i < currentStep
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? Colors.white
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? accent : scheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
// Line Selection
// ─────────────────────────────────────────────

class _LineSelectionSection extends StatelessWidget {
  final List<LocalTrainLine> lines;
  final bool isLoading;
  final ValueChanged<LocalTrainLine> onSelect;

  const _LineSelectionSection({
    required this.lines,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Choose your line',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          ...lines.map((line) => _LineCard(line: line, onTap: () => onSelect(line))),
        ],
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  final LocalTrainLine line;
  final VoidCallback onTap;

  const _LineCard({required this.line, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 44,
                decoration: BoxDecoration(
                  color: line.lineColor,
                  borderRadius: BorderRadius.circular(3),
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
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${line.startStation ?? ''} \u2192 ${line.endStation ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: line.lineColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
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
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Selected Line Chip (shown in steps 1+)
// ─────────────────────────────────────────────

class _SelectedLineChip extends StatelessWidget {
  final LocalTrainLine line;
  final VoidCallback onChangePressed;

  const _SelectedLineChip({
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
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: const Text('Change', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Station Selection
// ─────────────────────────────────────────────

class _StationSelectionSection extends StatelessWidget {
  final List<LocalTrainStation> stations;
  final bool isLoading;
  final LocalTrainStation? sourceStation;
  final LocalTrainStation? destStation;
  final ValueChanged<LocalTrainStation?> onSourceChanged;
  final ValueChanged<LocalTrainStation?> onDestChanged;
  final VoidCallback onSwap;
  final Color accent;

  const _StationSelectionSection({
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
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.alt_route, size: 16, color: accent),
                ),
                const SizedBox(width: 10),
                Text(
                  'SELECT STATIONS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.3,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Source station dropdown
            _StationDropdown(
              label: 'From (Source)',
              icon: Icons.trip_origin,
              iconColor: Colors.green.shade600,
              stations: stations,
              selected: sourceStation,
              onChanged: onSourceChanged,
              excludeStation: destStation,
            ),
            const SizedBox(height: 8),
            // Swap button
            Center(
              child: IconButton.filled(
                onPressed: onSwap,
                icon: const Icon(Icons.swap_vert, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: accent.withValues(alpha: 0.12),
                  foregroundColor: accent,
                ),
                tooltip: 'Swap stations',
              ),
            ),
            const SizedBox(height: 8),
            // Destination station dropdown
            _StationDropdown(
              label: 'To (Destination)',
              icon: Icons.place,
              iconColor: Colors.red.shade600,
              stations: stations,
              selected: destStation,
              onChanged: onDestChanged,
              excludeStation: sourceStation,
            ),
          ],
        ),
      ),
    );
  }
}

class _StationDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final List<LocalTrainStation> stations;
  final LocalTrainStation? selected;
  final ValueChanged<LocalTrainStation?> onChanged;
  final LocalTrainStation? excludeStation;

  const _StationDropdown({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.stations,
    required this.selected,
    required this.onChanged,
    this.excludeStation,
  });

  @override
  Widget build(BuildContext context) {
    final filteredStations = excludeStation != null
        ? stations.where((s) => s.id != excludeStation!.id).toList()
        : stations;

    return DropdownButtonFormField<int>(
      initialValue: selected?.id,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: iconColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      isExpanded: true,
      menuMaxHeight: 300,
      borderRadius: BorderRadius.circular(12),
      items: filteredStations.map((s) {
        return DropdownMenuItem<int>(
          value: s.id,
          child: Text(
            s.name,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (id) {
        if (id == null) {
          onChanged(null);
        } else {
          final station = stations.firstWhere((s) => s.id == id);
          onChanged(station);
        }
      },
    );
  }
}

// ─────────────────────────────────────────────
// Schedule Results
// ─────────────────────────────────────────────

class _ScheduleResultsSection extends StatelessWidget {
  final List<UpcomingTrain> trains;
  final bool isLoading;
  final UpcomingTrain? selectedTrain;
  final ValueChanged<UpcomingTrain> onTrainSelected;
  final VoidCallback onRefresh;
  final Color accent;

  const _ScheduleResultsSection({
    required this.trains,
    required this.isLoading,
    required this.selectedTrain,
    required this.onTrainSelected,
    required this.onRefresh,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.schedule, size: 16, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'NEXT TRAINS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                          letterSpacing: 0.3,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh',
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (trains.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.train_outlined,
                          size: 40, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        'No more trains today',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try swapping direction or check tomorrow',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...trains.map((t) => _TrainCard(
                    train: t,
                    isSelected: selectedTrain?.schedule.id == t.schedule.id,
                    onTap: () => onTrainSelected(t),
                    accent: accent,
                  )),
          ],
        ),
      ),
    );
  }
}

class _TrainCard extends StatelessWidget {
  final UpcomingTrain train;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accent;

  const _TrainCard({
    required this.train,
    required this.isSelected,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFast = train.trainType == 'FAST' || train.trainType == 'SEMI_FAST';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? accent.withValues(alpha: 0.08)
            : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? accent
                    : scheme.outlineVariant.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Departure time (large)
                Column(
                  children: [
                    Text(
                      train.formattedDeparture,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? accent : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DEP',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                // Arrow with duration
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isFast
                                  ? Colors.amber.shade700
                                  : scheme.outlineVariant,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              train.travelDuration,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isFast
                                  ? Colors.amber.shade700
                                  : scheme.outlineVariant,
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 10, color: scheme.onSurfaceVariant),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _TypeBadge(
                            label: train.trainTypeLabel,
                            color: isFast
                                ? Colors.amber.shade800
                                : scheme.onSurfaceVariant,
                            isFast: isFast,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${train.stopsCount} stops',
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Arrival time
                Column(
                  children: [
                    Text(
                      train.formattedArrival,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? accent : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ARR',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, color: accent, size: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isFast;

  const _TypeBadge({
    required this.label,
    required this.color,
    required this.isFast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFast) ...[
            Icon(Icons.bolt, size: 10, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
