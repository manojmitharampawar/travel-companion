import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/core/services/geocoding_service.dart';
import 'package:travel_companion/core/services/tile_cache_service.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/features/map/widgets/circle_icon_button.dart';
import 'package:travel_companion/features/map/widgets/map_pin.dart';

const _kTileUrl =
    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';

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
  late final MapController _mapController;
  LatLng? _pinnedLocation;
  LocationPoint? _resolvedPoint;
  bool _isResolving = false;
  bool _isLocating = false;

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<LocationPoint> _searchResults = [];
  bool _isSearching = false;
  bool _showSearch = false;
  Timer? _debounce;

  late final AnimationController _pinAnimController;
  late final Animation<double> _pinBounce;

  static const _indiaCenter = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pinBounce =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -20.0), weight: 30),
          TweenSequenceItem(tween: Tween(begin: -20.0, end: 0.0), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 20),
          TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 20),
        ]).animate(
          CurvedAnimation(parent: _pinAnimController, curve: Curves.easeOut),
        );

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

  double get _initialZoom => widget.initialLocation != null ? 15.0 : 4.5;

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
      _resolvedPoint =
          result ??
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
          AdaptiveFeedback.showToast(
            context,
            'Location permission denied',
            isError: true,
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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
        AdaptiveFeedback.showToast(
          context,
          'Could not get current location',
          isError: true,
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
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
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
                urlTemplate: _kTileUrl,
                tileProvider: CachedTileProvider(urlTemplate: _kTileUrl),
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
                        child: MapPin(color: widget.accentColor),
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

          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Row(
                  children: [
                    CircleIconButton(
                      icon: CupertinoIcons.back,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CupertinoTextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: (q) {
                            setState(() => _showSearch = true);
                            _onSearchChanged(q);
                          },
                          onTap: () => setState(() => _showSearch = true),
                          placeholder: 'Search for a place...',
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Icon(CupertinoIcons.search, size: 18),
                          ),
                          suffix: _searchController.text.isNotEmpty
                              ? CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _isSearching = false;
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Icon(
                                      CupertinoIcons.clear_circled_solid,
                                      size: 18,
                                    ),
                                  ),
                                )
                              : null,
                          decoration: null,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showSearch && (_searchResults.isNotEmpty || _isSearching))
                  Container(
                    margin: const EdgeInsets.only(top: 6, left: 44),
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground.resolveFrom(
                        context,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isSearching && _searchResults.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CupertinoActivityIndicator(radius: 10),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: _searchResults.length,
                            itemBuilder: (_, i) {
                              final p = _searchResults[i];
                              return GestureDetector(
                                onTap: () => _selectSearchResult(p),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: widget.accentColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          CupertinoIcons.location_solid,
                                          size: 17,
                                          color: widget.accentColor,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (p.address != null)
                                              Text(
                                                p.address!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),

          Positioned(
            right: 16,
            bottom:
                (_resolvedPoint != null || _isResolving ? 170 : 40) + bottomPad,
            child: CircleIconButton(
              icon: _isLocating
                  ? CupertinoIcons.time
                  : CupertinoIcons.location_fill,
              size: 48,
              color: widget.accentColor,
              iconColor: CupertinoColors.white,
              onTap: _isLocating ? null : _goToCurrentLocation,
            ),
          ),

          Positioned(
            right: 16,
            bottom:
                (_resolvedPoint != null || _isResolving ? 230 : 100) +
                bottomPad,
            child: Column(
              children: [
                CircleIconButton(
                  icon: CupertinoIcons.add,
                  size: 40,
                  onTap: () {
                    final cam = _mapController.camera;
                    _mapController.move(cam.center, cam.zoom + 1);
                  },
                ),
                const SizedBox(height: 4),
                CircleIconButton(
                  icon: CupertinoIcons.minus,
                  size: 40,
                  onTap: () {
                    final cam = _mapController.camera;
                    _mapController.move(cam.center, cam.zoom - 1);
                  },
                ),
              ],
            ),
          ),

          if (_resolvedPoint != null || _isResolving)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 12,
                      offset: Offset(0, -4),
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
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD0D0D0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_isResolving)
                          const Row(
                            children: [
                              CupertinoActivityIndicator(radius: 9),
                              SizedBox(width: 12),
                              Text(
                                'Getting address...',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          )
                        else ...[
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: widget.accentColor.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  CupertinoIcons.location_solid,
                                  color: widget.accentColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Text(
                                          _resolvedPoint!.address!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF707070),
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
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              color: widget.accentColor,
                              borderRadius: BorderRadius.circular(14),
                              onPressed: _confirmSelection,
                              child: Text(
                                'Confirm ${widget.title}',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
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
