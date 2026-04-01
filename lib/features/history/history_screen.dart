import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/core/ui/glass/glass_back_button.dart';
import 'package:travel_companion/features/history/history_journeys_screen.dart';

/// Main History screen — shows completed/cancelled journeys.
/// Favourites are accessible via the dedicated bottom nav tab.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final typography = GlassTypography.of(context);
    final horizontal = GlassLayout.horizontalPadding(context);
    final heroTop = GlassLayout.heroTopPadding(context);
    final canPop = Navigator.canPop(context);

    return CupertinoPageScaffold(
      backgroundColor: g.bg,
      child: GlassMeshBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
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
                  Text('History', style: typography.largeTitle),
                  const SizedBox(height: 8),
                  Text(
                    'Review your completed and cancelled trips.',
                    style: typography.body.copyWith(color: g.textAlpha(0.65)),
                  ),
                ],
              ),
            ),
            const Expanded(child: HistoryJourneysScreen()),
          ],
        ),
      ),
    );
  }
}
