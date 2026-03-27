import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasBothStations =
        state.boardingStation != null && state.destinationStation != null;

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
                          hintText:
                              'e.g. Central Line, Harbour Line, Western',
                          prefixIcon:
                              const Icon(Icons.linear_scale_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
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
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          helperText:
                              'Leave blank for any train on this route',
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
                        validator: (s) =>
                            s == null ? 'Select boarding station' : null,
                      ),

                      const SizedBox(height: 8),
                      // Route connector line
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Row(
                          children: [
                            Container(
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
                          ],
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
                        validator: (s) =>
                            s == null ? 'Select destination station' : null,
                      ),
                    ],
                  ),

                  // ── SECTION: Map Preview ───────────
                  if (hasBothStations)
                    _LocalTrainMapPreview(
                      boardingLat: state.boardingStation!.latitude,
                      boardingLng: state.boardingStation!.longitude,
                      boardingName: state.boardingStation!.name,
                      boardingCode: state.boardingStation!.code,
                      destinationLat: state.destinationStation!.latitude,
                      destinationLng: state.destinationStation!.longitude,
                      destinationName: state.destinationStation!.name,
                      destinationCode: state.destinationStation!.code,
                      accentColor: _accent,
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

                      // Class dropdown
                      DropdownButtonFormField<String>(
                        initialValue: (state.travelClass == null || state.travelClass!.isEmpty)
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

// ─────────────────────────────────────────────
// Inline Map Preview
// ─────────────────────────────────────────────

class _LocalTrainMapPreview extends StatelessWidget {
  final double boardingLat;
  final double boardingLng;
  final String boardingName;
  final String boardingCode;
  final double destinationLat;
  final double destinationLng;
  final String destinationName;
  final String destinationCode;
  final Color accentColor;

  const _LocalTrainMapPreview({
    required this.boardingLat,
    required this.boardingLng,
    required this.boardingName,
    required this.boardingCode,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationName,
    required this.destinationCode,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final origin = LatLng(boardingLat, boardingLng);
    final destination = LatLng(destinationLat, destinationLng);

    // Compute bounds with padding
    final midLat = (boardingLat + destinationLat) / 2;
    final midLng = (boardingLng + destinationLng) / 2;
    final center = LatLng(midLat, midLng);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header inside the card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.map_outlined, size: 16, color: accentColor),
                ),
                const SizedBox(width: 10),
                Text(
                  'ROUTE PREVIEW',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: 0.3,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Map
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: _estimateZoom(origin, destination),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.travel.companion',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [origin, destination],
                          strokeWidth: 3.5,
                          color: accentColor,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: origin,
                          width: 36,
                          height: 36,
                          child: _StationMarker(
                            color: Colors.green.shade600,
                            icon: Icons.trip_origin,
                          ),
                        ),
                        Marker(
                          point: destination,
                          width: 36,
                          height: 36,
                          child: _StationMarker(
                            color: Colors.red.shade600,
                            icon: Icons.place,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Station labels below the map
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                _StationLabel(
                  icon: Icons.trip_origin,
                  iconColor: Colors.green.shade600,
                  name: boardingName,
                  code: boardingCode,
                ),
                const Spacer(),
                Icon(Icons.arrow_forward,
                    size: 16, color: scheme.onSurfaceVariant),
                const Spacer(),
                _StationLabel(
                  icon: Icons.place,
                  iconColor: Colors.red.shade600,
                  name: destinationName,
                  code: destinationCode,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Rough zoom estimate based on distance between two points.
  double _estimateZoom(LatLng a, LatLng b) {
    const distance = Distance();
    final km = distance.as(LengthUnit.Kilometer, a, b);
    if (km < 2) return 14.5;
    if (km < 5) return 13.0;
    if (km < 10) return 12.0;
    if (km < 25) return 11.0;
    if (km < 50) return 10.0;
    if (km < 100) return 9.0;
    return 8.0;
  }
}

class _StationMarker extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _StationMarker({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}

class _StationLabel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String code;
  final CrossAxisAlignment crossAxisAlignment;

  const _StationLabel({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.code,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Flexible(
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            code,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
