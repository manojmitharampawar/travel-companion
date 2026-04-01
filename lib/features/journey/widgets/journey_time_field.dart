import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/models/app_time.dart';
import 'package:travel_companion/features/journey/widgets/cupertino_glass_time_field.dart';

class JourneyTimeField extends StatelessWidget {
  final AppTime? value;
  final ValueChanged<AppTime?> onChanged;
  final Color accentColor;

  const JourneyTimeField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateTimeValue = value == null
        ? null
        : DateTime(now.year, now.month, now.day, value!.hour, value!.minute);

    return CupertinoGlassTimeField(
      value: dateTimeValue,
      onChanged: (next) {
        if (next == null) {
          onChanged(null);
        } else {
          onChanged(AppTime(hour: next.hour, minute: next.minute));
        }
      },
      accentColor: accentColor,
      label: 'Departure Time',
    );
  }
}
