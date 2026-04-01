import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';

class SaveJourneyButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onPressed;
  final Color accentColor;
  final String label;

  const SaveJourneyButton({
    super.key,
    required this.isSaving,
    required this.onPressed,
    required this.accentColor,
    this.label = 'Save Journey',
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      label: label,
      icon: CupertinoIcons.check_mark_circled,
      onPressed: isSaving ? null : onPressed,
      accentColor: accentColor,
      isLoading: isSaving,
    );
  }
}
