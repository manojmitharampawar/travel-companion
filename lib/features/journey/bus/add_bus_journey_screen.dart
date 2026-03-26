import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/core/services/geocoding_service.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/bus/bus_journey_notifier.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';

// ─────────────────────────────────────────────
// Which search field is active
// ─────────────────────────────────────────────

enum _Field { origin, destination }

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────

class AddBusJourneyScreen extends ConsumerStatefulWidget {
  const AddBusJourneyScreen({super.key});

  @override
  ConsumerState<AddBusJourneyScreen> createState() =>
      _AddBusJourneyScreenState();
}

class _AddBusJourneyScreenState extends ConsumerState<AddBusJourneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeCtrl = TextEditingController();
  final _operatorCtrl = TextEditingController();

  static const _type = TransportType.bus;
  static const _accent = Color(0xFF2E7D32);

  @override
  void dispose() {
    _routeCtrl.dispose();
    _operatorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(busJourneyNotifierProvider);
    final notifier = ref.read(busJourneyNotifierProvider.notifier);

    ref.listen<BusJourneyState>(busJourneyNotifierProvider, (prev, next) {
      if (next.savedSuccessfully) Navigator.pop(context, true);
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
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // ── Hero AppBar ─────────────────────
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
                    title: 'Add Bus Journey',
                    subtitle: 'Track your bus trip and get arrival alerts',
                  ),
                ),
              );
            }),

            SliverPadding(
              padding: const EdgeInsets.only(top: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Route planner (search + map) ─
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _RouteSection(
                      state: state,
                      notifier: notifier,
                      accentColor: _accent,
                    ),
                  ),

                  // ── Bus details ──────────────────
                  FormSectionCard(
                    title: 'BUS DETAILS',
                    icon: Icons.directions_bus,
                    accentColor: _accent,
                    children: [
                      TextFormField(
                        controller: _routeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Route Number (optional)',
                          hintText: 'e.g. 500LTD, AC47',
                          prefixIcon: const Icon(Icons.confirmation_number_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onChanged: notifier.setRouteNumber,
                      ),
                      fieldSpacing,
                      TextFormField(
                        controller: _operatorCtrl,
                        decoration: InputDecoration(
                          labelText: 'Operator / Service (optional)',
                          hintText: 'e.g. MSRTC, KSRTC, Volvo',
                          prefixIcon: const Icon(Icons.business_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: notifier.setOperatorName,
                      ),
                    ],
                  ),

                  // ── Journey info ─────────────────
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

                  // ── Save ────────────────────────
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
// Route Section — Google Maps-style planner + inline map
// ─────────────────────────────────────────────

class _RouteSection extends StatefulWidget {
  final BusJourneyState state;
  final BusJourneyNotifier notifier;
  final Color accentColor;

  const _RouteSection({
    required this.state,
    required this.notifier,
    required this.accentColor,
  });

  @override
  State<_RouteSection> createState() => _RouteSectionState();
}

class _RouteSectionState extends State<_RouteSection> {
  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _originFocus = FocusNode();
  final _destFocus = FocusNode();
  final _mapController = MapController();

  _Field _activeField = _Field.origin;
  List<LocationPoint> _results = [];
  bool _isSearching = false;
  bool _isPinMode = false;
  Timer? _debounce;

  // Google Maps accent colors
  static const _originColor = Color(0xFF1A73E8);
  static const _destColor = Color(0xFFD93025);

  @override
  void initState() {
    super.initState();
    _originFocus.addListener(_onFocusChange);
    _destFocus.addListener(_onFocusChange);
    _syncControllersFromState();
  }

  void _syncControllersFromState() {
    final s = widget.state;
    if (s.origin != null && _originCtrl.text != s.origin!.name) {
      _originCtrl.text = s.origin!.name;
    }
    if (s.destination != null && _destCtrl.text != s.destination!.name) {
      _destCtrl.text = s.destination!.name;
    }
  }

  @override
  void didUpdateWidget(_RouteSection old) {
    super.didUpdateWidget(old);
    _syncControllersFromState();
    // Animate map camera when locations change
    WidgetsBinding.instance.addPostFrameCallback((_) => _animateCamera());
  }

  void _animateCamera() {
    final s = widget.state;
    if (s.origin != null && s.destination != null) {
      final bounds = LatLngBounds(
        LatLng(s.origin!.latitude, s.origin!.longitude),
        LatLng(s.destination!.latitude, s.destination!.longitude),
      );
      _mapController.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(64),
      ));
    } else if (s.origin != null) {
      _mapController.move(
          LatLng(s.origin!.latitude, s.origin!.longitude), 14);
    } else if (s.destination != null) {
      _mapController.move(
          LatLng(s.destination!.latitude, s.destination!.longitude), 14);
    }
  }

  void _onFocusChange() {
    if (_originFocus.hasFocus) {
      setState(() {
        _activeField = _Field.origin;
        _isPinMode = false;
      });
    } else if (_destFocus.hasFocus) {
      setState(() {
        _activeField = _Field.destination;
        _isPinMode = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final res = await GeocodingService.search(query);
      if (mounted) {
        setState(() {
          _results = res;
          _isSearching = false;
        });
      }
    });
  }

  void _selectResult(LocationPoint p) {
    FocusScope.of(context).unfocus();
    if (_activeField == _Field.origin) {
      widget.notifier.setOrigin(p);
    } else {
      widget.notifier.setDestination(p);
    }
    setState(() {
      _results = [];
      _isSearching = false;
    });
    // Auto-advance to destination if origin just set
    if (_activeField == _Field.origin && widget.state.destination == null) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _activeField = _Field.destination);
          _destFocus.requestFocus();
        }
      });
    }
  }

  Future<void> _onMapTap(LatLng tapped) async {
    if (!_isPinMode) return;
    final point = await GeocodingService.reverseGeocode(
        tapped.latitude, tapped.longitude);
    if (!mounted) return;
    if (_activeField == _Field.origin) {
      widget.notifier.setOrigin(point);
    } else {
      widget.notifier.setDestination(point);
    }
    setState(() => _results = []);
  }

  Future<void> _detectLocation() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSearching = true);
    await widget.notifier.detectCurrentLocation();
    if (mounted) setState(() => _isSearching = false);
  }

  void _swapLocations() {
    final s = widget.state;
    final tmp = s.origin;
    widget.notifier.setOrigin(s.destination);
    widget.notifier.setDestination(tmp);
  }

  void _clearField(_Field f) {
    if (f == _Field.origin) {
      _originCtrl.clear();
      widget.notifier.setOrigin(null);
    } else {
      _destCtrl.clear();
      widget.notifier.setDestination(null);
    }
    setState(() => _results = []);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _originCtrl.dispose();
    _destCtrl.dispose();
    _originFocus.dispose();
    _destFocus.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.accentColor;
    final s = widget.state;
    final hasOrigin = s.origin != null;
    final hasDest = s.destination != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.alt_route, size: 16, color: accent),
            ),
            const SizedBox(width: 10),
            Text(
              'JOURNEY ROUTE',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.3,
                  ),
            ),
          ]),
        ),

        // ── Google Maps-style planner card ────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Origin row
              _FieldRow(
                controller: _originCtrl,
                focusNode: _originFocus,
                isActive: _activeField == _Field.origin,
                isSet: hasOrigin,
                isDest: false,
                placeholder: 'Boarding stop or area',
                dotColor: hasOrigin ? _originColor : Colors.grey.shade400,
                onChanged: (v) {
                  setState(() => _activeField = _Field.origin);
                  _onSearchChanged(v);
                },
                onClear: () => _clearField(_Field.origin),
                onGps: (!hasOrigin || _activeField == _Field.origin)
                    ? _detectLocation
                    : null,
                isDetecting:
                    s.isDetectingLocation && _activeField == _Field.origin,
              ),

              // Connector + swap
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Three dots
                    SizedBox(
                      width: 14,
                      child: Column(
                        children: List.generate(
                          3,
                          (i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1.5),
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Swap button
                    if (hasOrigin || hasDest)
                      _MapFab(
                        icon: Icon(Icons.swap_vert_rounded,
                            size: 18, color: accent),
                        tooltip: 'Swap',
                        onTap: _swapLocations,
                        accentColor: accent,
                      ),
                  ],
                ),
              ),

              // Destination row
              _FieldRow(
                controller: _destCtrl,
                focusNode: _destFocus,
                isActive: _activeField == _Field.destination,
                isSet: hasDest,
                isDest: true,
                placeholder: 'Destination stop or area',
                dotColor: hasDest ? _destColor : Colors.grey.shade400,
                onChanged: (v) {
                  setState(() => _activeField = _Field.destination);
                  _onSearchChanged(v);
                },
                onClear: () => _clearField(_Field.destination),
              ),
            ],
          ),
        ),

        // ── Search results ────────────────────
        if (_results.isNotEmpty || _isSearching)
          _SearchResultsCard(
            results: _results,
            isSearching: _isSearching,
            isDest: _activeField == _Field.destination,
            onSelect: _selectResult,
          ),

        const SizedBox(height: 12),

        // ── Inline map ────────────────────────
        _InlineRouteMap(
          origin: s.origin,
          destination: s.destination,
          accentColor: accent,
          mapController: _mapController,
          isPinMode: _isPinMode,
          activeField: _activeField,
          isDetecting: s.isDetectingLocation,
          onMapTap: _onMapTap,
          onTogglePinMode: () {
            FocusScope.of(context).unfocus();
            setState(() {
              _isPinMode = !_isPinMode;
              _results = [];
            });
          },
          onMyLocation: () {
            setState(() => _activeField = _Field.origin);
            _detectLocation();
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Location input row (Google Maps look)
// ─────────────────────────────────────────────

class _FieldRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;
  final bool isSet;
  final bool isDest;
  final String placeholder;
  final Color dotColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback? onGps;
  final bool isDetecting;

  const _FieldRow({
    required this.controller,
    required this.focusNode,
    required this.isActive,
    required this.isSet,
    required this.isDest,
    required this.placeholder,
    required this.dotColor,
    required this.onChanged,
    required this.onClear,
    this.onGps,
    this.isDetecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, isDest ? 4 : 14, 12, isDest ? 14 : 4),
      child: Row(
        children: [
          // Leading indicator
          SizedBox(
            width: 26,
            child: Center(
              child: isDest
                  ? Icon(Icons.location_on_rounded,
                      size: 22,
                      color: isSet
                          ? const Color(0xFFD93025)
                          : Colors.grey.shade400)
                  : Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: isSet
                            ? [
                                BoxShadow(
                                  color: dotColor.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          // Text field
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSet ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSet ? const Color(0xFF202124) : const Color(0xFF5F6368),
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9AA0A6),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // Trailing actions
          if (isDetecting)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (isSet)
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.close_rounded,
                  size: 18, color: Colors.grey.shade400),
            )
          else if (onGps != null)
            GestureDetector(
              onTap: onGps,
              child: const Icon(Icons.my_location_rounded,
                  size: 18, color: Color(0xFF1A73E8)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Search results card
// ─────────────────────────────────────────────

class _SearchResultsCard extends StatelessWidget {
  final List<LocationPoint> results;
  final bool isSearching;
  final bool isDest;
  final ValueChanged<LocationPoint> onSelect;

  const _SearchResultsCard({
    required this.results,
    required this.isSearching,
    required this.isDest,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final markerColor =
        isDest ? const Color(0xFFD93025) : const Color(0xFF1A73E8);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: isSearching && results.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Searching...',
                      style: TextStyle(
                          color: Color(0xFF5F6368), fontSize: 13)),
                ],
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: results.length,
              separatorBuilder: (context, _) =>
                  const Divider(height: 1, indent: 56, endIndent: 16),
              itemBuilder: (_, i) {
                final p = results[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: markerColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.location_on_rounded,
                        size: 18, color: markerColor),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF202124),
                    ),
                  ),
                  subtitle: p.address != null
                      ? Text(
                          p.address!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF5F6368)),
                        )
                      : null,
                  trailing: const Icon(Icons.north_west_rounded,
                      size: 16, color: Color(0xFF9AA0A6)),
                  onTap: () => onSelect(p),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────
// Inline Route Map (CartoDB Voyager tiles)
// ─────────────────────────────────────────────

class _InlineRouteMap extends StatelessWidget {
  final LocationPoint? origin;
  final LocationPoint? destination;
  final Color accentColor;
  final MapController mapController;
  final bool isPinMode;
  final _Field activeField;
  final bool isDetecting;
  final Future<void> Function(LatLng) onMapTap;
  final VoidCallback onTogglePinMode;
  final VoidCallback onMyLocation;

  static const _defaultCenter = LatLng(20.5937, 78.9629);

  const _InlineRouteMap({
    required this.origin,
    required this.destination,
    required this.accentColor,
    required this.mapController,
    required this.isPinMode,
    required this.activeField,
    required this.isDetecting,
    required this.onMapTap,
    required this.onTogglePinMode,
    required this.onMyLocation,
  });

  LatLng get _center {
    if (origin != null && destination != null) {
      return LatLng(
        (origin!.latitude + destination!.latitude) / 2,
        (origin!.longitude + destination!.longitude) / 2,
      );
    }
    if (origin != null) return LatLng(origin!.latitude, origin!.longitude);
    if (destination != null) {
      return LatLng(destination!.latitude, destination!.longitude);
    }
    return _defaultCenter;
  }

  double get _zoom =>
      (origin == null && destination == null) ? 4.5 : 12.0;

  @override
  Widget build(BuildContext context) {
    final isDest = activeField == _Field.destination;
    final hasRoute = origin != null && destination != null;

    return Container(
      height: 310,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── Map ─────────────────────────────
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              onTap: (_, point) => onMapTap(point),
            ),
            children: [
              // CartoDB Voyager — Google Maps-like free tiles
              TileLayer(
                urlTemplate:
                    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                userAgentPackageName: 'com.travel_companion.app',
                tileProvider: NetworkTileProvider(),
                fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                maxZoom: 19,
              ),

              // Dashed route polyline (Google Maps style)
              if (hasRoute)
                PolylineLayer(polylines: [
                  Polyline(
                    points: [
                      LatLng(origin!.latitude, origin!.longitude),
                      LatLng(destination!.latitude, destination!.longitude),
                    ],
                    strokeWidth: 4.5,
                    color: const Color(0xFF1A73E8),
                    pattern:
                        StrokePattern.dashed(segments: [14, 7]),
                  ),
                ]),

              // Markers
              MarkerLayer(markers: [
                if (origin != null)
                  Marker(
                    point: LatLng(origin!.latitude, origin!.longitude),
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: _OriginPin(),
                  ),
                if (destination != null)
                  Marker(
                    point: LatLng(
                        destination!.latitude, destination!.longitude),
                    width: 44,
                    height: 52,
                    alignment: Alignment.bottomCenter,
                    child: const _DestinationPin(),
                  ),
              ]),

              // Required attribution
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                  TextSourceAttribution('© CARTO'),
                ],
              ),
            ],
          ),

          // ── Pin crosshair ────────────────────
          if (isPinMode) const Center(child: _Crosshair()),

          // ── Top instruction pill ─────────────
          if (isPinMode)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDest
                            ? Icons.location_on_rounded
                            : Icons.trip_origin_rounded,
                        size: 15,
                        color: isDest
                            ? const Color(0xFFD93025)
                            : const Color(0xFF1A73E8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDest
                            ? 'Tap to pin destination'
                            : 'Tap to pin boarding stop',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF202124),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Right controls ───────────────────
          Positioned(
            bottom: 36,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapFab(
                  icon: isDetecting
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.my_location_rounded,
                          size: 19, color: Color(0xFF1A73E8)),
                  tooltip: 'My Location',
                  onTap: onMyLocation,
                ),
                const SizedBox(height: 8),
                _MapFab(
                  icon: Icon(
                    isPinMode
                        ? Icons.edit_location_alt_rounded
                        : Icons.add_location_alt_outlined,
                    size: 19,
                    color: isPinMode ? accentColor : const Color(0xFF5F6368),
                  ),
                  tooltip: isPinMode ? 'Exit pin mode' : 'Pin a location',
                  active: isPinMode,
                  accentColor: accentColor,
                  onTap: onTogglePinMode,
                ),
              ],
            ),
          ),

          // ── Route distance chip ──────────────
          if (hasRoute)
            Positioned(
              bottom: 36,
              left: 12,
              child: _DistanceChip(
                  origin: origin!, destination: destination!),
            ),

          // ── Bottom gradient (readability) ────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x28000000), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Origin marker (Google blue dot)
// ─────────────────────────────────────────────

class _OriginPin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFF1A73E8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x551A73E8),
              blurRadius: 8,
              spreadRadius: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Destination marker (teardrop pin with bus icon)
