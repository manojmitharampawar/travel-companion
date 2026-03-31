import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:intl/intl.dart';

/// Dialog for rescheduling a journey with date and time selection.
/// SOLID-D: Depends on Material widgets, no business logic - purely UI
/// Returns: (DateTime, TimeOfDay) tuple on confirmation, null on cancel
class JourneyRescheduleDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final TimeOfDay? initialTime;

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
  late TimeOfDay selectedTime;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    selectedTime = widget.initialTime ?? const TimeOfDay(hour: 6, minute: 0);
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      helpText: 'Select journey date',
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      helpText: 'Select boarding time',
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final dateStr = DateFormat('dd MMM yyyy').format(selectedDate);
    final timeStr = selectedTime.format(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  g.cardFill(),
                  g.cardFill(),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: g.border(0.15),
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      'Reschedule Journey',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: g.text,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date selector
                    _buildDateTimeSelector(
                      context: context,
                      label: 'Date',
                      value: dateStr,
                      icon: Icons.calendar_today_rounded,
                      onTap: () => _selectDate(context),
                      g: g,
                    ),
                    const SizedBox(height: 16),

                    // Time selector
                    _buildDateTimeSelector(
                      context: context,
                      label: 'Time',
                      value: timeStr,
                      icon: Icons.schedule_rounded,
                      onTap: () => _selectTime(context),
                      g: g,
                    ),
                    const SizedBox(height: 28),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: _buildButton(
                              label: 'Cancel',
                              color: g.textAlpha(0.15),
                              textColor: g.text,
                              g: g,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pop(context, (selectedDate, selectedTime)),
                            child: _buildButton(
                              label: 'Confirm',
                              color: const Color(0xFF00BCD4),
                              textColor: Colors.white,
                              g: g,
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
      ),
    );
  }

  Widget _buildDateTimeSelector({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required GlassColors g,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: g.dropdownBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: g.border(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: g.textAlpha(0.6)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: g.textAlpha(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: g.text,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_rounded, size: 18, color: g.textAlpha(0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required Color textColor,
    required GlassColors g,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
