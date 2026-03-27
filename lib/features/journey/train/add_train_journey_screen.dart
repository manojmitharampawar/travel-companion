import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/train/train_journey_notifier.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';
import 'package:travel_companion/features/journey/widgets/train_stop_selector.dart';

class AddTrainJourneyScreen extends ConsumerStatefulWidget {
  const AddTrainJourneyScreen({super.key});

  @override
  ConsumerState<AddTrainJourneyScreen> createState() => _AddTrainJourneyScreenState();
}

class _AddTrainJourneyScreenState extends ConsumerState<AddTrainJourneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pnrCtrl = TextEditingController();
  final _trainNumCtrl = TextEditingController();
  final _trainNameCtrl = TextEditingController();
  final _berthCtrl = TextEditingController();

  static const _type = TransportType.train;
  static const _accent = Color(0xFF1565C0); // Railway blue

  @override
  void dispose() {
    _pnrCtrl.dispose();
    _trainNumCtrl.dispose();
    _trainNameCtrl.dispose();
    _berthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainJourneyNotifierProvider);
    final notifier = ref.read(trainJourneyNotifierProvider.notifier);
    final hasRouteStops = state.trainRouteStops.isNotEmpty;

    // Sync auto-filled values back to text controllers
    ref.listen<TrainJourneyState>(trainJourneyNotifierProvider, (prev, next) {
      if (prev?.trainName != next.trainName && next.trainName.isNotEmpty) {
        _trainNameCtrl.text = next.trainName;
      }
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
                    title: 'Add Train Journey',
                    subtitle: 'Enter your train details and book smart alerts',
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
                    icon: Icons.train,
                    accentColor: _accent,
                    children: [
                      // PNR
                      TextFormField(
                        controller: _pnrCtrl,
                        decoration: InputDecoration(
                          labelText: 'PNR Number (optional)',
                          hintText: '10-digit PNR',
                          prefixIcon: const Icon(Icons.confirmation_number_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          helperText: 'Auto-detected from SMS if available',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        onChanged: notifier.setPnr,
                      ),
                      fieldSpacing,

                      // Train Number
                      TextFormField(
                        controller: _trainNumCtrl,
                        decoration: InputDecoration(
                          labelText: 'Train Number *',
                          hintText: 'e.g. 12301',
                          prefixIcon: const Icon(Icons.pin_outlined),
                          suffixIcon: state.isAutoFilling
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                          helperText: 'Name and route auto-fill from number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        onChanged: notifier.setTrainNumber,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Train number is required';
                          if (v.length < 4) return 'Enter a valid 4-5 digit number';
                          return null;
                        },
                      ),
                      fieldSpacing,

                      // Train Name
                      TextFormField(
                        controller: _trainNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Train Name (optional)',
                          hintText: 'e.g. Rajdhani Express',
                          prefixIcon: const Icon(Icons.label_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: notifier.setTrainName,
                      ),

                      // Route stops badge when loaded
                      if (hasRouteStops) ...[
                        const SizedBox(height: 10),
                        _RouteLoadedBanner(
                          stopCount: state.trainRouteStops.length,
                          trainName: state.trainName,
                          accentColor: _accent,
                        ),
                      ],
                    ],
                  ),

                  // ── SECTION: Route ─────────────────
                  FormSectionCard(
                    title: 'JOURNEY ROUTE',
                    icon: Icons.alt_route,
                    accentColor: _accent,
                    children: [
                      // Boarding Station
                      if (hasRouteStops)
                        TrainStopSelector(
                          label: 'Boarding Station *',
                          leadingIcon: Icons.trip_origin,
                          stops: state.trainRouteStops,
                          selected: _findStop(state.trainRouteStops,
                              state.boardingStation?.code),
                          onChanged: notifier.selectBoardingStop,
                          accentColor: _accent,
                          validator: (_) => state.boardingStation == null
                              ? 'Select boarding station'
                              : null,
                        )
                      else
                        StationAutocompleteField(
                          label: 'Boarding Station *',
                          hint: 'Search by name or code',
                          leadingIcon: Icons.trip_origin,
                          selected: state.boardingStation,
                          searchFn: notifier.searchStations,
                          onChanged: notifier.setBoardingStation,
                          accentColor: _accent,
                          validator: (s) =>
                              s == null ? 'Select boarding station' : null,
                        ),

                      const SizedBox(height: 8),
                      // Route line connector
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
                                    Colors.green.shade600,
                                    Colors.red.shade600,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Destination Station
                      if (hasRouteStops)
                        TrainStopSelector(
                          label: 'Destination Station *',
                          leadingIcon: Icons.place,
                          stops: state.destinationStops,
                          selected: _findStop(state.trainRouteStops,
                              state.destinationStation?.code),
                          onChanged: notifier.selectDestinationStop,
                          accentColor: _accent,
                          disabledHint: 'Select boarding station first',
                          validator: (_) => state.destinationStation == null
                              ? 'Select destination station'
                              : null,
                        )
                      else
                        StationAutocompleteField(
                          label: 'Destination Station *',
                          hint: 'Search by name or code',
                          leadingIcon: Icons.place,
                          selected: state.destinationStation,
                          searchFn: notifier.searchStations,
                          onChanged: notifier.setDestinationStation,
                          accentColor: _accent,
                          validator: (s) =>
                              s == null ? 'Select destination station' : null,
                        ),
                    ],
                  ),

                  // ── SECTION: Route Preview ─────────
                  if (state.boardingStation != null &&
                      state.destinationStation != null &&
                      state.boardingStation!.latitude != 0 &&
                      state.destinationStation!.latitude != 0)
                    _TrainRoutePreview(
                      stops: state.trainRouteStops,
                      boardingCode: state.boardingStation!.code,
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

                      // Class dropdown
                      DropdownButtonFormField<String>(
                        initialValue: state.travelClass,
                        decoration: InputDecoration(
                          labelText: 'Travel Class (optional)',
                          prefixIcon: const Icon(Icons.airline_seat_recline_normal_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'SL', child: Text('Sleeper — SL')),
                          DropdownMenuItem(value: '3A', child: Text('AC 3 Tier — 3A')),
                          DropdownMenuItem(value: '2A', child: Text('AC 2 Tier — 2A')),
                          DropdownMenuItem(value: '1A', child: Text('First AC — 1A')),
                          DropdownMenuItem(value: '3E', child: Text('AC Economy — 3E')),
                          DropdownMenuItem(value: 'CC', child: Text('Chair Car — CC')),
                          DropdownMenuItem(value: 'EC', child: Text('Exec Chair — EC')),
                          DropdownMenuItem(value: '2S', child: Text('Second Sitting — 2S')),
                        ],
                        onChanged: notifier.setTravelClass,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      fieldSpacing,

                      TextFormField(
                        controller: _berthCtrl,
                        decoration: InputDecoration(
                          labelText: 'Berth / Seat (optional)',
                          hintText: 'e.g. S5/32/SU',
                          prefixIcon: const Icon(Icons.event_seat_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: notifier.setBerth,
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

  TrainRouteStop? _findStop(List<TrainRouteStop> stops, String? code) {
    if (code == null) return null;
    try {
      return stops.firstWhere((s) => s.stationCode == code);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────
// Route Loaded Banner
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// Train Route Map Preview
// ─────────────────────────────────────────────

class _TrainRoutePreview extends StatelessWidget {
  final List<TrainRouteStop> stops;
  final String boardingCode;
  final String destinationCode;
  final Color accentColor;

  const _TrainRoutePreview({
    required this.stops,
    required this.boardingCode,
    required this.destinationCode,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    // Build route points from stops between boarding and destination
    final routeStops = _getRouteStops();
    if (routeStops.isEmpty) return const SizedBox.shrink();

    final points = routeStops
        .where((s) => s.latitude != 0 && s.longitude != 0)
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();

    if (points.length < 2) return const SizedBox.shrink();

    // Calculate center and zoom
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLon = points.first.longitude, maxLon = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    final center = LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);
    final maxDiff = (maxLat - minLat) > (maxLon - minLon)
        ? (maxLat - minLat)
        : (maxLon - minLon);
    final zoom = (12.0 - (maxDiff * 10).clamp(0, 8)).clamp(4.0, 14.0);

    return FormSectionCard(
      title: 'ROUTE PREVIEW',
      icon: Icons.map_outlined,
      accentColor: accentColor,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                  userAgentPackageName: 'com.travel_companion.app',
                  fallbackUrl:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                // Route polyline connecting all stations
                PolylineLayer(polylines: [
                  Polyline(
                    points: points,
                    strokeWidth: 4,
                    color: accentColor,
                  ),
                ]),
                // Station markers
                MarkerLayer(markers: [
                  for (int i = 0; i < routeStops.length; i++)
                    if (routeStops[i].latitude != 0)
                      Marker(
                        point: LatLng(
                            routeStops[i].latitude, routeStops[i].longitude),
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        child: _StationDot(
                          isEndpoint: routeStops[i].stationCode == boardingCode ||
                              routeStops[i].stationCode == destinationCode,
                          isOrigin: routeStops[i].stationCode == boardingCode,
                          accentColor: accentColor,
                        ),
                      ),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Route summary strip
        Row(
          children: [
            Icon(Icons.trip_origin, size: 14, color: Colors.green.shade600),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                routeStops.first.stationName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${routeStops.length} stops',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                routeStops.last.stationName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.location_on, size: 14, color: Colors.red.shade600),
          ],
        ),
      ],
    );
  }

  List<TrainRouteStop> _getRouteStops() {
    if (stops.isEmpty) return [];
    final boardingIdx =
        stops.indexWhere((s) => s.stationCode == boardingCode);
    final destIdx =
        stops.indexWhere((s) => s.stationCode == destinationCode);
    if (boardingIdx < 0 || destIdx < 0 || boardingIdx >= destIdx) return [];
    return stops.sublist(boardingIdx, destIdx + 1);
  }
}

class _StationDot extends StatelessWidget {
  final bool isEndpoint;
  final bool isOrigin;
  final Color accentColor;

  const _StationDot({
    required this.isEndpoint,
    required this.isOrigin,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isEndpoint) {
      final color = isOrigin ? Colors.green.shade600 : Colors.red.shade600;
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
          ],
        ),
        child: Icon(
          isOrigin ? Icons.trip_origin : Icons.location_on,
          size: 10,
          color: Colors.white,
        ),
      );
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: accentColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Route Loaded Banner
// ─────────────────────────────────────────────

class _RouteLoadedBanner extends StatelessWidget {
  final int stopCount;
  final String trainName;
  final Color accentColor;

  const _RouteLoadedBanner({
    required this.stopCount,
    required this.trainName,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$stopCount stops loaded${trainName.isNotEmpty ? ' · $trainName' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
