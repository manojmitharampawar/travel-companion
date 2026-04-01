import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/features/history/widgets/reschedule_picker_tile.dart';

/// Dialog for rescheduling a journey with Cupertino date and time pickers.
/// Returns `(DateTime selectedDate, DateTime selectedTime)` when confirmed.
class JourneyRescheduleDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialTime;

  const JourneyRescheduleDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.initialTime,
    super.key,
  });

  @override
  State<JourneyRescheduleDialog> createState() =>
      _JourneyRescheduleDialogState();
}

class _JourneyRescheduleDialogState extends State<JourneyRescheduleDialog> {
  late DateTime selectedDate;
  late DateTime selectedTime;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    selectedTime = widget.initialTime ?? DateTime(0, 1, 1, 6, 0);
  }

  Future<void> _selectDate() async {
    final picked = await _showPicker(
      mode: CupertinoDatePickerMode.date,
      initial: selectedDate,
      minimum: widget.firstDate,
      maximum: widget.lastDate,
    );
    if (picked != null && mounted) {
      setState(() {
        selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _selectTime() async {
    final base = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    final picked = await _showPicker(
      mode: CupertinoDatePickerMode.time,
      initial: base,
    );
    if (picked != null && mounted) {
      setState(() {
        selectedTime = DateTime(0, 1, 1, picked.hour, picked.minute);
      });
    }
  }

  Future<DateTime?> _showPicker({
    required CupertinoDatePickerMode mode,
    required DateTime initial,
    DateTime? minimum,
    DateTime? maximum,
  }) async {
    DateTime tempValue = initial;
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) {
        final g = GlassColors.of(context);
        return Container(
          height: 290,
          margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
          decoration: BoxDecoration(
            color: g.cardFill(),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: g.border(0.15)),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  onPressed: () => Navigator.pop(context, tempValue),
                  child: const Text('Done'),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: mode,
                  initialDateTime: initial,
                  minimumDate: minimum,
                  maximumDate: maximum,
                  use24hFormat: false,
                  onDateTimeChanged: (value) => tempValue = value,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final dateStr = DateFormat('dd MMM yyyy').format(selectedDate);
    final timeStr = DateFormat(
      'hh:mm a',
    ).format(DateTime(0, 1, 1, selectedTime.hour, selectedTime.minute));

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [g.cardFill(), g.cardFill(0.92)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: g.border(0.15)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Reschedule Journey',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: g.text,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ReschedulePickerTile(
                    label: 'Date',
                    value: dateStr,
                    icon: CupertinoIcons.calendar,
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 12),
                  ReschedulePickerTile(
                    label: 'Time',
                    value: timeStr,
                    icon: CupertinoIcons.time,
                    onTap: _selectTime,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: g.textAlpha(0.12),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: g.text),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: const Color(0xFF00BCD4),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () => Navigator.pop(context, (
                            selectedDate,
                            selectedTime,
                          )),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(color: CupertinoColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
