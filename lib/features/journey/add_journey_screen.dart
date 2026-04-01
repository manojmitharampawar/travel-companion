import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/core/ui/adaptive_navigation.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/station.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/widgets/add_journey_background.dart';
import 'package:travel_companion/features/journey/widgets/cupertino_glass_date_field.dart';
import 'package:travel_companion/features/journey/widgets/cupertino_glass_text_form_field.dart';
import 'package:travel_companion/features/journey/widgets/cupertino_glass_time_field.dart';
import 'package:travel_companion/features/journey/widgets/glass_save_bar.dart';
import 'package:travel_companion/features/journey/widgets/glass_station_search_field.dart';
import 'package:travel_companion/features/journey/widgets/glass_transport_type_selector.dart';
import 'package:travel_companion/features/journey/widgets/journey_sliver_header.dart';
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
  DateTime? _journeyTime;
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
          AddJourneyBackground(accentColor: _accentColor),
          CustomScrollView(
            slivers: [
              JourneySliverHeader(title: 'Add ${_transportType.label} Journey'),

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
                          GlassTransportTypeSelector(
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
                            child: Container(height: 1, color: g.divider),
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
            child: GlassSaveBar(
              accentColor: _accentColor,
              isLoading: _isLoading,
              onSave: _saveJourney,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ Glass Input Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€â”€ Train Fields â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  List<Widget> _buildTrainFields() {
    return [
      _glassSectionLabel('Train Details'),
      CupertinoGlassTextFormField(
        controller: _pnrController,
        labelText: 'PNR Number (optional)',
        hintText: '10-digit PNR',
        helperText: 'Example: 1234567890',
        prefixIcon: CupertinoIcons.number_circle,
        keyboardType: TextInputType.number,
        maxLength: 10,
      ),
      const SizedBox(height: 16),
      CupertinoGlassTextFormField(
        controller: _vehicleNumberController,
        labelText: 'Train Number *',
        hintText: 'e.g., 12345',
        helperText: 'Train name will auto-fill when number is entered',
        prefixIcon: CupertinoIcons.tram_fill,
        suffix: _isAutoFilling
            ? const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CupertinoActivityIndicator(radius: 8),
                ),
              )
            : null,
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
      CupertinoGlassTextFormField(
        controller: _vehicleNameController,
        labelText: 'Train Name (optional)',
        hintText: 'e.g., Rajdhani Express',
        prefixIcon: CupertinoIcons.tag,
      ),
      const SizedBox(height: 24),
      _glassSectionLabel('Journey Route'),
      GlassStationSearchField(
        label: 'Boarding Station *',
        selectedStation: _boardingStation,
        accentColor: _accentColor,
        onSelected: (station) => setState(() => _boardingStation = station),
      ),
      const SizedBox(height: 16),
      GlassStationSearchField(
        label: 'Destination Station *',
        selectedStation: _destinationStation,
        accentColor: _accentColor,
        onSelected: (station) => setState(() => _destinationStation = station),
      ),
      const SizedBox(height: 24),
      _glassSectionLabel('Travel Information'),
      _buildDatePicker(),
      const SizedBox(height: 16),
      GlassPickerField<String>(
        label: 'Class (optional)',
        placeholder: 'Select travel class',
        prefixIcon: CupertinoIcons.rectangle_stack_person_crop,
        value: _classController.text.isEmpty ? null : _classController.text,
        enableSearch: true,
        allowClear: true,
        options: const [
          GlassPickerOption(value: 'SL', label: 'Sleeper (SL)'),
          GlassPickerOption(value: '3A', label: 'AC 3 Tier (3A)'),
          GlassPickerOption(value: '2A', label: 'AC 2 Tier (2A)'),
          GlassPickerOption(value: '1A', label: 'AC First (1A)'),
          GlassPickerOption(value: '3E', label: 'AC 3 Economy (3E)'),
          GlassPickerOption(value: 'CC', label: 'Chair Car (CC)'),
          GlassPickerOption(value: 'EC', label: 'Exec Chair (EC)'),
          GlassPickerOption(value: '2S', label: 'Second Sitting (2S)'),
        ],
        onChanged: (value) =>
            setState(() => _classController.text = value ?? ''),
      ),
      const SizedBox(height: 16),
      CupertinoGlassTextFormField(
        controller: _berthController,
        labelText: 'Berth/Seat (optional)',
        hintText: 'e.g., S5/32/SU',
        prefixIcon: CupertinoIcons.bed_double_fill,
      ),
    ];
  }

  List<Widget> _buildBusFields() {
    return [
      _glassSectionLabel('Bus Details'),
      CupertinoGlassTextFormField(
        controller: _vehicleNumberController,
        labelText: 'Route Number (optional)',
        hintText: 'e.g., Route 101',
        prefixIcon: CupertinoIcons.map_pin_ellipse,
      ),
      const SizedBox(height: 16),
      CupertinoGlassTextFormField(
        controller: _vehicleNameController,
        labelText: 'Bus Operator (optional)',
        hintText: 'e.g., KSRTC, RedBus',
        prefixIcon: CupertinoIcons.bus,
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

  List<Widget> _buildMetroLocalFields() {
    return [
      _glassSectionLabel('Journey Details'),
      CupertinoGlassTextFormField(
        controller: _vehicleNameController,
        labelText: _transportType.vehicleNameLabel,
        hintText: _transportType == TransportType.metro
            ? 'e.g., Blue Line'
            : 'e.g., Western Line',
        prefixIcon: _transportType.icon,
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
    return CupertinoGlassDateField(
      value: _journeyDate,
      accentColor: _accentColor,
      onChanged: (value) => setState(() => _journeyDate = value),
    );
  }

  Widget _buildTimePicker() {
    return CupertinoGlassTimeField(
      value: _journeyTime,
      accentColor: _accentColor,
      onChanged: (value) => setState(() => _journeyTime = value),
    );
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Background
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
