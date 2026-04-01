import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/core/theme/app_icons.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/features/journey/train/widgets/train_station_dot.dart';

class GlassTrainRoutePreview extends StatelessWidget {
  final List<TrainRouteStop> stops;
  final String boardingCode;
  final String destinationCode;
  final Color accentColor;

  const GlassTrainRoutePreview({
    super.key,
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

    return GlassSectionCard(
      title: 'Route Preview',
      icon: AppIcons.mapOutlined,
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
                  fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      strokeWidth: 4,
                      color: accentColor,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    for (int i = 0; i < routeStops.length; i++)
                      if (routeStops[i].latitude != 0)
                        Marker(
                          point: LatLng(
                            routeStops[i].latitude,
                            routeStops[i].longitude,
                          ),
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          child: TrainStationDot(
                            isEndpoint:
                                routeStops[i].stationCode == boardingCode ||
                                routeStops[i].stationCode == destinationCode,
                            isOrigin: routeStops[i].stationCode == boardingCode,
                            accentColor: accentColor,
                          ),
                        ),
                  ],
                ),
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
              style: TextStyle(fontSize: 11, color: g.textAlpha(0.4)),
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
    final boardingIdx = stops.indexWhere((s) => s.stationCode == boardingCode);
    final destIdx = stops.indexWhere((s) => s.stationCode == destinationCode);
    if (boardingIdx < 0 || destIdx < 0 || boardingIdx >= destIdx) return [];
    return stops.sublist(boardingIdx, destIdx + 1);
  }
}
