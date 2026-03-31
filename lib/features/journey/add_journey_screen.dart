import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/core/ui/adaptive_navigation.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/station.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/widgets/location_search_field.dart';
import 'package:travel_companion/features/map/map_location_picker.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/providers/app_providers.dart';

class AddJourneyScreen extends ConsumerStatefulWidget {
  final TransportType initialType;

  const AddJourneyScreen({super.key, this.initialType = TransportType.train});

  @override
  ConsumerState<AddJourneyScreen> createState() => _AddJourneyScreenState();
}

class _AddJourneyScreenState extends ConsumerState<AddJourneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pnrController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _vehicleNameController = TextEditingController();
  final _classController = TextEditingController();
  final _berthController = TextEditingController();

  late TransportType _transportType;

  Station? _boardingStation;
  Station? _destinationStation;
  LocationPoint? _originLocation;
  LocationPoint? _destinationLocation;

  DateTime _journeyDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay? _journeyTime;
  bool _isLoading = false;
  bool _isAutoFilling = false;

  Color get _accentColor => _transportType.color;

  @override
  void initState() {
    super.initState();
    _transportType = widget.initialType;
  }

  @override
  void dispose() {
    _pnrController.dispose();
    _vehicleNumberController.dispose();
    _vehicleNameController.dispose();
    _classController.dispose();
    _berthController.dispose();
    super.dispose();
  }

  Future<void> _onTrainNumberChanged(String value) async {
    if (value.length < 4 || _transportType != TransportType.train) return;

    setState(() => _isAutoFilling = true);

    try {
      final trainRepo = ref.read(trainRepositoryProvider);
      final localName = await trainRepo.getTrainNameByNumber(value);

      if (localName != null && _vehicleNameController.text.isEmpty) {
        _vehicleNameController.text = localName;

        final endpoints = await trainRepo.getTrainEndpoints(value);
        if (endpoints != null) {
          final stationRepo = ref.read(stationRepositoryProvider);

          if (_boardingStation == null) {
            final from = await stationRepo.getStationByCode(
              endpoints['from_station']!,
            );
            if (from != null) setState(() => _boardingStation = from);
          }

          if (_destinationStation == null) {
            final to = await stationRepo.getStationByCode(
              endpoints['to_station']!,
            );
            if (to != null) setState(() => _destinationStation = to);
          }
        }
      } else if (value.length == 5 && _vehicleNameController.text.isEmpty) {
        final api = ref.read(trainStatusApiProvider);
        final details = await api.getTrainDetails(value);
        if (details != null && details['train_name'] != null) {
          final name = details['train_name'] as String;
          if (name.isNotEmpty) {
            _vehicleNameController.text = name;
          }
        }
      }
    } catch (_) {
      // Best-effort
    } finally {
      if (mounted) setState(() => _isAutoFilling = false);
    }
  }

  Future<void> _useCurrentLocation({required bool isOrigin}) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final location = LocationPoint(
        name: 'Current Location',
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() {
        if (isOrigin) {
          _originLocation = location;
        } else {
          _destinationLocation = location;
        }
      });
    } catch (e) {
      if (mounted) {
        AdaptiveFeedback.showToast(
          context,
          'Could not get current location',
          isError: true,
        );
      }
    }
  }

  Future<void> _pickOnMap({required bool isOrigin}) async {
    final result = await Navigator.push<LocationPoint>(
      context,
      adaptivePageRoute(
        MapLocationPicker(
          title: isOrigin ? 'Pick Origin' : 'Pick Destination',
          initialLocation: isOrigin ? _originLocation : _destinationLocation,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        if (isOrigin) {
          _originLocation = result;
        } else {
          _destinationLocation = result;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return CupertinoPageScaffold(
      backgroundColor: g.bg,
      child: Stack(
        children: [
          _AddJourneyBackground(accentColor: _accentColor),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: g.cardFill(0.12),
                            border: Border.all(color: g.border(0.15)),
                          ),
                          child: Row(
                            children: [
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                minimumSize: const Size(32, 32),
                                onPressed: () => Navigator.maybePop(context),
                                child: Icon(
                                  CupertinoIcons.back,
                                  color: g.appBarForeground,
                                  size: 20,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Add ${_transportType.label} Journey',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 44),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Transport type selector
                          Text(
                            'What are you traveling by?',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: g.textAlpha(0.8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _GlassTransportTypeSelector(
                            selected: _transportType,
                            onChanged: (type) {
                              setState(() {
                                _transportType = type;
                                _boardingStation = null;
                                _destinationStation = null;
                                _originLocation = null;
                                _destinationLocation = null;
                                _vehicleNumberController.clear();
                                _vehicleNameController.clear();
                                _pnrController.clear();
                                _classController.clear();
                                _berthController.clear();
                              });
                            },
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: g.divider),
                          ),

                          // Transport-specific fields
                          if (_transportType == TransportType.train)
                            ..._buildTrainFields(),
                          if (_transportType == TransportType.bus)
                            ..._buildBusFields(),
                          if (_transportType == TransportType.metro ||
                              _transportType == TransportType.localTrain)
                            ..._buildMetroLocalFields(),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _GlassSaveBar(
              accentColor: _accentColor,
              isLoading: _isLoading,
              onSave: _saveJourney,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Glass Input Helpers ──────────────────────

  InputDecoration _glassInputDecoration({
    required String labelText,
    String? hintText,
    String? helperText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final g = GlassColors.of(context);
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      labelStyle: TextStyle(color: g.textSecondary),
      hintStyle: TextStyle(color: g.textHint),
      helperStyle: TextStyle(color: g.textTertiary),
      counterStyle: TextStyle(color: g.textHint),
      prefixIcon: Icon(prefixIcon, color: _accentColor),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: g.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: g.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE74C3C)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2),
      ),
      errorStyle: const TextStyle(color: Color(0xFFE74C3C)),
      filled: true,
      fillColor: g.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  TextStyle get _glassTextStyle =>
      TextStyle(color: GlassColors.of(context).text);

  Widget _glassSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: _accentColor.withValues(alpha: 0.9),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ─── Train Fields ─────────────────────────────

  List<Widget> _buildTrainFields() {
    return [
      _glassSectionLabel('Train Details'),
      TextFormField(
        controller: _pnrController,
        style: _glassTextStyle,
        decoration: _glassInputDecoration(
          labelText: 'PNR Number (optional)',
          hintText: '10-digit PNR',
          helperText: 'Example: 1234567890',
          prefixIcon: Icons.confirmation_number_outlined,
        ),
        keyboardType: TextInputType.number,
        maxLength: 10,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _vehicleNumberController,
        style: _glassTextStyle,
        decoration: _glassInputDecoration(
          labelText: 'Train Number *',
          hintText: 'e.g., 12345',
          helperText: 'Train name will auto-fill when number is entered',
          prefixIcon: Icons.train,
          suffixIcon: _isAutoFilling
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: GlassColors.of(context).loadingIndicator,
                    ),
                  ),
                )
              : null,
        ),
        keyboardType: TextInputType.number,
        maxLength: 5,
        onChanged: _onTrainNumberChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Train number is required';
          }
          if (value.length < 4 || value.length > 5) {
            return 'Enter a valid train number';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _vehicleNameController,
        style: _glassTextStyle,
        decoration: _glassInputDecoration(
          labelText: 'Train Name (optional)',
          hintText: 'e.g., Rajdhani Express',
          prefixIcon: Icons.label_outline,
        ),
      ),
      const SizedBox(height: 24),
      _glassSectionLabel('Journey Route'),
      _GlassStationSearchField(
        label: 'Boarding Station *',
        selectedStation: _boardingStation,
        accentColor: _accentColor,
        onSelected: (station) => setState(() => _boardingStation = station),
      ),
      const SizedBox(height: 16),
      _GlassStationSearchField(
        label: 'Destination Station *',
        selectedStation: _destinationStation,
        accentColor: _accentColor,
        onSelected: (station) => setState(() => _destinationStation = station),
      ),
      const SizedBox(height: 24),
      _glassSectionLabel('Travel Information'),
      _buildDatePicker(),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: _classController.text.isEmpty
            ? null
            : _classController.text,
        style: _glassTextStyle,
        dropdownColor: GlassColors.of(context).dropdownBg,
        decoration: _glassInputDecoration(
          labelText: 'Class (optional)',
          prefixIcon: Icons.airline_seat_recline_normal,
        ),
        items: const [
          DropdownMenuItem(value: 'SL', child: Text('Sleeper (SL)')),
          DropdownMenuItem(value: '3A', child: Text('AC 3 Tier (3A)')),
          DropdownMenuItem(value: '2A', child: Text('AC 2 Tier (2A)')),
          DropdownMenuItem(value: '1A', child: Text('AC First (1A)')),
          DropdownMenuItem(value: '3E', child: Text('AC 3 Economy (3E)')),
          DropdownMenuItem(value: 'CC', child: Text('Chair Car (CC)')),
          DropdownMenuItem(value: 'EC', child: Text('Exec Chair (EC)')),
          DropdownMenuItem(value: '2S', child: Text('Second Sitting (2S)')),
        ],
        onChanged: (value) => _classController.text = value ?? '',
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _berthController,
        style: _glassTextStyle,
        decoration: _glassInputDecoration(
          labelText: 'Berth/Seat (optional)',
          hintText: 'e.g., S5/32/SU',
          prefixIcon: Icons.event_seat,
        ),
      ),
    ];
  }

  // ─── Bus Fields ───────────────────────────────

  List<Widget> _buildBusFields() {
    return [
      _glassSectionLabel('Bus Details'),
      TextFormField(
        controller: _vehicleNumberController,
        style: _glassTextStyle,
        decoration: _glassInputDecoration(
          labelText: 'Route Number (optional)',
          hintText: 'e.g., Route 101',
          prefixIcon: Icons.route,
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _vehicleNameController,
        style: _glassTextStyle,
        decoration: _glassInputDecoration(
          labelText: 'Bus Operator (optional)',
          hintText: 'e.g., KSRTC, RedBus',
          prefixIcon: Icons.directions_bus,
        ),
      ),
      const SizedBox(height: 24),
      _glassSectionLabel('Journey Route'),
      LocationSearchField(
        label: 'Origin *',
        initialValue: _originLocation,
        onSelected: (loc) => setState(() => _originLocation = loc),
        stationRepository: ref.read(stationRepositoryProvider),
        locationRepository: ref.read(locationRepositoryProvider),
        onUseCurrentLocation: () => _useCurrentLocation(isOrigin: true),
        onPickOnMap: () => _pickOnMap(isOrigin: true),
        transportType: TransportType.bus,
        allowMapSelection: true,
      ),
      const SizedBox(height: 16),
      LocationSearchField(
        label: 'Destination *',
        initialValue: _destinationLocation,
        onSelected: (loc) => setState(() => _destinationLocation = loc),
        stationRepository: ref.read(stationRepositoryProvider),
        locationRepository: ref.read(locationRepositoryProvider),
        onUseCurrentLocation: () => _useCurrentLocation(isOrigin: false),
        onPickOnMap: () => _pickOnMap(isOrigin: false),
        transportType: TransportType.bus,
        allowMapSelection: true,
      ),
      const SizedBox(height: 24),
      _glassSectionLabel('Travel Information'),
      _buildDatePicker(),
      const SizedBox(height: 16),
      _buildTimePicker(),
    ];
  }

  // ─── Metro/Local Fields ───────────────────────

  List<Widget> _buildMetroLocalFields() {
    return [
      _glassSectionLabel('Journey Details'),
      TextFormField(
        controller: _vehicleNameController,
        style: _glassTextStyle,
        decoration: _glassInputDecoration(
          labelText: _transportType.vehicleNameLabel,
          hintText: _transportType == TransportType.metro
              ? 'e.g., Blue Line'
              : 'e.g., Western Line',
          prefixIcon: _transportType.icon,
        ),
      ),
      const SizedBox(height: 24),
      _glassSectionLabel('Journey Route'),
      LocationSearchField(
        label: 'Origin Station *',
        initialValue: _originLocation,
        onSelected: (loc) => setState(() => _originLocation = loc),
        stationRepository: ref.read(stationRepositoryProvider),
        locationRepository: ref.read(locationRepositoryProvider),
        transportType: _transportType,
        allowMapSelection: false,
      ),
      const SizedBox(height: 16),
      LocationSearchField(
        label: 'Destination Station *',
        initialValue: _destinationLocation,
        onSelected: (loc) => setState(() => _destinationLocation = loc),
        stationRepository: ref.read(stationRepositoryProvider),
        locationRepository: ref.read(locationRepositoryProvider),
        transportType: _transportType,
        allowMapSelection: false,
      ),
      const SizedBox(height: 16),
      _buildDatePicker(),
      const SizedBox(height: 16),
      _buildTimePicker(),
    ];
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _glassInputDecoration(
          labelText: 'Journey Date *',
          prefixIcon: Icons.calendar_today,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd MMM yyyy (EEEE)').format(_journeyDate),
              style: TextStyle(
                fontSize: 15,
                color: GlassColors.of(context).text,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: _accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: _selectTime,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _glassInputDecoration(
          labelText: 'Departure Time (optional)',
          prefixIcon: Icons.access_time,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _journeyTime != null
                  ? _journeyTime!.format(context)
                  : 'Select time',
              style: TextStyle(
                fontSize: 15,
                color: _journeyTime != null
                    ? GlassColors.of(context).text
                    : GlassColors.of(context).textHint,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: _accentColor),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _journeyDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 120)),
    );
    if (picked != null) setState(() => _journeyDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _journeyTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _journeyTime = picked);
  }

  Future<void> _saveJourney() async {
    if (!_formKey.currentState!.validate()) return;

    if (_transportType == TransportType.train) {
      if (_boardingStation == null) {
        return _showError('Please select a boarding station');
      }
      if (_destinationStation == null) {
        return _showError('Please select a destination station');
      }
      if (_boardingStation!.code == _destinationStation!.code) {
        return _showError('Boarding and destination cannot be the same');
      }
    } else {
      if (_originLocation == null) {
        return _showError('Please select an origin');
      }
      if (_destinationLocation == null) {
        return _showError('Please select a destination');
      }
    }

    setState(() => _isLoading = true);

    try {
      DateTime journeyDateTime = _journeyDate;
      if (_journeyTime != null) {
        journeyDateTime = DateTime(
          _journeyDate.year,
          _journeyDate.month,
          _journeyDate.day,
          _journeyTime!.hour,
          _journeyTime!.minute,
        );
      }

      final journey = Journey(
        transportType: _transportType,
        pnr: _pnrController.text.isEmpty ? null : _pnrController.text,
        vehicleNumber: _vehicleNumberController.text.isEmpty
            ? null
            : _vehicleNumberController.text,
        vehicleName: _vehicleNameController.text.isEmpty
            ? null
            : _vehicleNameController.text,
        journeyDate: journeyDateTime,
        boardingStationCode: _boardingStation?.code,
        destinationStationCode: _destinationStation?.code,
        originLatitude: _originLocation?.latitude,
        originLongitude: _originLocation?.longitude,
        destinationLatitude: _destinationLocation?.latitude,
        destinationLongitude: _destinationLocation?.longitude,
        originName: _originLocation?.name,
        destinationName: _destinationLocation?.name,
        travelClass: _classController.text.isEmpty
            ? null
            : _classController.text,
        berth: _berthController.text.isEmpty ? null : _berthController.text,
        scheduledTime: _journeyTime != null
            ? '${_journeyTime!.hour.toString().padLeft(2, '0')}:${_journeyTime!.minute.toString().padLeft(2, '0')}'
            : null,
        createdAt: DateTime.now(),
      );

      final locationRepo = ref.read(locationRepositoryProvider);
      if (_originLocation != null && _originLocation!.stationCode == null) {
        await locationRepo.saveLocation(_originLocation!);
      }
      if (_destinationLocation != null &&
          _destinationLocation!.stationCode == null) {
        await locationRepo.saveLocation(_destinationLocation!);
      }

      await ref.read(journeyRepositoryProvider).insertJourney(journey);

      if (mounted) {
        AdaptiveFeedback.showToast(context, 'Journey added successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Failed to save journey: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    AdaptiveFeedback.showToast(context, message, isError: true);
  }
}

// ─────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────

class _AddJourneyBackground extends StatelessWidget {
  final Color accentColor;
  const _AddJourneyBackground({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accentColor.withValues(alpha: 0.12),
                  accentColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accentColor.withValues(alpha: 0.06),
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
// Glass Transport Type Selector
// ─────────────────────────────────────────────

class _GlassTransportTypeSelector extends StatelessWidget {
  final TransportType selected;
  final ValueChanged<TransportType> onChanged;

  const _GlassTransportTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: g.cardFill(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: g.border(0.1)),
          ),
          child: Row(
            children: TransportType.values.map((type) {
              final isSelected = type == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? type.color.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: type.color.withValues(alpha: 0.4))
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type.icon,
                          size: 18,
                          color: isSelected ? type.color : g.textTertiary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? type.color : g.textTertiary,
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
// Glass Station Search (train-specific)
// ─────────────────────────────────────────────

class _GlassStationSearchField extends ConsumerStatefulWidget {
  final String label;
  final Station? selectedStation;
  final Color accentColor;
  final ValueChanged<Station> onSelected;

  const _GlassStationSearchField({
    required this.label,
    required this.selectedStation,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  ConsumerState<_GlassStationSearchField> createState() =>
      _GlassStationSearchFieldState();
}

class _GlassStationSearchFieldState
    extends ConsumerState<_GlassStationSearchField> {
  final _controller = TextEditingController();
  List<Station> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedStation != null) {
      _controller.text = widget.selectedStation!.displayName;
    }
  }

  @override
  void didUpdateWidget(_GlassStationSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedStation != oldWidget.selectedStation &&
        widget.selectedStation != null) {
      _controller.text = widget.selectedStation!.displayName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          style: TextStyle(color: g.text),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(color: g.textSecondary),
            prefixIcon: Icon(Icons.location_on, color: widget.accentColor),
            suffixIcon: widget.selectedStation != null
                ? IconButton(
                    icon: Icon(Icons.clear, color: g.textSecondary),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _suggestions = [];
                        _showSuggestions = false;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: g.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: g.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: widget.accentColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE74C3C)),
            ),
            errorStyle: const TextStyle(color: Color(0xFFE74C3C)),
            filled: true,
            fillColor: g.inputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: _onSearchChanged,
          validator: (_) {
            if (widget.selectedStation == null) {
              return 'Please select a station';
            }
            return null;
          },
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: g.dropdownBg.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: g.border(0.1)),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final station = _suggestions[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.train,
                        size: 20,
                        color: widget.accentColor,
                      ),
                      title: Text(
                        station.name,
                        style: TextStyle(color: g.text, fontSize: 14),
                      ),
                      subtitle: Text(
                        station.code,
                        style: TextStyle(color: g.textTertiary, fontSize: 12),
                      ),
                      onTap: () {
                        _controller.text = station.displayName;
                        widget.onSelected(station);
                        setState(() {
                          _showSuggestions = false;
                          _suggestions = [];
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final stationRepo = ref.read(stationRepositoryProvider);
    final results = await stationRepo.searchStations(query);

    setState(() {
      _suggestions = results;
      _showSuggestions = true;
    });
  }
}

// ─────────────────────────────────────────────
// Glass Save Bar
// ─────────────────────────────────────────────

class _GlassSaveBar extends StatelessWidget {
  final Color accentColor;
  final bool isLoading;
  final VoidCallback onSave;

  const _GlassSaveBar({
    required this.accentColor,
    required this.isLoading,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: g.bottomBarBg,
            border: Border(top: BorderSide(color: g.bottomBarBorder, width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: isLoading ? null : onSave,
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CupertinoActivityIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.checkmark_circle,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Save Journey',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
      ),
    );
  }
}
