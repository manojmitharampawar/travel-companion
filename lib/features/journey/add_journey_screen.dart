import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:travel_companion/core/theme/app_theme.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/station.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/widgets/location_search_field.dart';
import 'package:travel_companion/features/map/map_location_picker.dart';
import 'package:travel_companion/providers/app_providers.dart';

class AddJourneyScreen extends ConsumerStatefulWidget {
  final TransportType initialType;

  const AddJourneyScreen({
    super.key,
    this.initialType = TransportType.train,
  });

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

  // For train journeys (station-based)
  Station? _boardingStation;
  Station? _destinationStation;

  // For non-train journeys (location-based)
  LocationPoint? _originLocation;
  LocationPoint? _destinationLocation;

  DateTime _journeyDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay? _journeyTime;
  bool _isLoading = false;
  bool _isAutoFilling = false;

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
            final from = await stationRepo.getStationByCode(endpoints['from_station']!);
            if (from != null) setState(() => _boardingStation = from);
          }

          if (_destinationStation == null) {
            final to = await stationRepo.getStationByCode(endpoints['to_station']!);
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    }
  }

  Future<void> _pickOnMap({required bool isOrigin}) async {
    final result = await Navigator.push<LocationPoint>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Add ${_transportType.label} Journey'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Transport type selector with improved styling
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What are you traveling by?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTransportTypeSelector(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Divider(color: Colors.grey[200]),
              ),

              // Transport-specific fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_transportType == TransportType.train) ..._buildTrainFields(),
                    if (_transportType == TransportType.bus) ..._buildBusFields(),
                    if (_transportType == TransportType.metro ||
                        _transportType == TransportType.localTrain)
                      ..._buildMetroLocalFields(),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button with improved styling
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveJourney,
                    style: ElevatedButton.styleFrom(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline),
                              SizedBox(width: 8),
                              Text(
                                'Save Journey',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransportTypeSelector() {
    return SegmentedButton<TransportType>(
      segments: TransportType.values.map((type) {
        return ButtonSegment<TransportType>(
          value: type,
          label: Text(type.label, style: const TextStyle(fontSize: 12)),
          icon: Icon(type.icon, size: 18),
        );
      }).toList(),
      selected: {_transportType},
      onSelectionChanged: (selected) {
        setState(() {
          _transportType = selected.first;
          // Reset type-specific fields
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
    );
  }

  List<Widget> _buildTrainFields() {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          'Train Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      TextFormField(
        controller: _pnrController,
        decoration: InputDecoration(
          labelText: 'PNR Number (optional)',
          hintText: '10-digit PNR',
          prefixIcon: const Icon(Icons.confirmation_number_outlined),
          helperText: 'Example: 1234567890',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        keyboardType: TextInputType.number,
        maxLength: 10,
      ),
      const SizedBox(height: 16),

      TextFormField(
        controller: _vehicleNumberController,
        decoration: InputDecoration(
          labelText: 'Train Number *',
          hintText: 'e.g., 12345',
          prefixIcon: const Icon(Icons.train),
          suffixIcon: _isAutoFilling
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
          helperText: 'Train name will auto-fill when number is entered',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        keyboardType: TextInputType.number,
        maxLength: 5,
        onChanged: _onTrainNumberChanged,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Train number is required';
          if (value.length < 4 || value.length > 5) return 'Enter a valid train number';
          return null;
        },
      ),
      const SizedBox(height: 16),

      TextFormField(
        controller: _vehicleNameController,
        decoration: InputDecoration(
          labelText: 'Train Name (optional)',
          hintText: 'e.g., Rajdhani Express',
          prefixIcon: const Icon(Icons.label_outline),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      const SizedBox(height: 24),

      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          'Journey Route',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      _StationSearchField(
        label: 'Boarding Station *',
        selectedStation: _boardingStation,
        onSelected: (station) => setState(() => _boardingStation = station),
      ),
      const SizedBox(height: 16),

      _StationSearchField(
        label: 'Destination Station *',
        selectedStation: _destinationStation,
        onSelected: (station) => setState(() => _destinationStation = station),
      ),
      const SizedBox(height: 24),

      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          'Travel Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      _buildDatePicker(),
      const SizedBox(height: 16),

      DropdownButtonFormField<String>(
        initialValue: _classController.text.isEmpty ? null : _classController.text,
        decoration: InputDecoration(
          labelText: 'Class (optional)',
          prefixIcon: const Icon(Icons.airline_seat_recline_normal),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
        decoration: InputDecoration(
          labelText: 'Berth/Seat (optional)',
          hintText: 'e.g., S5/32/SU',
          prefixIcon: const Icon(Icons.event_seat),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildBusFields() {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          'Bus Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      TextFormField(
        controller: _vehicleNumberController,
        decoration: InputDecoration(
          labelText: 'Route Number (optional)',
          hintText: 'e.g., Route 101',
          prefixIcon: const Icon(Icons.route),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      const SizedBox(height: 16),

      TextFormField(
        controller: _vehicleNameController,
        decoration: InputDecoration(
          labelText: 'Bus Operator (optional)',
          hintText: 'e.g., KSRTC, RedBus',
          prefixIcon: const Icon(Icons.directions_bus),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      const SizedBox(height: 24),

      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          'Journey Route',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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

      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          'Travel Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      _buildDatePicker(),
      const SizedBox(height: 16),
      _buildTimePicker(),
    ];
  }

  List<Widget> _buildMetroLocalFields() {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          'Journey Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      TextFormField(
        controller: _vehicleNameController,
        decoration: InputDecoration(
          labelText: _transportType.vehicleNameLabel,
          hintText: _transportType == TransportType.metro
              ? 'e.g., Blue Line'
              : 'e.g., Western Line',
          prefixIcon: Icon(_transportType.icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      const SizedBox(height: 24),

      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          'Journey Route',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Journey Date *',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd MMM yyyy (EEEE)').format(_journeyDate),
              style: const TextStyle(fontSize: 15),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: _selectTime,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Departure Time (optional)',
          prefixIcon: const Icon(Icons.access_time),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _journeyTime != null ? _journeyTime!.format(context) : 'Select time',
              style: TextStyle(
                fontSize: 15,
                color: _journeyTime != null ? Colors.black : Colors.grey[500],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[600],
            ),
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

    // Validate based on transport type
    if (_transportType == TransportType.train) {
      if (_boardingStation == null) return _showError('Please select a boarding station');
      if (_destinationStation == null) return _showError('Please select a destination station');
      if (_boardingStation!.code == _destinationStation!.code) {
        return _showError('Boarding and destination cannot be the same');
      }
    } else {
      if (_originLocation == null) return _showError('Please select an origin');
      if (_destinationLocation == null) return _showError('Please select a destination');
    }

    setState(() => _isLoading = true);

    try {
      DateTime journeyDateTime = _journeyDate;
      if (_journeyTime != null) {
        journeyDateTime = DateTime(
          _journeyDate.year, _journeyDate.month, _journeyDate.day,
          _journeyTime!.hour, _journeyTime!.minute,
        );
      }

      final journey = Journey(
        transportType: _transportType,
        pnr: _pnrController.text.isEmpty ? null : _pnrController.text,
        vehicleNumber: _vehicleNumberController.text.isEmpty
            ? null : _vehicleNumberController.text,
        vehicleName: _vehicleNameController.text.isEmpty
            ? null : _vehicleNameController.text,
        journeyDate: journeyDateTime,
        boardingStationCode: _boardingStation?.code,
        destinationStationCode: _destinationStation?.code,
        originLatitude: _originLocation?.latitude,
        originLongitude: _originLocation?.longitude,
        destinationLatitude: _destinationLocation?.latitude,
        destinationLongitude: _destinationLocation?.longitude,
        originName: _originLocation?.name,
        destinationName: _destinationLocation?.name,
        travelClass: _classController.text.isEmpty ? null : _classController.text,
        berth: _berthController.text.isEmpty ? null : _berthController.text,
        scheduledTime: _journeyTime != null
            ? '${_journeyTime!.hour.toString().padLeft(2, '0')}:${_journeyTime!.minute.toString().padLeft(2, '0')}'
            : null,
        createdAt: DateTime.now(),
      );

      // Save custom locations for reuse
      final locationRepo = ref.read(locationRepositoryProvider);
      if (_originLocation != null && _originLocation!.stationCode == null) {
        await locationRepo.saveLocation(_originLocation!);
      }
      if (_destinationLocation != null && _destinationLocation!.stationCode == null) {
        await locationRepo.saveLocation(_destinationLocation!);
      }

      await ref.read(journeyRepositoryProvider).insertJourney(journey);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journey added successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Failed to save journey: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.dangerColor),
    );
  }
}

// Keep the existing train-specific station search field for backward compat
class _StationSearchField extends ConsumerStatefulWidget {
  final String label;
  final Station? selectedStation;
  final ValueChanged<Station> onSelected;

  const _StationSearchField({
    required this.label,
    required this.selectedStation,
    required this.onSelected,
  });

  @override
  ConsumerState<_StationSearchField> createState() => _StationSearchFieldState();
}

class _StationSearchFieldState extends ConsumerState<_StationSearchField> {
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
  void didUpdateWidget(_StationSearchField oldWidget) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: widget.selectedStation != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _suggestions = [];
                        _showSuggestions = false;
                      });
                    },
                  )
                : null,
          ),
          onChanged: _onSearchChanged,
          validator: (_) {
            if (widget.selectedStation == null) return 'Please select a station';
            return null;
          },
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final station = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.train, size: 20),
                  title: Text(station.name),
                  subtitle: Text(station.code),
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
