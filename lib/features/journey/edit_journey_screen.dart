import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/core/ui/adaptive_navigation.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
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
          _EditBackground(accentColor: accentColor),
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
                                  'Edit ${type.label} Journey',
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
                          // Vehicle info
                          if (type == TransportType.train) ...[
                            _glassTextField(
                              controller: _pnrController,
                              label: 'PNR Number',
                              icon: Icons.confirmation_number,
                              accentColor: accentColor,
                              maxLength: 10,
                            ),
                            const SizedBox(height: 12),
                            _glassTextField(
                              controller: _vehicleNumberController,
                              label: 'Train Number',
                              icon: Icons.train,
                              accentColor: accentColor,
                            ),
                          ] else ...[
                            _glassTextField(
                              controller: _vehicleNumberController,
                              label: '${type.label} Route/Number',
                              icon: type.icon,
                              accentColor: accentColor,
                            ),
                          ],
                          const SizedBox(height: 12),

                          _glassTextField(
                            controller: _vehicleNameController,
                            label: '${type.label} Name',
                            icon: Icons.label,
                            accentColor: accentColor,
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
                          _GlassDateField(
                            label: 'Journey Date',
                            value: DateFormat(
                              'dd MMM yyyy (EEEE)',
                            ).format(_journeyDate),
                            icon: Icons.calendar_today,
                            accentColor: accentColor,
                            onTap: _selectDate,
                          ),
                          const SizedBox(height: 16),

                          // Time
                          _GlassDateField(
                            label: 'Departure Time',
                            value: _journeyTime != null
                                ? _journeyTime!.format(context)
                                : 'Not set',
                            icon: Icons.access_time,
                            accentColor: accentColor,
                            onTap: _selectTime,
                            isEmpty: _journeyTime == null,
                          ),
                          const SizedBox(height: 16),

                          if (type == TransportType.train) ...[
                            _glassTextField(
                              controller: _classController,
                              label: 'Class',
                              icon: Icons.airline_seat_recline_normal,
                              accentColor: accentColor,
                            ),
                            const SizedBox(height: 12),
                            _glassTextField(
                              controller: _berthController,
                              label: 'Berth/Seat',
                              icon: Icons.event_seat,
                              accentColor: accentColor,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Repeat section
                          _GlassRepeatSection(
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
            child: _GlassSaveBar(
              accentColor: accentColor,
              isLoading: _isLoading,
              onSave: _saveChanges,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color accentColor,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    final g = GlassColors.of(context);
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      validator: validator,
      style: TextStyle(color: g.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: g.textSecondary),
        prefixIcon: Icon(icon, color: accentColor),
        counterStyle: TextStyle(color: g.textHint),
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
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE74C3C)),
        ),
        filled: true,
        fillColor: g.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
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

// ─────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────

class _EditBackground extends StatelessWidget {
  final Color accentColor;
  const _EditBackground({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 240,
            height: 240,
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
          bottom: 160,
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
// Glass Date/Time Field
// ─────────────────────────────────────────────

class _GlassDateField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isEmpty;

  const _GlassDateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: g.textSecondary),
          prefixIcon: Icon(icon, color: accentColor),
          suffixIcon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: accentColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: g.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: g.inputBorder),
          ),
          filled: true,
          fillColor: g.inputFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: isEmpty ? g.textTertiary : g.text,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Repeat Section
// ─────────────────────────────────────────────

class _GlassRepeatSection extends StatelessWidget {
  final bool isRepeating;
  final int repeatDays;
  final Color accentColor;
  final ValueChanged<bool> onRepeatingChanged;
  final void Function(int index, bool selected) onDayToggled;

  const _GlassRepeatSection({
    required this.isRepeating,
    required this.repeatDays,
    required this.accentColor,
    required this.onRepeatingChanged,
    required this.onDayToggled,
  });

  String _repeatDaysDisplay() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final active = <String>[];
    for (var i = 0; i < 7; i++) {
      if (repeatDays & (1 << i) != 0) active.add(days[i]);
    }
    if (active.length == 7) return 'Daily';
    return active.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: g.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: g.border(0.1)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(Icons.repeat_rounded, color: accentColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Repeat Journey',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: g.text,
                            ),
                          ),
                          Text(
                            isRepeating
                                ? _repeatDaysDisplay()
                                : 'Set as a recurring journey',
                            style: TextStyle(
                              fontSize: 12,
                              color: g.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isRepeating,
                      onChanged: onRepeatingChanged,
                      activeThumbColor: accentColor,
                      activeTrackColor: accentColor.withValues(alpha: 0.35),
                      inactiveThumbColor: g.switchInactiveThumb,
                      inactiveTrackColor: g.switchInactiveTrack,
                    ),
                  ],
                ),
              ),
              if (isRepeating) ...[
                Divider(color: g.divider, height: 0),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildDaySelector(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector(BuildContext context) {
    final g = GlassColors.of(context);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: List.generate(7, (i) {
        final isSelected = repeatDays & (1 << i) != 0;
        return GestureDetector(
          onTap: () => onDayToggled(i, !isSelected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.2)
                  : g.cardFill(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.5)
                    : g.border(0.1),
              ),
            ),
            child: Text(
              days[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accentColor : g.textSecondary,
              ),
            ),
          ),
        );
      }),
    );
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
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CupertinoActivityIndicator(
                              color: g.loadingIndicator,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.checkmark_circle,
                                color: GlassColors.onAccent,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: GlassColors.onAccent,
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
