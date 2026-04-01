import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/core/ui/glass/glass_back_button.dart';

class SettingsPageHeader extends StatelessWidget {
  const SettingsPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final typography = GlassTypography.of(context);
    final horizontal = GlassLayout.horizontalPadding(context);
    final heroTop = GlassLayout.heroTopPadding(context);
    final canPop = Navigator.canPop(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        heroTop,
        horizontal,
        GlassSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canPop) ...[
            GlassBackButton(onTap: () => Navigator.maybePop(context)),
            const SizedBox(height: GlassSpacing.md),
          ],
          Text('Settings', style: typography.largeTitle),
          const SizedBox(height: 8),
          Text(
            'Tune reminders, tracking, and the app experience.',
            style: typography.body.copyWith(color: g.textAlpha(0.65)),
          ),
        ],
      ),
    );
  }
}