// ─────────────────────────────────────────────

class _DestinationPin extends StatelessWidget {
  const _DestinationPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFD93025),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55D93025),
                blurRadius: 8,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(Icons.directions_bus_rounded,
              size: 18, color: Colors.white),
        ),
        CustomPaint(
          size: const Size(12, 8),
          painter: _TrianglePainter(color: const Color(0xFFD93025)),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      ui.Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter o) => o.color != color;
}

// ─────────────────────────────────────────────
// Crosshair for pin mode
// ─────────────────────────────────────────────

class _Crosshair extends StatelessWidget {
  const _Crosshair();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
              color: Color(0xFF1A73E8), shape: BoxShape.circle),
        ),
        Container(
            width: 44, height: 1.5,
            color: Colors.white.withValues(alpha: 0.55)),
        Container(
            width: 1.5, height: 44,
            color: Colors.white.withValues(alpha: 0.55)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Map floating action button
// ─────────────────────────────────────────────

class _MapFab extends StatelessWidget {
  final Widget icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;
  final Color? accentColor;

  const _MapFab({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: active && accentColor != null
                ? accentColor!.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active && accentColor != null
                  ? accentColor!.withValues(alpha: 0.4)
                  : Colors.grey.shade200,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Straight-line distance chip
// ─────────────────────────────────────────────

class _DistanceChip extends StatelessWidget {
  final LocationPoint origin;
  final LocationPoint destination;

  const _DistanceChip({required this.origin, required this.destination});

  @override
  Widget build(BuildContext context) {
    const calc = Distance();
    final km = calc.as(
      LengthUnit.Kilometer,
      LatLng(origin.latitude, origin.longitude),
      LatLng(destination.latitude, destination.longitude),
    );
    final label =
        km < 1 ? '${(km * 1000).toStringAsFixed(0)} m' : '~${km.toStringAsFixed(1)} km';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.straighten_rounded,
              size: 13, color: Color(0xFF1A73E8)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202124),
            ),
          ),
        ],
      ),
    );
  }
}
