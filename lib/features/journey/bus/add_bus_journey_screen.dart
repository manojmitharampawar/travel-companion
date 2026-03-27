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
    final theme = Theme.of(context);

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
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // ── Hero AppBar ─────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: kToolbarHeight + 80,
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
            ),

            SliverPadding(
              padding: const EdgeInsets.only(top: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Route section ─────────────────
                  FormSectionCard(
                    title: 'JOURNEY ROUTE',
                    icon: Icons.alt_route,
                    accentColor: _accent,
                    children: [
                      _LocationSearchField(
                        label: 'Origin',
                        hint: 'Boarding stop or area',
                        leadingIcon: Icons.trip_origin,
                        value: state.origin,
                        accentColor: _accent,
                        markerColor: const Color(0xFF1A73E8),
                        isDetecting: state.isDetectingLocation,
                        onSelected: notifier.setOrigin,
                        onDetectGps: notifier.detectCurrentLocation,
                        searchFn: (q) => GeocodingService.search(q),
                      ),
                      fieldSpacing,
                      _LocationSearchField(
                        label: 'Destination',
                        hint: 'Destination stop or area',
                        leadingIcon: Icons.location_on,
                        value: state.destination,
                        accentColor: _accent,
                        markerColor: const Color(0xFFD93025),
                        onSelected: notifier.setDestination,
                        searchFn: (q) => GeocodingService.search(q),
                      ),
                    ],
                  ),

                  // ── Inline bus map preview ────────
                  if (state.origin != null || state.destination != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: _BusRouteMapPreview(
                        origin: state.origin,
                        destination: state.destination,
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
                          prefixIcon:
                              const Icon(Icons.confirmation_number_outlined),
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
// Location search field with OverlayEntry dropdown
// ─────────────────────────────────────────────
//
// This is the key fix for the destination selection bug.
// Search results are rendered in an OverlayEntry positioned
// relative to the text field, so they float above all other
// widgets and never get clipped by parent containers.
// ─────────────────────────────────────────────

class _LocationSearchField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData leadingIcon;
  final LocationPoint? value;
  final Color accentColor;
  final Color markerColor;
  final bool isDetecting;
  final ValueChanged<LocationPoint?> onSelected;
  final VoidCallback? onDetectGps;
  final Future<List<LocationPoint>> Function(String query) searchFn;

  const _LocationSearchField({
    required this.label,
    required this.hint,
    required this.leadingIcon,
    required this.value,
    required this.accentColor,
    required this.markerColor,
    required this.onSelected,
    required this.searchFn,
    this.onDetectGps,
    this.isDetecting = false,
  });

  @override
  State<_LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<_LocationSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<LocationPoint> _results = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _controller.text = widget.value!.name;
    }
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(_LocationSearchField old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) {
      _controller.text = widget.value?.name ?? '';
      if (widget.value != null) {
        _removeOverlay();
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Delay removal so that tap events on overlay items register first.
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      _removeOverlay();
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final res = await widget.searchFn(query);
        if (mounted) {
          setState(() {
            _results = res;
            _isSearching = false;
          });
          if (res.isNotEmpty) {
            _showOverlay();
          } else {
            _removeOverlay();
          }
        }
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _selectResult(LocationPoint point) {
    _controller.text = point.name;
    _focusNode.unfocus();
    _removeOverlay();
    setState(() {
      _results = [];
      _isSearching = false;
    });
    widget.onSelected(point);
  }

  void _clear() {
    _controller.clear();
    _removeOverlay();
    setState(() {
      _results = [];
      _isSearching = false;
    });
    widget.onSelected(null);
  }

  void _showOverlay() {
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final fieldWidth = renderBox.size.width;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: fieldWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            shadowColor: Colors.black.withValues(alpha: 0.15),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: _isSearching && _results.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
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
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, indent: 56, endIndent: 16),
                      itemBuilder: (_, i) {
                        final p = _results[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 2),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  widget.markerColor.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.location_on_rounded,
                                size: 18, color: widget.markerColor),
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5F6368)),
                                )
                              : null,
                          trailing: const Icon(Icons.north_west_rounded,
                              size: 14, color: Color(0xFF9AA0A6)),
                          onTap: () => _selectResult(p),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final isSet = widget.value != null;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: Icon(widget.leadingIcon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: widget.isDetecting
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : isSet
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _clear,
                        )
                      : widget.onDetectGps != null
                          ? IconButton(
                              icon: const Icon(Icons.my_location,
                                  size: 20, color: Color(0xFF1A73E8)),
                              tooltip: 'Detect GPS location',
                              onPressed: widget.onDetectGps,
                            )
                          : const Icon(Icons.search, size: 20),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Inline Bus Route Map Preview
// ─────────────────────────────────────────────

class _BusRouteMapPreview extends StatefulWidget {
  final LocationPoint? origin;
  final LocationPoint? destination;
  final Color accentColor;

  const _BusRouteMapPreview({
    this.origin,
    this.destination,
    required this.accentColor,
  });

  @override
  State<_BusRouteMapPreview> createState() => _BusRouteMapPreviewState();
}

class _BusRouteMapPreviewState extends State<_BusRouteMapPreview> {
  late MapController _mapController;

  static const _defaultCenter = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(_BusRouteMapPreview old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) => _animateCamera());
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _animateCamera() {
    final o = widget.origin;
    final d = widget.destination;
    if (o != null && d != null) {
      final bounds = LatLngBounds(
        LatLng(o.latitude, o.longitude),
        LatLng(d.latitude, d.longitude),
      );
      _mapController.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ));
    } else if (o != null) {
      _mapController.move(LatLng(o.latitude, o.longitude), 13);
    } else if (d != null) {
      _mapController.move(LatLng(d.latitude, d.longitude), 13);
    }
  }

  LatLng get _center {
    final o = widget.origin;
    final d = widget.destination;
    if (o != null && d != null) {
      return LatLng(
        (o.latitude + d.latitude) / 2,
        (o.longitude + d.longitude) / 2,
      );
    }
    if (o != null) return LatLng(o.latitude, o.longitude);
    if (d != null) return LatLng(d.latitude, d.longitude);
    return _defaultCenter;
  }

  double get _zoom =>
      (widget.origin == null && widget.destination == null) ? 4.5 : 12.0;

  @override
  Widget build(BuildContext context) {
    final o = widget.origin;
    final d = widget.destination;
    final hasRoute = o != null && d != null;

    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
            ),
            children: [
              // CartoDB Voyager tiles
              TileLayer(
                urlTemplate:
                    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                userAgentPackageName: 'com.travel_companion.app',
                fallbackUrl:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                maxZoom: 19,
              ),

              // Dashed polyline between origin and destination
              if (hasRoute)
                PolylineLayer(polylines: [
                  Polyline(
                    points: [
                      LatLng(o.latitude, o.longitude),
                      LatLng(d.latitude, d.longitude),
                    ],
                    strokeWidth: 4.0,
                    color: widget.accentColor,
                    pattern: StrokePattern.dashed(segments: [14, 7]),
                  ),
                ]),

              // Markers
              MarkerLayer(markers: [
                if (o != null)
                  Marker(
                    point: LatLng(o.latitude, o.longitude),
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: _OriginPin(),
                  ),
                if (d != null)
                  Marker(
                    point: LatLng(d.latitude, d.longitude),
                    width: 44,
                    height: 52,
                    alignment: Alignment.bottomCenter,
                    child: const _DestinationPin(),
                  ),
              ]),

              // Attribution
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                  TextSourceAttribution('CARTO'),
                ],
              ),
            ],
          ),

          // Distance chip
          if (hasRoute)
            Positioned(
              bottom: 36,
              left: 12,
              child: _DistanceChip(origin: o, destination: d),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Origin marker (blue dot)
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
    final label = km < 1
        ? '${(km * 1000).toStringAsFixed(0)} m'
        : '~${km.toStringAsFixed(1)} km';

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
              size: 13, color: Color(0xFF2E7D32)),
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
