import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/core/services/geocoding_service.dart';
import 'package:travel_companion/core/services/routing_service.dart';
import 'package:travel_companion/core/services/tile_cache_service.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/bus/bus_journey_notifier.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';
import 'package:travel_companion/features/map/bus_map_picker_screen.dart';

const _kBgColor = Color(0xFF0A0E21);
const _accent = Color(0xFF2E7D32);
const _originColor = Color(0xFF1A73E8);
const _destColor = Color(0xFFD93025);
const _kTileUrl = 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';
const _kDarkTileUrl = 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';

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
      backgroundColor: _kBgColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Glass background
          _BusBackground(),

          Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                // Glass Hero AppBar
                SliverAppBar(
                  pinned: true,
                  expandedHeight: kToolbarHeight + 80,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: TransportHeroHeader(
                      type: TransportType.bus,
                      title: 'Add Bus Journey',
                      subtitle: 'Track your bus trip and get arrival alerts',
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.only(top: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Route section
                      FormSectionCard(
                        title: 'JOURNEY ROUTE',
                        icon: Icons.alt_route,
                        accentColor: _accent,
                        children: [
                          _GlassBusLocationField(
                            label: 'Origin',
                            hint: 'Boarding stop or area',
                            icon: Icons.trip_origin,
                            iconColor: _originColor,
                            value: state.origin,
                            isDetecting: state.isDetectingLocation,
                            onSelected: notifier.setOrigin,
                            onDetectGps: notifier.detectCurrentLocation,
                            onPickOnMap: () => _openMapPicker(
                              title: 'Origin',
                              current: state.origin,
                              onResult: notifier.setOrigin,
                            ),
                          ),

                          // Swap button
                          if (state.origin != null || state.destination != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Center(
                                child: GestureDetector(
                                  onTap: notifier.swapLocations,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _accent.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.swap_vert_rounded,
                                            size: 18, color: _accent),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Swap',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            fieldSpacing,

                          _GlassBusLocationField(
                            label: 'Destination',
                            hint: 'Destination stop or area',
                            icon: Icons.location_on,
                            iconColor: _destColor,
                            value: state.destination,
                            onSelected: notifier.setDestination,
                            onPickOnMap: () => _openMapPicker(
                              title: 'Destination',
                              current: state.destination,
                              onResult: notifier.setDestination,
                            ),
                          ),
                        ],
                      ),

                      // Route map preview
                      if (state.origin != null || state.destination != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: _GlassBusRouteMapPreview(
                            origin: state.origin,
                            destination: state.destination,
                            routeResult: state.routeResult,
                            isFetchingRoute: state.isFetchingRoute,
                          ),
                        ),

                      // Offline map download
                      if (state.origin != null && state.destination != null)
                        _GlassOfflineMapCard(
                          isCaching: state.isCachingTiles,
                          progress: state.tileCacheProgress,
                          isCached: state.tilesCached,
                          onDownload: notifier.downloadMapForOffline,
                        ),

                      // Bus details
                      FormSectionCard(
                        title: 'BUS DETAILS',
                        icon: Icons.directions_bus,
                        accentColor: _accent,
                        children: [
                          TextFormField(
                            controller: _routeCtrl,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9)),
                            decoration: glassInputDecoration(
                              labelText: 'Route Number (optional)',
                              hintText: 'e.g. 500LTD, AC47',
                              prefixIcon: Icons.confirmation_number_outlined,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onChanged: notifier.setRouteNumber,
                          ),
                          fieldSpacing,
                          TextFormField(
                            controller: _operatorCtrl,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9)),
                            decoration: glassInputDecoration(
                              labelText: 'Operator / Service (optional)',
                              hintText: 'e.g. MSRTC, KSRTC, Volvo',
                              prefixIcon: Icons.business_outlined,
                            ),
                            onChanged: notifier.setOperatorName,
                          ),
                        ],
                      ),

                      // Journey info
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

  Future<void> _openMapPicker({
    required String title,
    required LocationPoint? current,
    required ValueChanged<LocationPoint?> onResult,
  }) async {
    final result = await Navigator.push<LocationPoint>(
      context,
      MaterialPageRoute(
        builder: (_) => BusMapPickerScreen(
          title: title,
          accentColor: _accent,
          initialLocation: current,
        ),
      ),
    );
    if (result != null) {
      onResult(result);
    }
  }
}

// ─────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────

class _BusBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBgColor,
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: _GlowOrb(color: _accent, size: 220),
          ),
          Positioned(
            bottom: 150,
            left: -60,
            child: _GlowOrb(color: GlassConstants.meshCyan, size: 180),
          ),
          Positioned(
            top: 400,
            right: -30,
            child: _GlowOrb(color: GlassConstants.meshPurple, size: 140),
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
// Glass Bus Location Field
// ─────────────────────────────────────────────

class _GlassBusLocationField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final LocationPoint? value;
  final bool isDetecting;
  final ValueChanged<LocationPoint?> onSelected;
  final VoidCallback? onDetectGps;
  final VoidCallback onPickOnMap;

  const _GlassBusLocationField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onSelected,
    required this.onPickOnMap,
    this.onDetectGps,
    this.isDetecting = false,
  });

  @override
  State<_GlassBusLocationField> createState() => _GlassBusLocationFieldState();
}

