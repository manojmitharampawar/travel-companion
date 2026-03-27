import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/core/services/geocoding_service.dart';
import 'package:travel_companion/data/models/location_point.dart';

/// Full-screen map picker for bus journeys.
///
/// Supports:
/// - Tap anywhere to drop a pin
/// - Search bar to jump to a location
/// - Current location FAB
/// - Reverse geocode of tapped point
/// - Animated pin drop
///
/// Returns the selected [LocationPoint] via Navigator.pop.
class BusMapPickerScreen extends StatefulWidget {
  final String title;
  final Color accentColor;
  final LocationPoint? initialLocation;

  const BusMapPickerScreen({
    super.key,
    required this.title,
    this.accentColor = const Color(0xFF2E7D32),
    this.initialLocation,
  });

  @override
  State<BusMapPickerScreen> createState() => _BusMapPickerScreenState();
}

class _BusMapPickerScreenState extends State<BusMapPickerScreen>
    with SingleTickerProviderStateMixin {
  late MapController _mapController;
  LatLng? _pinnedLocation;
  LocationPoint? _resolvedPoint;
  bool _isResolving = false;
  bool _isLocating = false;

  // Search
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<LocationPoint> _searchResults = [];
  bool _isSearching = false;
  bool _showSearch = false;
  Timer? _debounce;

  // Pin animation
  late AnimationController _pinAnimController;
  late Animation<double> _pinBounce;

  // India center default
  static const _indiaCenter = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pinBounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -20.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -20.0, end: 0.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _pinAnimController,
      curve: Curves.easeOut,
    ));

    if (widget.initialLocation != null) {
      _pinnedLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _resolvedPoint = widget.initialLocation;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController.dispose();
    _pinAnimController.dispose();
    super.dispose();
  }

  LatLng get _initialCenter {
    if (widget.initialLocation != null) {
      return LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
    }
    return _indiaCenter;
  }

  double get _initialZoom =>
      widget.initialLocation != null ? 15.0 : 4.5;

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    _dismissSearch();
    setState(() {
      _pinnedLocation = point;
      _resolvedPoint = null;
      _isResolving = true;
    });
    _pinAnimController.forward(from: 0);
    _reverseGeocode(point);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    final result = await GeocodingService.reverseGeocode(
      point.latitude,
      point.longitude,
    );
    if (!mounted) return;
    setState(() {
      _isResolving = false;
      _resolvedPoint = result ??
          LocationPoint(
            name: 'Pinned Location',
            latitude: point.latitude,
            longitude: point.longitude,
          );
    });
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      _mapController.move(latLng, 16);
      setState(() {
        _pinnedLocation = latLng;
        _resolvedPoint = null;
        _isResolving = true;
      });
      _pinAnimController.forward(from: 0);
      _reverseGeocode(latLng);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await GeocodingService.search(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _selectSearchResult(LocationPoint point) {
    final latLng = LatLng(point.latitude, point.longitude);
    _mapController.move(latLng, 16);
    setState(() {
      _pinnedLocation = latLng;
      _resolvedPoint = point;
      _searchResults = [];
      _showSearch = false;
    });
    _searchController.clear();
    _searchFocus.unfocus();
    _pinAnimController.forward(from: 0);
  }

  void _dismissSearch() {
    if (_showSearch) {
      setState(() {
        _showSearch = false;
        _searchResults = [];
      });
      _searchController.clear();
      _searchFocus.unfocus();
    }
  }

  void _confirmSelection() {
    if (_resolvedPoint != null) {
      Navigator.pop(context, _resolvedPoint);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              onTap: _onMapTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                userAgentPackageName: 'com.travel_companion.app',
                fallbackUrl:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                maxZoom: 19,
              ),
              if (_pinnedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pinnedLocation!,
                      width: 50,
                      height: 70,
                      alignment: Alignment.topCenter,
                      child: AnimatedBuilder(
                        animation: _pinBounce,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _pinBounce.value),
                          child: child,
                        ),
                        child: _MapPin(color: widget.accentColor),
                      ),
                    ),
                  ],
                ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                  TextSourceAttribution('CARTO'),
                ],
              ),
            ],
          ),

          // ── Tap hint overlay (no pin yet) ──────
          if (_pinnedLocation == null)
            Center(
              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tap on the map to drop a pin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Top bar with back + search ─────────
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            right: 12,
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    // Back button
                    _CircleButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    // Search bar
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: (q) {
                            setState(() => _showSearch = true);
                            _onSearchChanged(q);
                          },
                          onTap: () =>
                              setState(() => _showSearch = true),
                          decoration: InputDecoration(
                            hintText: 'Search for a place...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(Icons.search, size: 22),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                        _isSearching = false;
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 14),
                          ),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),

                // Search results dropdown
                if (_showSearch &&
                    (_searchResults.isNotEmpty || _isSearching))
                  Container(
                    margin: const EdgeInsets.only(top: 6, left: 44),
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isSearching && _searchResults.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text('Searching...',
                                    style: TextStyle(
                                        color: Color(0xFF5F6368),
                                        fontSize: 13)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, _) => const Divider(
                                height: 1, indent: 52, endIndent: 12),
                            itemBuilder: (_, i) {
                              final p = _searchResults[i];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 0),
                                leading: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: widget.accentColor
                                        .withValues(alpha: 0.10),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.location_on_rounded,
                                      size: 17, color: widget.accentColor),
                                ),
                                title: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: p.address != null
                                    ? Text(
                                        p.address!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      )
                                    : null,
                                onTap: () => _selectSearchResult(p),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),

          // ── Current Location FAB ───────────────
          Positioned(
            right: 16,
            bottom: (_resolvedPoint != null || _isResolving ? 170 : 40) +
                bottomPad,
            child: _CircleButton(
              icon: _isLocating
                  ? Icons.hourglass_top_rounded
                  : Icons.my_location_rounded,
              size: 48,
              color: widget.accentColor,
              iconColor: Colors.white,
              onTap: _isLocating ? null : _goToCurrentLocation,
            ),
          ),

          // ── Zoom controls ──────────────────────
          Positioned(
            right: 16,
            bottom: (_resolvedPoint != null || _isResolving ? 230 : 100) +
                bottomPad,
            child: Column(
              children: [
                _CircleButton(
                  icon: Icons.add,
                  size: 40,
                  onTap: () {
                    final cam = _mapController.camera;
                    _mapController.move(cam.center, cam.zoom + 1);
                  },
                ),
                const SizedBox(height: 4),
                _CircleButton(
                  icon: Icons.remove,
                  size: 40,
                  onTap: () {
                    final cam = _mapController.camera;
                    _mapController.move(cam.center, cam.zoom - 1);
                  },
                ),
              ],
            ),
          ),

          // ── Bottom location card ───────────────
          if (_resolvedPoint != null || _isResolving)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (_isResolving)
                          const Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Getting address...',
                                  style: TextStyle(fontSize: 14)),
                            ],
                          )
                        else ...[
                          // Location info
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: widget.accentColor
                                      .withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.location_on_rounded,
                                    color: widget.accentColor, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _resolvedPoint!.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_resolvedPoint!.address != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 3),
                                        child: Text(
                                          _resolvedPoint!.address!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Coordinates
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const SizedBox(width: 56),
                                Icon(Icons.gps_fixed,
                                    size: 13, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  '${_resolvedPoint!.latitude.toStringAsFixed(5)}, '
                                  '${_resolvedPoint!.longitude.toStringAsFixed(5)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Confirm button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton.icon(
                              onPressed: _confirmSelection,
                              style: FilledButton.styleFrom(
                                backgroundColor: widget.accentColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 20),
                              label: Text(
                                'Confirm ${widget.title}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
// Animated map pin
// ─────────────────────────────────────────────

class _MapPin extends StatelessWidget {
  final Color color;
  const _MapPin({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.40),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        // Pin tail
        CustomPaint(
          size: const Size(14, 10),
          painter: _PinTailPainter(color: color),
        ),
        // Ground shadow
        Container(
          width: 16,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter({required this.color});

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
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}

// ─────────────────────────────────────────────
// Reusable circle button (back, zoom, FAB)
// ─────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final Color? iconColor;

  const _CircleButton({
    required this.icon,
    this.onTap,
    this.size = 44,
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: size * 0.48,
          color: iconColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
