import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_companion/core/theme/app_theme.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/widgets/location_search_field.dart';
import 'package:travel_companion/features/map/map_location_picker.dart';
import 'package:travel_companion/providers/app_providers.dart';

class EditJourneyScreen extends ConsumerStatefulWidget {
  final Journey journey;

  const EditJourneyScreen({super.key, required this.journey});

  @override
  ConsumerState<EditJourneyScreen> createState() => _EditJourneyScreenState();
}

class _EditJourneyScreenState extends ConsumerState<EditJourneyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _vehicleNumberController;
  late final TextEditingController _vehicleNameController;
  late final TextEditingController _pnrController;
  late final TextEditingController _classController;
  late final TextEditingController _berthController;

  late DateTime _journeyDate;
  TimeOfDay? _journeyTime;
  LocationPoint? _originLocation;
  LocationPoint? _destinationLocation;
  bool _isRepeating = false;
  int _repeatDays = 0; // Bitmask
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final j = widget.journey;
    _vehicleNumberController = TextEditingController(text: j.vehicleNumber ?? '');
    _vehicleNameController = TextEditingController(text: j.vehicleName ?? '');
    _pnrController = TextEditingController(text: j.pnr ?? '');
    _classController = TextEditingController(text: j.travelClass ?? '');
    _berthController = TextEditingController(text: j.berth ?? '');
    _journeyDate = j.journeyDate;
    _isRepeating = j.isRepeating;
    _repeatDays = j.repeatDays ?? 0;

    if (j.scheduledTime != null) {
      final parts = j.scheduledTime!.split(':');
      if (parts.length == 2) {
        _journeyTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    if (!j.isTrain) {
      if (j.originLatitude != null && j.originLongitude != null) {
        _originLocation = LocationPoint(
          name: j.originName ?? 'Origin',
          latitude: j.originLatitude!,
          longitude: j.originLongitude!,
          stationCode: j.boardingStationCode,
        );
      }
      if (j.destinationLatitude != null && j.destinationLongitude != null) {
        _destinationLocation = LocationPoint(
          name: j.destinationName ?? 'Destination',
          latitude: j.destinationLatitude!,
          longitude: j.destinationLongitude!,
          stationCode: j.destinationStationCode,
        );
      }
    }
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _vehicleNameController.dispose();
    _pnrController.dispose();
    _classController.dispose();
    _berthController.dispose();
    super.dispose();
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
    final type = widget.journey.transportType;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${type.label} Journey'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vehicle info
              if (type == TransportType.train) ...[
                TextFormField(
                  controller: _pnrController,
                  decoration: const InputDecoration(
                    labelText: 'PNR Number',
                    prefixIcon: Icon(Icons.confirmation_number),
                  ),
                  maxLength: 10,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vehicleNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Train Number',
                    prefixIcon: Icon(Icons.train),
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller: _vehicleNumberController,
                  decoration: InputDecoration(
                    labelText: '${type.label} Route/Number',
                    prefixIcon: Icon(type.icon),
                  ),
                ),
              ],
              const SizedBox(height: 12),

              TextFormField(
                controller: _vehicleNameController,
                decoration: InputDecoration(
                  labelText: '${type.label} Name',
                  prefixIcon: const Icon(Icons.label),
                ),
              ),
              const SizedBox(height: 16),

              // Location fields
              if (type != TransportType.train) ...[
                LocationSearchField(
                  label: 'Origin',
                  initialValue: _originLocation,
                  onSelected: (loc) => setState(() => _originLocation = loc),
                  stationRepository: ref.read(stationRepositoryProvider),
                  locationRepository: ref.read(locationRepositoryProvider),
                  onPickOnMap: () => _pickOnMap(isOrigin: true),
                ),
                const SizedBox(height: 16),
                LocationSearchField(
                  label: 'Destination',
                  initialValue: _destinationLocation,
                  onSelected: (loc) => setState(() => _destinationLocation = loc),
                  stationRepository: ref.read(stationRepositoryProvider),
                  locationRepository: ref.read(locationRepositoryProvider),
                  onPickOnMap: () => _pickOnMap(isOrigin: false),
                ),
              ],
              const SizedBox(height: 16),

              // Date
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Journey Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd MMM yyyy (EEEE)').format(_journeyDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Time
              InkWell(
                onTap: _selectTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Departure Time',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    _journeyTime != null ? _journeyTime!.format(context) : 'Not set',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (type == TransportType.train) ...[
                TextFormField(
                  controller: _classController,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    prefixIcon: Icon(Icons.airline_seat_recline_normal),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _berthController,
                  decoration: const InputDecoration(
                    labelText: 'Berth/Seat',
                    prefixIcon: Icon(Icons.event_seat),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Repeat section
              const Divider(),
              SwitchListTile(
                title: const Text('Repeat Journey'),
                subtitle: _isRepeating
                    ? Text(_repeatDaysDisplay())
                    : const Text('Set as a recurring journey'),
                value: _isRepeating,
                onChanged: (val) => setState(() {
                  _isRepeating = val;
                  if (!val) _repeatDays = 0;
                }),
              ),

              if (_isRepeating) _buildDaySelector(),

              const SizedBox(height: 32),

              // Save
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24, width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Wrap(
      spacing: 8,
      children: List.generate(7, (i) {
        final isSelected = _repeatDays & (1 << i) != 0;
        return FilterChip(
          label: Text(days[i]),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _repeatDays |= (1 << i);
              } else {
                _repeatDays &= ~(1 << i);
              }
            });
          },
        );
      }),
    );
  }

  String _repeatDaysDisplay() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final active = <String>[];
    for (var i = 0; i < 7; i++) {
      if (_repeatDays & (1 << i) != 0) active.add(days[i]);
    }
    if (active.length == 7) return 'Daily';
    return active.join(', ');
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _journeyDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      DateTime journeyDateTime = _journeyDate;
      if (_journeyTime != null) {
        journeyDateTime = DateTime(
          _journeyDate.year, _journeyDate.month, _journeyDate.day,
          _journeyTime!.hour, _journeyTime!.minute,
        );
      }

      final updated = widget.journey.copyWith(
        vehicleNumber: _vehicleNumberController.text.isEmpty
            ? null : _vehicleNumberController.text,
        vehicleName: _vehicleNameController.text.isEmpty
            ? null : _vehicleNameController.text,
        pnr: _pnrController.text.isEmpty ? null : _pnrController.text,
        journeyDate: journeyDateTime,
        travelClass: _classController.text.isEmpty ? null : _classController.text,
        berth: _berthController.text.isEmpty ? null : _berthController.text,
        originLatitude: _originLocation?.latitude,
        originLongitude: _originLocation?.longitude,
        originName: _originLocation?.name,
        destinationLatitude: _destinationLocation?.latitude,
        destinationLongitude: _destinationLocation?.longitude,
        destinationName: _destinationLocation?.name,
        repeatDays: _isRepeating && _repeatDays > 0 ? _repeatDays : null,
        scheduledTime: _journeyTime != null
            ? '${_journeyTime!.hour.toString().padLeft(2, '0')}:${_journeyTime!.minute.toString().padLeft(2, '0')}'
            : null,
      );

      await ref.read(journeyRepositoryProvider).updateJourney(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journey updated!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.dangerColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