class _GlassBusLocationFieldState extends State<_GlassBusLocationField> {
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
  void didUpdateWidget(_GlassBusLocationField old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) {
      _controller.text = widget.value?.name ?? '';
      if (widget.value != null) _removeOverlay();
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
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) _removeOverlay();
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
    _updateOverlay();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final res = await GeocodingService.search(query);
        if (mounted) {
          setState(() {
            _results = res;
            _isSearching = false;
          });
          if (res.isNotEmpty) {
            _updateOverlay();
          } else {
            _showNoResultsOverlay();
          }
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isSearching = false);
          _removeOverlay();
        }
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

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final fieldWidth = renderBox.size.width;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        width: fieldWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 62),
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(14),
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2340).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: _isSearching && _results.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('Searching...',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 13,
                                  )),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 56,
                            endIndent: 16,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
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
                                      widget.iconColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.location_on_rounded,
                                    size: 18, color: widget.iconColor),
                              ),
                              title: Text(
                                p.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              subtitle: p.address != null
                                  ? Text(
                                      p.address!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            Colors.white.withValues(alpha: 0.4),
                                      ),
                                    )
                                  : null,
                              trailing: Icon(Icons.north_west_rounded,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.3)),
                              onTap: () => _selectResult(p),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showNoResultsOverlay() {
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final fieldWidth = renderBox.size.width;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        width: fieldWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 62),
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(14),
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2340).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 20, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 28,
                          color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      Text(
                        'No locations found',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          _removeOverlay();
                          _focusNode.unfocus();
                          widget.onPickOnMap();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map_outlined,
                                  size: 16, color: _accent),
                              const SizedBox(width: 6),
                              Text(
                                'Pick on map instead',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final isSet = widget.value != null;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
            decoration: glassInputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: widget.icon,
              suffixIcon: widget.isDetecting || _isSearching
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
                  : isSet
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.5)),
                          onPressed: _clear,
                        )
                      : null,
            ),
          ),

          // Action row
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                _GlassActionChip(
                  icon: Icons.map_outlined,
                  label: 'Pick on map',
                  onTap: () {
                    _focusNode.unfocus();
                    _removeOverlay();
                    widget.onPickOnMap();
                  },
                ),
                if (widget.onDetectGps != null) ...[
                  const SizedBox(width: 8),
                  _GlassActionChip(
                    icon: Icons.my_location,
                    label: 'Current location',
                    color: _originColor,
                    onTap: widget.isDetecting ? null : widget.onDetectGps,
                  ),
                ],
              ],
            ),
          ),

          // Selected location chip
          if (isSet)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.iconColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: widget.iconColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.value!.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: widget.iconColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.value!.address != null)
                            Text(
                              widget.value!.address!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${widget.value!.latitude.toStringAsFixed(4)}, '
                      '${widget.value!.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.3),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass action chip
// ─────────────────────────────────────────────

class _GlassActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _GlassActionChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = _accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Route Map Preview
// ─────────────────────────────────────────────

class _GlassBusRouteMapPreview extends StatefulWidget {
  final LocationPoint? origin;
  final LocationPoint? destination;
  final RouteResult? routeResult;
  final bool isFetchingRoute;

  const _GlassBusRouteMapPreview({
    this.origin,
    this.destination,
    this.routeResult,
    this.isFetchingRoute = false,
  });

  @override
  State<_GlassBusRouteMapPreview> createState() =>
      _GlassBusRouteMapPreviewState();
}

class _GlassBusRouteMapPreviewState extends State<_GlassBusRouteMapPreview> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(_GlassBusRouteMapPreview old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _fitBounds() {
    final o = widget.origin;
    final d = widget.destination;
    final route = widget.routeResult;

    if (route != null && route.isNotEmpty) {
      double minLat = route.points.first.latitude;
      double maxLat = route.points.first.latitude;
      double minLng = route.points.first.longitude;
      double maxLng = route.points.first.longitude;
      for (final p in route.points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      _mapController.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(48),
      ));
    } else if (o != null && d != null) {
      _mapController.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(o.latitude, o.longitude),
          LatLng(d.latitude, d.longitude),
        ),
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
    return const LatLng(20.5937, 78.9629);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.origin;
    final d = widget.destination;
    final route = widget.routeResult;
    final hasRoute = route != null && route.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 12,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _kDarkTileUrl,
                    tileProvider: CachedTileProvider(urlTemplate: _kTileUrl),
                    maxZoom: 19,
                  ),
                  if (hasRoute)
                    PolylineLayer(polylines: [
                      Polyline(
                        points: route.points,
                        strokeWidth: 7.0,
                        color: _accent.withValues(alpha: 0.25),
                      ),
                      Polyline(
                        points: route.points,
                        strokeWidth: 4.5,
                        color: _accent,
                      ),
                    ]),
                  if (!hasRoute && o != null && d != null)
                    PolylineLayer(polylines: [
                      Polyline(
                        points: [
                          LatLng(o.latitude, o.longitude),
                          LatLng(d.latitude, d.longitude),
                        ],
                        strokeWidth: 3.5,
                        color: _accent.withValues(alpha: 0.50),
                        pattern: StrokePattern.dashed(segments: [14, 7]),
                      ),
                    ]),
                  MarkerLayer(markers: [
                    if (o != null)
                      Marker(
                        point: LatLng(o.latitude, o.longitude),
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: _RouteMarker(
                          color: _originColor,
                          icon: Icons.trip_origin,
                        ),
                      ),
                    if (d != null)
                      Marker(
                        point: LatLng(d.latitude, d.longitude),
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: _RouteMarker(
                          color: _destColor,
                          icon: Icons.location_on_rounded,
                        ),
                      ),
                  ]),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                      TextSourceAttribution('CARTO'),
                    ],
                  ),
                ],
              ),

              // Loading overlay
              if (widget.isFetchingRoute)
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _kBgColor.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _accent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('Finding best route...',
                                  style: TextStyle(
                                      fontSize: 12, color: _accent)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Route info chips
              if (hasRoute)
                Positioned(
                  bottom: 36,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      _GlassMapInfoChip(
                        icon: Icons.route_rounded,
                        label: route.distanceText,
                        color: _accent,
                      ),
                      const SizedBox(width: 6),
                      _GlassMapInfoChip(
                        icon: Icons.schedule_rounded,
                        label: route.durationText,
                        color: const Color(0xFF1565C0),
                      ),
                    ],
                  ),
                ),

              if ((o != null) != (d != null))
                Positioned(
                  bottom: 36,
                  left: 10,
                  child: _GlassMapInfoChip(
                    icon: Icons.location_on_rounded,
                    label: (o ?? d)!.name,
                    color: o != null ? _originColor : _destColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Route marker
// ─────────────────────────────────────────────

class _RouteMarker extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _RouteMarker({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}

// ─────────────────────────────────────────────
// Glass map info chip
// ─────────────────────────────────────────────

class _GlassMapInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _GlassMapInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _kBgColor.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass offline map card
// ─────────────────────────────────────────────

class _GlassOfflineMapCard extends StatelessWidget {
  final bool isCaching;
  final int progress;
  final bool isCached;
  final VoidCallback onDownload;

  const _GlassOfflineMapCard({
    required this.isCaching,
    required this.progress,
    required this.isCached,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isCached
                  ? _accent.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCached
                    ? _accent.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCached
                        ? _accent.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCached
                        ? Icons.offline_pin_rounded
                        : Icons.cloud_download_outlined,
                    size: 20,
                    color: isCached
                        ? _accent
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCached
                            ? 'Map saved for offline'
                            : isCaching
                                ? 'Downloading map tiles...'
                                : 'Save map for offline use',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCached
                              ? _accent
                              : Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (isCaching)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 4,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(_accent),
                          ),
                        )
                      else
                        Text(
                          isCached
                              ? 'Route map available without internet'
                              : 'Download route tiles for journey tracking',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isCached && !isCaching)
                  GestureDetector(
                    onTap: onDownload,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Download',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _accent,
                        ),
                      ),
                    ),
                  ),
                if (isCaching)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '$progress%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ),
                if (isCached)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: _accent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
