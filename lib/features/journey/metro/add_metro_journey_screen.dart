import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/data/models/metro_line.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/metro/metro_journey_notifier.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';
import 'package:travel_companion/features/map/metro_journey_map_widget.dart';

class AddMetroJourneyScreen extends ConsumerStatefulWidget {
  const AddMetroJourneyScreen({super.key});

  @override
  ConsumerState<AddMetroJourneyScreen> createState() =>
      _AddMetroJourneyScreenState();
}

class _AddMetroJourneyScreenState extends ConsumerState<AddMetroJourneyScreen> {
  final _formKey = GlobalKey<FormState>();

  static const _type = TransportType.metro;
  static const _accent = Color(0xFF006BB6); // Metro blue

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(metroJourneyNotifierProvider.notifier).loadCities();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(metroJourneyNotifierProvider);
    final notifier = ref.read(metroJourneyNotifierProvider.notifier);

    // ── Side-effects ─────────────────────────────
    ref.listen<MetroJourneyState>(metroJourneyNotifierProvider, (prev, next) {
      if (next.savedSuccessfully) {
        Navigator.pop(context, true);
      }
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final hasStations = state.stationsOnLine.isNotEmpty;
    final isReady =
        state.boardingStation != null && state.destinationStation != null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────
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
                    title: 'Add Metro Journey',
                    subtitle: 'Select line and stations for smart tracking',
                  ),
                ),
              );
            }),

            // ── Content ──────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.only(top: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── SECTION: City Selection ────────
                  FormSectionCard(
                    title: 'SELECT CITY',
                    icon: Icons.location_city,
                    accentColor: _accent,
                    children: [
                      if (state.isLoadingCities)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: state.city.isEmpty ? null : state.city,
                          decoration: InputDecoration(
                            labelText: 'Metro City *',
                            hintText: 'Choose your city',
                            prefixIcon:
                                const Icon(Icons.location_city_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: state.availableCities
                              .map((city) => DropdownMenuItem(
                                    value: city,
                                    child: Text(city),
                                  ))
                              .toList(),
                          onChanged: (city) {
                            if (city != null) notifier.setCity(city);
                          },
                          validator: (_) => state.city.isEmpty
                              ? 'Please select a city'
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                    ],
                  ),

                  // ── SECTION: Metro Line ────────────
                  if (state.city.isNotEmpty)
                    FormSectionCard(
                      title: 'SELECT METRO LINE',
                      icon: Icons.directions_subway,
                      accentColor: _accent,
                      children: [
                        if (state.isLoadingLines)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(_accent),
                              ),
                            ),
                          )
                        else if (state.availableLines.isEmpty)
                          _InfoBanner(
                            message: 'No metro lines available in this city',
                            icon: Icons.info_outline,
                            color: Colors.orange,
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: state.availableLines
                                .map((line) => _MetroLineChip(
                                      line: line,
                                      isSelected:
                                          state.selectedLine?.id == line.id,
                                      onTap: () => notifier.selectLine(line),
                                    ))
                                .toList(),
                          ),
                      ],
                    ),

                  // ── SECTION: Station Route ─────────
                  if (state.selectedLine != null)
                    FormSectionCard(
                      title: 'JOURNEY ROUTE',
                      icon: Icons.alt_route,
                      accentColor: _accent,
                      children: [
                        if (state.isLoadingStations)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(_accent),
                              ),
                            ),
                          )
                        else ...[
                          // Boarding station
                          DropdownButtonFormField<int>(
                            initialValue: state.boardingStation?.id,
                            decoration: InputDecoration(
                              labelText: 'Boarding Station *',
                              hintText: 'Choose origin',
                              prefixIcon: Icon(Icons.trip_origin,
                                  color: Colors.green.shade600),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: hasStations
                                ? state.stationsOnLine
                                    .map((station) => DropdownMenuItem(
                                          value: station.id,
                                          child: Text(
                                            station.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ))
                                    .toList()
                                : [],
                            onChanged: (stationId) {
                              if (stationId != null) {
                                final station = state.stationsOnLine
                                    .firstWhere((s) => s.id == stationId);
                                notifier.setBoardingStation(station);
                              }
                            },
                            validator: (_) => state.boardingStation == null
                                ? 'Select boarding station'
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),

                          const SizedBox(height: 8),

                          // Route line connector
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Container(
                              width: 2,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.green.shade600,
                                    Colors.red.shade600,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Destination station
                          DropdownButtonFormField<int>(
                            initialValue: state.destinationStation?.id,
                            decoration: InputDecoration(
                              labelText: 'Destination Station *',
                              hintText: state.boardingStation == null
                                  ? 'Select boarding station first'
                                  : 'Choose destination',
                              prefixIcon: Icon(Icons.place,
                                  color: Colors.red.shade600),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: hasStations && state.boardingStation != null
                                ? state.stationsOnLine
                                    .where((s) =>
                                        s.stationIndex >
                                        state.boardingStation!.stationIndex)
                                    .map((station) => DropdownMenuItem(
                                          value: station.id,
                                          child: Text(
                                            station.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ))
                                    .toList()
                                : [],
                            onChanged: state.boardingStation == null
                                ? null
                                : (stationId) {
                                    if (stationId != null) {
                                      final station = state.stationsOnLine
                                          .firstWhere(
                                              (s) => s.id == stationId);
                                      notifier.setDestinationStation(station);
                                    }
                                  },
                            validator: (_) => state.destinationStation == null
                                ? 'Select destination station'
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ],
                      ],
                    ),

                  // ── SECTION: Route Preview Map ─────
                  if (isReady && state.selectedLine != null)
                    FormSectionCard(
                      title: 'ROUTE PREVIEW',
                      icon: Icons.map_outlined,
                      accentColor: _accent,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 250,
                            child: MetroJourneyMapWidget(
                              stations: state.stationsOnLine,
                              originStation: state.boardingStation,
                              destinationStation: state.destinationStation,
                              lineColor:
                                  state.selectedLine!.lineColorHex ?? '#006BB6',
                            ),
                          ),
                        ),
                      ],
                    ),

                  // ── SECTION: Journey Info ──────────
                  FormSectionCard(
                    title: 'JOURNEY INFO',
                    icon: Icons.info_outline,
                    accentColor: _accent,
                    children: [
                      JourneyDateField(
                        value: state.journeyDate,
                        onChanged: notifier.setJourneyDate,
                        accentColor: _accent,
                      ),
                      fieldSpacing,
                      JourneyTimeField(
                        value: state.departureTime,
                        onChanged: notifier.setDepartureTime,
                        accentColor: _accent,
                      ),
                    ],
                  ),

                  // ── Save Button ────────────────────
                  SaveJourneyButton(
                    isSaving: state.isSaving,
                    accentColor: _accent,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) notifier.save();
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Metro Line Chip
// ─────────────────────────────────────────────────────

class _MetroLineChip extends StatelessWidget {
  final MetroLine line;
  final bool isSelected;
  final VoidCallback onTap;

  const _MetroLineChip({
    required this.line,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor = line.color;
    return FilterChip(
      label: Text(line.displayName),
      selected: isSelected,
      onSelected: (_) => onTap(),
      avatar: isSelected
          ? null
          : CircleAvatar(
              backgroundColor: lineColor,
              radius: 6,
            ),
      selectedColor: lineColor.withValues(alpha: 0.2),
      checkmarkColor: lineColor,
      labelStyle: TextStyle(
        color: isSelected ? lineColor : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? lineColor : lineColor.withValues(alpha: 0.4),
        width: isSelected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}

// ─────────────────────────────────────────────────────
// Info Banner
// ─────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final MaterialColor color;

  const _InfoBanner({
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
