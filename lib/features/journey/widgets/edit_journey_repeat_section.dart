import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class EditJourneyRepeatSection extends StatelessWidget {
  final bool isRepeating;
  final int repeatDays;
  final Color accentColor;
  final ValueChanged<bool> onRepeatingChanged;
  final void Function(int index, bool selected) onDayToggled;

  const EditJourneyRepeatSection({
    super.key,
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
                    Icon(CupertinoIcons.repeat, color: accentColor, size: 20),
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
                    CupertinoSwitch(
                      value: isRepeating,
                      onChanged: onRepeatingChanged,
                      activeTrackColor: accentColor.withValues(alpha: 0.75),
                      thumbColor: isRepeating
                          ? accentColor
                          : g.switchInactiveThumb,
                      inactiveTrackColor: g.switchInactiveTrack,
                    ),
                  ],
                ),
              ),
              if (isRepeating) ...[
                Container(height: 1, color: g.divider),
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
