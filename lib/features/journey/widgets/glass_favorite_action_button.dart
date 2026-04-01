import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class GlassFavoriteActionButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onToggle;

  const GlassFavoriteActionButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onToggle,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Icon(
          isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
          key: ValueKey(isFavorite),
          color: isFavorite
              ? const Color(0xFFFF5252)
              : GlassColors.of(context).textAlpha(0.7),
        ),
      ),
    );
  }
}
