import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class GlassBackButton extends StatelessWidget {
  const GlassBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = GlassColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.cardFill(0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border(0.1)),
        ),
        child: Icon(CupertinoIcons.arrow_left, color: colors.text, size: 20),
      ),
    );
  }
}
