import 'package:flutter/cupertino.dart';
import 'package:travel_companion/features/journey/widgets/cupertino_glass_date_field.dart';

class JourneyDateField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final Color accentColor;

  const JourneyDateField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoGlassDateField(
      value: value,
      onChanged: onChanged,
      accentColor: accentColor,
      label: 'Journey Date',
    );
  }
}
