import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/core/ui/adaptive_navigation.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/journey_tracking_screen.dart';
import 'package:travel_companion/features/journey/widgets/location_search_field.dart';
import 'package:travel_companion/features/journey/widgets/quick_trip_background.dart';
import 'package:travel_companion/features/journey/widgets/quick_trip_origin_card.dart';
import 'package:travel_companion/features/journey/widgets/quick_trip_start_button.dart';
import 'package:travel_companion/features/journey/widgets/quick_trip_transport_selector.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/providers/app_providers.dart';

class QuickTripScreen extends ConsumerStatefulWidget {
  final TransportType initialType;

  const QuickTripScreen({super.key, this.initialType = TransportType.metro});

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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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
      AdaptiveFeedback.showToast(
        context,
        'Please select a destination',
        isError: true,
      );
      return;
    }

    setState(() => _isStarting = true);

    try {
      if (_origin == null) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
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

      final id = await ref
          .read(journeyRepositoryProvider)
          .insertJourney(journey);
      final savedJourney = journey.copyWith(id: id);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          adaptivePageRoute(JourneyTrackingScreen(journey: savedJourney)),
        );
      }
    } catch (e) {
      if (mounted) {
        AdaptiveFeedback.showToast(
          context,
          'Failed to start trip: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _transportType.color;
    final g = GlassColors.of(context);

    return CupertinoPageScaffold(
      backgroundColor: g.bg,
      child: Stack(
        children: [
          QuickTripBackground(accentColor: accentColor),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Glass AppBar row
                  Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(36, 36),
                        onPressed: () => Navigator.pop(context),
                        child: Icon(CupertinoIcons.back, color: g.text),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Trip',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: g.textAlpha(0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Transport type selector
                  QuickTripTransportSelector(
                    selected: _transportType,
                    types: const [
                      TransportType.metro,
                      TransportType.bus,
                      TransportType.localTrain,
                    ],
                    onChanged: (type) => setState(() => _transportType = type),
                  ),
                  const SizedBox(height: 24),

                  // Origin card
                  QuickTripOriginCard(
                    origin: _origin,
                    isGettingLocation: _isGettingLocation,
                  ),
                  const SizedBox(height: 12),

                  // Destination
                  LocationSearchField(
                    label: 'Where are you going? *',
                    initialValue: _destination,
                    onSelected: (loc) => setState(() => _destination = loc),
                    stationRepository: ref.read(stationRepositoryProvider),
                    locationRepository: ref.read(locationRepositoryProvider),
                    onUseCurrentLocation: null,
                  ),

                  const Spacer(),

                  // Glass start button
                  QuickTripStartButton(
                    accentColor: accentColor,
                    isStarting: _isStarting,
                    isDisabled: _destination == null,
                    onTap: _startTrip,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Background
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
