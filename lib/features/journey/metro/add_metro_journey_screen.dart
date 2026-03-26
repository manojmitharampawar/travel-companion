import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/metro/metro_journey_notifier.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';

class AddMetroJourneyScreen extends ConsumerStatefulWidget {
  const AddMetroJourneyScreen({super.key});

  @override
  ConsumerState<AddMetroJourneyScreen> createState() => _AddMetroJourneyScreenState();
}

class _AddMetroJourneyScreenState extends ConsumerState<AddMetroJourneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lineCtrl = TextEditingController();

  static const _type = TransportType.metro;
  static const _accent = Color(0xFF6A1B9A); // Deep purple

  @override
  void dispose() {
    _lineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(metroJourneyNotifierProvider);
    final notifier = ref.read(metroJourneyNotifierProvider.notifier);

    ref.listen<MetroJourneyState>(metroJourneyNotifierProvider, (prev, next) {
      if (next.savedSuccessfully) {
        Navigator.pop(context, true);
      }
      if (next.errorMessage != null && prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

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
                    subtitle: 'Never miss your metro stop again',
                  ),
                ),
              );
            }),

            // ── Content ──────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.only(top: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── SECTION: Metro Details ─────────
                  FormSectionCard(
                    title: 'METRO DETAILS',
                    icon: Icons.subway,
                    accentColor: _accent,
                    children: [
                      TextFormField(
                        controller: _lineCtrl,
                        decoration: InputDecoration(
                          labelText: 'Metro Line (optional)',
                          hintText: 'e.g. Blue Line, Yellow Line',
                          prefixIcon: const Icon(Icons.linear_scale_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          helperText: 'Specify the line for better tracking accuracy',
                        ),
                        onChanged: notifier.setLineName,
                      ),
                    ],
                  ),

                  // ── SECTION: Route ─────────────────
                  FormSectionCard(
                    title: 'JOURNEY ROUTE',
                    icon: Icons.alt_route,
                    accentColor: _accent,
                    children: [
                      StationAutocompleteField(
                        label: 'Boarding Station *',
                        hint: 'Search metro station',
                        leadingIcon: Icons.trip_origin,
                        selected: state.boardingStation,
                        searchFn: notifier.searchMetroStations,
                        onChanged: notifier.setBoardingStation,
                        accentColor: _accent,
                        validator: (s) => s == null ? 'Select boarding station' : null,
                      ),

                      const SizedBox(height: 8),
                      // Metro route dots
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Row(
                          children: [
                            Column(
                              children: List.generate(
                                4,
                                (i) => Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _accent.withValues(alpha: 0.4 + i * 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      StationAutocompleteField(
                        label: 'Destination Station *',
                        hint: 'Search metro station',
                        leadingIcon: Icons.place,
                        selected: state.destinationStation,
                        searchFn: notifier.searchMetroStations,
                        onChanged: notifier.setDestinationStation,
                        accentColor: _accent,
                        validator: (s) => s == null ? 'Select destination station' : null,
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

                  // ── Quick Tip Banner ───────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _accent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: _accent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You\'ll get an alarm 2 stations before your destination.',
                              style: TextStyle(
                                fontSize: 13,
                                color: _accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
