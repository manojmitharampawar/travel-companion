import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/journey_tracking_screen.dart';
import 'package:travel_companion/features/journey/widgets/location_search_field.dart';
import 'package:travel_companion/providers/app_providers.dart';

class QuickTripScreen extends ConsumerStatefulWidget {
  final TransportType initialType;

  const QuickTripScreen({
    super.key,
    this.initialType = TransportType.metro,
  });

  @override
  ConsumerState<QuickTripScreen> createState() => _QuickTripScreenState();
}

class _QuickTripScreenState extends ConsumerState<QuickTripScreen> {
  late TransportType _transportType;
  LocationPoint? _origin;
  LocationPoint? _destination;
  bool _isStarting = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _transportType = widget.initialType;
    _detectCurrentLocation();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _origin = LocationPoint(
          name: 'Current Location',
          latitude: position.latitude,
          longitude: position.longitude,
        );
      });
    } catch (_) {
      // User will pick manually
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _startTrip() async {
    if (_destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination')),
      );
      return;
    }

    setState(() => _isStarting = true);

    try {
      // If no origin, try current location one more time
      if (_origin == null) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        _origin = LocationPoint(
          name: 'Current Location',
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }

      final journey = Journey(
        transportType: _transportType,
        journeyDate: DateTime.now(),
        isQuickTrip: true,
        status: JourneyStatus.active,
        originLatitude: _origin?.latitude,
        originLongitude: _origin?.longitude,
        originName: _origin?.name,
        destinationLatitude: _destination!.latitude,
        destinationLongitude: _destination!.longitude,
        destinationName: _destination!.name,
        boardingStationCode: _origin?.stationCode,
        destinationStationCode: _destination!.stationCode,
        createdAt: DateTime.now(),
      );

      final id = await ref.read(journeyRepositoryProvider).insertJourney(journey);
      final savedJourney = journey.copyWith(id: id);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => JourneyTrackingScreen(journey: savedJourney),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start trip: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Trip'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Transport type
            SegmentedButton<TransportType>(
              segments: [
                TransportType.metro,
                TransportType.bus,
                TransportType.localTrain,
              ].map((type) {
                return ButtonSegment<TransportType>(
                  value: type,
                  label: Text(type.label, style: const TextStyle(fontSize: 12)),
                  icon: Icon(type.icon, size: 18),
                );
              }).toList(),
              selected: {_transportType},
              onSelectionChanged: (selected) {
                setState(() => _transportType = selected.first);
              },
            ),
            const SizedBox(height: 24),

            // Origin
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.my_location, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From', style: theme.textTheme.labelSmall),
                          if (_isGettingLocation)
                            const Text('Detecting location...')
                          else
                            Text(
                              _origin?.displayName ?? 'Unknown location',
                              style: theme.textTheme.bodyMedium,
                            ),
                        ],
                      ),
                    ),
                    if (_isGettingLocation)
                      const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Destination
            LocationSearchField(
              label: 'Where are you going? *',
              initialValue: _destination,
              onSelected: (loc) => setState(() => _destination = loc),
              stationRepository: ref.read(stationRepositoryProvider),
              locationRepository: ref.read(locationRepositoryProvider),
              onUseCurrentLocation: null, // Doesn't make sense for destination
            ),

            const Spacer(),

            // Big start button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isStarting || _destination == null ? null : _startTrip,
                icon: _isStarting
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow, size: 28),
                label: Text(
                  _isStarting ? 'Starting...' : 'Start Tracking',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _transportType.color,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
