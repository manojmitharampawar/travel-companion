import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/core/ui/adaptive_navigation.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/features/journey/widgets/cupertino_glass_date_field.dart';
import 'package:travel_companion/features/journey/widgets/cupertino_glass_text_form_field.dart';
import 'package:travel_companion/features/journey/widgets/cupertino_glass_time_field.dart';
import 'package:travel_companion/features/journey/widgets/edit_journey_background.dart';
import 'package:travel_companion/features/journey/widgets/edit_journey_repeat_section.dart';
import 'package:travel_companion/features/journey/widgets/glass_save_bar.dart';
import 'package:travel_companion/features/journey/widgets/location_search_field.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';
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
  DateTime? _journeyTime;
  LocationPoint? _originLocation;
  LocationPoint? _destinationLocation;
  bool _isRepeating = false;
  int _repeatDays = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final j = widget.journey;
    _vehicleNumberController = TextEditingController(
      text: j.vehicleNumber ?? '',
    );
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
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        _journeyTime = DateTime(
          _journeyDate.year,
          _journeyDate.month,
          _journeyDate.day,
          hour,
          minute,
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
    final type = widget.journey.transportType;
    final accentColor = type.color;
    final g = GlassColors.of(context);

    return CupertinoPageScaffold(
      backgroundColor: g.bg,
      child: Stack(
        children: [
          EditJourneyBackground(accentColor: accentColor),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: TransportFormAppBar(title: 'Edit ${type.label} Journey'),
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
                          // Vehicle info
                          if (type == TransportType.train) ...[
                            CupertinoGlassTextFormField(
                              controller: _pnrController,
                              labelText: 'PNR Number',
                              prefixIcon: CupertinoIcons.number_circle,
                              maxLength: 10,
                            ),
                            const SizedBox(height: 12),
                            CupertinoGlassTextFormField(
                              controller: _vehicleNumberController,
                              labelText: 'Train Number',
                              prefixIcon: CupertinoIcons.tram_fill,
                            ),
                          ] else ...[
                            CupertinoGlassTextFormField(
                              controller: _vehicleNumberController,
                              labelText: '${type.label} Route/Number',
                              prefixIcon: type.icon,
                            ),
                          ],
                          const SizedBox(height: 12),

                          CupertinoGlassTextFormField(
                            controller: _vehicleNameController,
                            labelText: '${type.label} Name',
                            prefixIcon: CupertinoIcons.tag,
                          ),
                          const SizedBox(height: 16),

                          // Location fields
                          if (type != TransportType.train) ...[
                            LocationSearchField(
                              label: 'Origin',
                              initialValue: _originLocation,
                              onSelected: (loc) =>
                                  setState(() => _originLocation = loc),
                              stationRepository: ref.read(
                                stationRepositoryProvider,
                              ),
                              locationRepository: ref.read(
                                locationRepositoryProvider,
                              ),
                              onPickOnMap: () => _pickOnMap(isOrigin: true),
                            ),
                            const SizedBox(height: 16),
                            LocationSearchField(
                              label: 'Destination',
                              initialValue: _destinationLocation,
                              onSelected: (loc) =>
                                  setState(() => _destinationLocation = loc),
                              stationRepository: ref.read(
                                stationRepositoryProvider,
                              ),
                              locationRepository: ref.read(
                                locationRepositoryProvider,
                              ),
                              onPickOnMap: () => _pickOnMap(isOrigin: false),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Date
                          CupertinoGlassDateField(
                            value: _journeyDate,
                            accentColor: accentColor,
                            onChanged: (value) =>
                                setState(() => _journeyDate = value),
                          ),
                          const SizedBox(height: 16),

                          // Time
                          CupertinoGlassTimeField(
                            label: 'Departure Time',
                            value: _journeyTime,
                            accentColor: accentColor,
                            onChanged: (value) =>
                                setState(() => _journeyTime = value),
                          ),
                          const SizedBox(height: 16),

                          if (type == TransportType.train) ...[
                            CupertinoGlassTextFormField(
                              controller: _classController,
                              labelText: 'Class',
                              prefixIcon:
                                  CupertinoIcons.rectangle_stack_person_crop,
                            ),
                            const SizedBox(height: 12),
                            CupertinoGlassTextFormField(
                              controller: _berthController,
                              labelText: 'Berth/Seat',
                              prefixIcon: CupertinoIcons.bed_double_fill,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Repeat section
                          EditJourneyRepeatSection(
                            isRepeating: _isRepeating,
                            repeatDays: _repeatDays,
                            accentColor: accentColor,
                            onRepeatingChanged: (val) => setState(() {
                              _isRepeating = val;
                              if (!val) _repeatDays = 0;
                            }),
                            onDayToggled: (i, selected) => setState(() {
                              if (selected) {
                                _repeatDays |= (1 << i);
                              } else {
                                _repeatDays &= ~(1 << i);
                              }
                            }),
                          ),
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
              accentColor: accentColor,
              isLoading: _isLoading,
              label: 'Save Changes',
              onSave: _saveChanges,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
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

      final updated = widget.journey.copyWith(
        vehicleNumber: _vehicleNumberController.text.isEmpty
            ? null
            : _vehicleNumberController.text,
        vehicleName: _vehicleNameController.text.isEmpty
            ? null
            : _vehicleNameController.text,
        pnr: _pnrController.text.isEmpty ? null : _pnrController.text,
        journeyDate: journeyDateTime,
        travelClass: _classController.text.isEmpty
            ? null
            : _classController.text,
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
        AdaptiveFeedback.showToast(context, 'Journey updated!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AdaptiveFeedback.showToast(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Background
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
