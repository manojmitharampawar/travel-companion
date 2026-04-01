part of '../add_bus_journey_screen.dart';

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
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
          padding: const EdgeInsets.all(48),
        ),
      );
    } else if (o != null && d != null) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(o.latitude, o.longitude),
            LatLng(d.latitude, d.longitude),
          ),
          padding: const EdgeInsets.all(48),
        ),
      );
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
    final g = GlassColors.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: g.border(0.12)),
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
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: route.points,
                          strokeWidth: 7.0,
                          color: g.busAccent.withValues(alpha: 0.25),
                        ),
                        Polyline(
                          points: route.points,
                          strokeWidth: 4.5,
                          color: g.busAccent,
                        ),
                      ],
                    ),
                  if (!hasRoute && o != null && d != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [
                            LatLng(o.latitude, o.longitude),
                            LatLng(d.latitude, d.longitude),
                          ],
                          strokeWidth: 3.5,
                          color: g.busAccent.withValues(alpha: 0.50),
                          pattern: StrokePattern.dashed(segments: [14, 7]),
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (o != null)
                        Marker(
                          point: LatLng(o.latitude, o.longitude),
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: RouteMarker(
                            color: g.originMarker,
                            icon: AppIcons.tripOrigin,
                          ),
                        ),
                      if (d != null)
                        Marker(
                          point: LatLng(d.latitude, d.longitude),
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: RouteMarker(
                            color: g.destMarker,
                            icon: AppIcons.locationOnRounded,
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
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: g.bottomBarBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: g.inputBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CupertinoActivityIndicator(
                                  radius: 7,
                                  color: g.busAccent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Finding best route...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: g.busAccent,
                                ),
                              ),
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
                      GlassMapInfoChip(
                        icon: AppIcons.routeRounded,
                        label: route.distanceText,
                        color: g.busAccent,
                      ),
                      const SizedBox(width: 6),
                      GlassMapInfoChip(
                        icon: AppIcons.scheduleRounded,
                        label: route.durationText,
                        color: g.statusInfo,
                      ),
                    ],
                  ),
                ),

              if ((o != null) != (d != null))
                Positioned(
                  bottom: 36,
                  left: 10,
                  child: GlassMapInfoChip(
                    icon: AppIcons.locationOnRounded,
                    label: (o ?? d)!.name,
                    color: o != null ? g.originMarker : g.destMarker,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
