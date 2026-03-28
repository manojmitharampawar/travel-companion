import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/journey_tracking_screen.dart';
import 'package:travel_companion/features/journey/widgets/location_search_field.dart';
import 'package:travel_companion/providers/app_providers.dart';

const _kBgColor = Color(0xFF0A0E21);

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
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
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
        SnackBar(
          content: const Text('Please select a destination'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isStarting = true);

    try {
      if (_origin == null) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
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

      final id =
          await ref.read(journeyRepositoryProvider).insertJourney(journey);
      final savedJourney = journey.copyWith(id: id);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                JourneyTrackingScreen(journey: savedJourney),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start trip: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _transportType.color;

    return Scaffold(
      backgroundColor: _kBgColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _QuickTripBackground(accentColor: accentColor),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Glass AppBar row
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Trip',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Transport type selector
                  _GlassTransportSelector(
                    selected: _transportType,
                    types: const [
                      TransportType.metro,
                      TransportType.bus,
                      TransportType.localTrain,
                    ],
                    onChanged: (type) =>
                        setState(() => _transportType = type),
                  ),
                  const SizedBox(height: 24),

                  // Origin card
                  _GlassOriginCard(
                    origin: _origin,
                    isGettingLocation: _isGettingLocation,
                  ),
                  const SizedBox(height: 12),

                  // Destination
                  LocationSearchField(
                    label: 'Where are you going? *',
                    initialValue: _destination,
                    onSelected: (loc) =>
                        setState(() => _destination = loc),
                    stationRepository:
                        ref.read(stationRepositoryProvider),
                    locationRepository:
                        ref.read(locationRepositoryProvider),
                    onUseCurrentLocation: null,
                  ),

                  const Spacer(),

                  // Glass start button
                  _GlassStartButton(
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

// ─────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────

class _QuickTripBackground extends StatelessWidget {
  final Color accentColor;
  const _QuickTripBackground({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -80,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accentColor.withValues(alpha: 0.15),
                  accentColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accentColor.withValues(alpha: 0.08),
                  accentColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Glass Transport Selector
// ─────────────────────────────────────────────

class _GlassTransportSelector extends StatelessWidget {
  final TransportType selected;
  final List<TransportType> types;
  final ValueChanged<TransportType> onChanged;

  const _GlassTransportSelector({
    required this.selected,
    required this.types,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: types.map((type) {
              final isSelected = type == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? type.color.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(
                              color: type.color.withValues(alpha: 0.4))
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type.icon,
                          size: 20,
                          color: isSelected
                              ? type.color
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? type.color
                                : Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Origin Card
// ─────────────────────────────────────────────

class _GlassOriginCard extends StatelessWidget {
  final LocationPoint? origin;
  final bool isGettingLocation;

  const _GlassOriginCard({
    required this.origin,
    required this.isGettingLocation,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF27AE60).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.my_location,
                    color: Color(0xFF27AE60), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isGettingLocation)
                      Text(
                        'Detecting location...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      )
                    else
                      Text(
                        origin?.displayName ?? 'Unknown location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                  ],
                ),
              ),
              if (isGettingLocation)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.5),
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
// Glass Start Button
// ─────────────────────────────────────────────

class _GlassStartButton extends StatelessWidget {
  final Color accentColor;
  final bool isStarting;
  final bool isDisabled;
  final VoidCallback onTap;

  const _GlassStartButton({
    required this.accentColor,
    required this.isStarting,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isDisabled
            ? null
            : LinearGradient(
                colors: [
                  accentColor,
                  accentColor.withValues(alpha: 0.8),
                ],
              ),
        color: isDisabled ? Colors.white.withValues(alpha: 0.06) : null,
        borderRadius: BorderRadius.circular(16),
        border: isDisabled
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isStarting || isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isStarting)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                else
                  Icon(Icons.play_arrow,
                      size: 28,
                      color: isDisabled
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.white),
                const SizedBox(width: 8),
                Text(
                  isStarting ? 'Starting...' : 'Start Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDisabled
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.white,
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
