import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/data/models/location_point.dart';

class MapLocationPicker extends StatefulWidget {
  final LocationPoint? initialLocation;
  final String title;

  const MapLocationPicker({
    super.key,
    this.initialLocation,
    this.title = 'Pick Location',
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  LatLng? _selectedPoint;
  bool _isLoading = false;

  static const _defaultCenter = LatLng(20.5937, 78.9629);
  static const _defaultZoom = 5.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedPoint = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
    } else {
      _detectCurrentLocation();
    }
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _selectedPoint = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {
      // Default center fallback.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _selectedPoint ?? _defaultCenter;
    final zoom = _selectedPoint != null ? 14.0 : _defaultZoom;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        trailing: _selectedPoint == null
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: _confirmSelection,
                child: const Text('Confirm'),
              ),
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              onTap: (tapPosition, point) {
                setState(() => _selectedPoint = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.travel_companion.app',
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        CupertinoIcons.location_solid,
                        size: 34,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 4),
                ],
              ),
              child: Text(
                _selectedPoint != null
                    ? 'Tap to move pin, then press Confirm'
                    : 'Tap on the map to select a location',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF616161)),
              ),
            ),
          ),
          if (_isLoading)
            const Center(child: CupertinoActivityIndicator(radius: 12)),
        ],
      ),
    );
  }

  void _confirmSelection() {
    if (_selectedPoint == null) return;
    final location = LocationPoint(
      name: 'Map Location',
      latitude: _selectedPoint!.latitude,
      longitude: _selectedPoint!.longitude,
    );
    Navigator.pop(context, location);
  }
}
