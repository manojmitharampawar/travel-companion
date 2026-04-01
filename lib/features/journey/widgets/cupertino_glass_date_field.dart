import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class CupertinoGlassDateField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final Color accentColor;
  final String label;

  const CupertinoGlassDateField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.accentColor,
    this.label = 'Journey Date *',
  });

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final minimumDate = DateTime(now.year, now.month, now.day);
    final maximumDate = minimumDate.add(const Duration(days: 365));
    final initialDate = value.isBefore(minimumDate) ? minimumDate : value;

    final picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (ctx) {
        DateTime temp = initialDate;
        final g = GlassColors.of(ctx);
        return _DateSheet(
          accentColor: accentColor,
          glass: g,
          minimumDate: minimumDate,
          maximumDate: maximumDate,
          initialDate: initialDate,
          onDateChanged: (d) => temp = d,
          onCancel: () => Navigator.pop(ctx),
          onDone: () => Navigator.pop(ctx, temp),
        );
      },
    );

    if (picked != null) {
      onChanged(DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
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
          onPressed: () => _pickDate(context),
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
                    Icon(CupertinoIcons.calendar, size: 18, color: accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormat('dd MMM yyyy (EEEE)').format(value),
                        style: TextStyle(
                          fontSize: 15,
                          color: g.textAlpha(0.92),
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

class _DateSheet extends StatelessWidget {
  final Color accentColor;
  final GlassColors glass;
  final DateTime minimumDate;
  final DateTime maximumDate;
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onCancel;
  final VoidCallback onDone;

  const _DateSheet({
    required this.accentColor,
    required this.glass,
    required this.minimumDate,
    required this.maximumDate,
    required this.initialDate,
    required this.onDateChanged,
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
                      onPressed: onCancel,
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: glass.textSecondary),
                      ),
                    ),
                    const Spacer(),
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
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    minimumDate: minimumDate,
                    maximumDate: maximumDate,
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
