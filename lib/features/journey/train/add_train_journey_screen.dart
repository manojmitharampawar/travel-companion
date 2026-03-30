import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/train/train_journey_notifier.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/features/journey/widgets/train_stop_selector.dart';

const _kAccent = Color(0xFF1565C0);

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
  static const _accent = _kAccent;

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

    final g = GlassColors.of(context);

    return Scaffold(
      backgroundColor: g.bg,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Glass background orbs
          _TrainBackground(),

          Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                // Glass App Bar
                Builder(builder: (ctx) {
                  final topPad = MediaQuery.paddingOf(ctx).top;
                  return SliverAppBar(
                    pinned: true,
                    expandedHeight: topPad + kToolbarHeight + 80,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    scrolledUnderElevation: 0,
                    foregroundColor: Colors.white,
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

                SliverPadding(
                  padding: const EdgeInsets.only(top: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Train Details
                      FormSectionCard(
                        title: 'TRAIN DETAILS',
                        icon: Icons.train,
                        accentColor: _accent,
                        children: [
                          TextFormField(
                            controller: _pnrCtrl,
                            style: TextStyle(color: g.textAlpha(0.9)),
                            decoration: glassInputDecoration(
                              labelText: 'PNR Number (optional)',
                              hintText: '10-digit PNR',
                              prefixIcon: Icons.confirmation_number_outlined,
                              helperText: 'Auto-detected from SMS if available',
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            onChanged: notifier.setPnr,
                          ),
                          fieldSpacing,

                          TextFormField(
                            controller: _trainNumCtrl,
                            style: TextStyle(color: g.textAlpha(0.9)),
                            decoration: glassInputDecoration(
                              labelText: 'Train Number *',
                              hintText: 'e.g. 12301',
                              prefixIcon: Icons.pin_outlined,
                              helperText: 'Name and route auto-fill from number',
                              suffixIcon: state.isAutoFilling
                                  ? Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    )
                                  : null,
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

                          TextFormField(
                            controller: _trainNameCtrl,
                            style: TextStyle(color: g.textAlpha(0.9)),
                            decoration: glassInputDecoration(
                              labelText: 'Train Name (optional)',
                              hintText: 'e.g. Rajdhani Express',
                              prefixIcon: Icons.label_outline,
                            ),
                            onChanged: notifier.setTrainName,
                          ),

                          if (hasRouteStops) ...[
                            const SizedBox(height: 10),
                            _GlassRouteLoadedBanner(
                              stopCount: state.trainRouteStops.length,
                              trainName: state.trainName,
                              accentColor: _accent,
                            ),
                          ],
                        ],
                      ),

                      // Journey Route
                      FormSectionCard(
                        title: 'JOURNEY ROUTE',
                        icon: Icons.alt_route,
                        accentColor: _accent,
                        children: [
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
                          // Route connector
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
                                        const Color(0xFF27AE60),
                                        const Color(0xFFE74C3C),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

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

                      // Route Preview
                      if (state.boardingStation != null &&
                          state.destinationStation != null &&
                          state.boardingStation!.latitude != 0 &&
                          state.destinationStation!.latitude != 0)
                        _GlassTrainRoutePreview(
                          stops: state.trainRouteStops,
                          boardingCode: state.boardingStation!.code,
                          destinationCode: state.destinationStation!.code,
                          accentColor: _accent,
                        ),

                      // Journey Info
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

                          DropdownButtonFormField<String>(
                            initialValue: state.travelClass,
                            decoration: glassInputDecoration(
                              labelText: 'Travel Class (optional)',
                              prefixIcon: Icons.airline_seat_recline_normal_outlined,
                            ),
                            dropdownColor: g.dropdownBg,
                            style: TextStyle(
                              color: g.textAlpha(0.9),
                              fontSize: 14,
                            ),
                            iconEnabledColor: g.textAlpha(0.5),
                            borderRadius: BorderRadius.circular(14),
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
                          ),
                          fieldSpacing,

                          TextFormField(
                            controller: _berthCtrl,
                            style: TextStyle(color: g.textAlpha(0.9)),
                            decoration: glassInputDecoration(
                              labelText: 'Berth / Seat (optional)',
                              hintText: 'e.g. S5/32/SU',
                              prefixIcon: Icons.event_seat_outlined,
                            ),
                            onChanged: notifier.setBerth,
                          ),
                        ],
                      ),

                      // Save
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
        ],
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
// Background
// ─────────────────────────────────────────────

class _TrainBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: GlassColors.of(context).bg,
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: _GlowOrb(color: _kAccent, size: 220),
          ),
          Positioned(
            bottom: 150,
            left: -60,
            child: _GlowOrb(color: GlassConstants.meshPurple, size: 180),
          ),
          Positioned(
            top: 400,
            right: -30,
            child: _GlowOrb(color: GlassConstants.meshCyan, size: 140),
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
// Glass Route Loaded Banner
// ─────────────────────────────────────────────

class _GlassRouteLoadedBanner extends StatelessWidget {
  final int stopCount;
  final String trainName;
  final Color accentColor;

  const _GlassRouteLoadedBanner({
    required this.stopCount,
    required this.trainName,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
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

// ─────────────────────────────────────────────
// Glass Route Map Preview
// ─────────────────────────────────────────────

class _GlassTrainRoutePreview extends StatelessWidget {
  final List<TrainRouteStop> stops;
  final String boardingCode;
  final String destinationCode;
  final Color accentColor;

  const _GlassTrainRoutePreview({
    required this.stops,
    required this.boardingCode,
    required this.destinationCode,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final routeStops = _getRouteStops();
    if (routeStops.isEmpty) return const SizedBox.shrink();

    final points = routeStops
        .where((s) => s.latitude != 0 && s.longitude != 0)
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();

    if (points.length < 2) return const SizedBox.shrink();

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
                      'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
                  userAgentPackageName: 'com.travel_companion.app',
                  fallbackUrl:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                PolylineLayer(polylines: [
                  Polyline(
                    points: points,
                    strokeWidth: 4,
                    color: accentColor,
                  ),
                ]),
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
                    color: const Color(0xFF27AE60).withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                routeStops.first.stationName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: g.textAlpha(0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${routeStops.length} stops',
              style: TextStyle(
                fontSize: 11,
                color: g.textAlpha(0.4),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                routeStops.last.stationName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: g.textAlpha(0.8),
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
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
                    color: const Color(0xFFE74C3C).withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
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
      final color = isOrigin ? const Color(0xFF27AE60) : const Color(0xFFE74C3C);
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
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
