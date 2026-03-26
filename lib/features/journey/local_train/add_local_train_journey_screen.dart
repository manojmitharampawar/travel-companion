import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _lineCtrl = TextEditingController();
  final _trainNumCtrl = TextEditingController();

  static const _type = TransportType.localTrain;
  static const _accent = Color(0xFFE65100); // Deep orange

  @override
  void dispose() {
    _lineCtrl.dispose();
    _trainNumCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localTrainJourneyNotifierProvider);
    final notifier = ref.read(localTrainJourneyNotifierProvider.notifier);

    ref.listen<LocalTrainJourneyState>(localTrainJourneyNotifierProvider, (prev, next) {
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
                    title: 'Add Local Train Journey',
                    subtitle: 'Track your daily local train commute',
                  ),
                ),
              );
            }),

            // ── Content ──────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.only(top: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── SECTION: Train Details ─────────
                  FormSectionCard(
                    title: 'TRAIN DETAILS',
                    icon: Icons.directions_railway,
                    accentColor: _accent,
                    children: [
                      TextFormField(
                        controller: _lineCtrl,
                        decoration: InputDecoration(
                          labelText: 'Line / Route Name (optional)',
                          hintText: 'e.g. Central Line, Harbour Line, Western',
                          prefixIcon: const Icon(Icons.linear_scale_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: notifier.setLineName,
                      ),
                      fieldSpacing,

                      TextFormField(
                        controller: _trainNumCtrl,
                        decoration: InputDecoration(
                          labelText: 'Train Number (optional)',
                          hintText: 'e.g. 90210',
                          prefixIcon: const Icon(Icons.pin_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          helperText: 'Leave blank for any train on this route',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        onChanged: notifier.setTrainNumber,
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
                        hint: 'Search by name or code',
                        leadingIcon: Icons.trip_origin,
                        selected: state.boardingStation,
                        searchFn: notifier.searchLocalTrainStations,
                        onChanged: notifier.setBoardingStation,
                        accentColor: _accent,
                        validator: (s) => s == null ? 'Select boarding station' : null,
                      ),

                      const SizedBox(height: 8),
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
                                Colors.orange.shade700,
                                Colors.deepOrange.shade800,
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      StationAutocompleteField(
                        label: 'Destination Station *',
                        hint: 'Search by name or code',
                        leadingIcon: Icons.place,
                        selected: state.destinationStation,
                        searchFn: notifier.searchLocalTrainStations,
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
                      fieldSpacing,

                      // Class dropdown (First Class / Second Class common for Mumbai locals)
                      DropdownButtonFormField<String>(
                        initialValue: state.travelClass,
                        decoration: InputDecoration(
                          labelText: 'Class (optional)',
                          prefixIcon: const Icon(Icons.airline_seat_recline_normal_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'FC', child: Text('First Class — FC')),
                          DropdownMenuItem(value: 'SC', child: Text('Second Class — SC')),
                          DropdownMenuItem(value: 'Ladies', child: Text('Ladies Coach')),
                          DropdownMenuItem(value: 'Divyang', child: Text('Divyang Coach')),
                        ],
                        onChanged: notifier.setTravelClass,
                        borderRadius: BorderRadius.circular(12),
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
