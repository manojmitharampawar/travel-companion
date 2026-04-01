import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class CupertinoGlassTimeField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final Color accentColor;
  final String label;

  const CupertinoGlassTimeField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.accentColor,
    this.label = 'Departure Time (optional)',
  });

  Future<void> _pickTime(BuildContext context) async {
    final now = DateTime.now();
    final seed =
        value ?? DateTime(now.year, now.month, now.day, now.hour, now.minute);

    final picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (ctx) {
        DateTime temp = seed;
        final g = GlassColors.of(ctx);
        return _TimeSheet(
          accentColor: accentColor,
          glass: g,
          initialDateTime: seed,
          onDateChanged: (d) => temp = d,
          onClear: () => Navigator.pop(ctx, null),
          onCancel: () => Navigator.pop(ctx),
          onDone: () => Navigator.pop(ctx, temp),
        );
      },
    );

    if (picked != null || value != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final display = value == null
        ? 'Select time'
        : DateFormat('hh:mm a').format(value!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: g.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () => _pickTime(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: g.inputFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: g.inputBorder),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.clock, size: 18, color: accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        display,
                        style: TextStyle(
                          fontSize: 15,
                          color: value == null ? g.textHint : g.textAlpha(0.92),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_down,
                      size: 14,
                      color: g.textHint,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeSheet extends StatelessWidget {
  final Color accentColor;
  final GlassColors glass;
  final DateTime initialDateTime;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onClear;
  final VoidCallback onCancel;
  final VoidCallback onDone;

  const _TimeSheet({
    required this.accentColor,
    required this.glass,
    required this.initialDateTime,
    required this.onDateChanged,
    required this.onClear,
    required this.onCancel,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: glass.cardFill(0.9),
            padding: EdgeInsets.only(
              left: 14,
              right: 14,
              top: 10,
              bottom: MediaQuery.paddingOf(context).bottom + 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 30),
                      onPressed: onClear,
                      child: Text(
                        'Clear',
                        style: TextStyle(color: glass.textSecondary),
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 30),
                      onPressed: onCancel,
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: glass.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 30),
                      onPressed: onDone,
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 210,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: initialDateTime,
                    use24hFormat: false,
                    onDateTimeChanged: onDateChanged,
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
