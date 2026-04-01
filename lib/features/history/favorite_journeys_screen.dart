import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/core/ui/glass/glass_back_button.dart';
import 'package:travel_companion/features/history/application/actions/reschedule_favorite_journey_action.dart';
import 'package:travel_companion/features/history/application/actions/toggle_favorite_journey_action.dart';
import 'package:travel_companion/features/history/application/history_journey_queries.dart';
import 'package:travel_companion/features/history/widgets/favorite_journey_body.dart';

class FavoriteJourneysScreen extends ConsumerWidget {
  const FavoriteJourneysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = GlassColors.of(context);
    final typography = GlassTypography.of(context);
    final horizontal = GlassLayout.horizontalPadding(context);
    final heroTop = GlassLayout.heroTopPadding(context);
    final bottomPadding = GlassLayout.bottomContentPadding(context);
    final canPop = Navigator.canPop(context);
    final favoritesAsync = ref.watch(favoriteJourneysProvider);

    return CupertinoPageScaffold(
      backgroundColor: colors.bg,
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
                  Text('Favourites', style: typography.largeTitle),
                  const SizedBox(height: 8),
                  Text(
                    'Your starred routes, ready to reschedule.',
                    style: typography.body.copyWith(
                      color: colors.textAlpha(0.65),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FavoriteJourneyBody(
                favoritesAsync: favoritesAsync,
                horizontal: horizontal,
                bottomPadding: bottomPadding,
                onRefresh: () async => ref.invalidate(favoriteJourneysProvider),
                onReschedule: (enrichedJourney) {
                  return RescheduleFavoriteJourneyAction.execute(
                    context: context,
                    ref: ref,
                    enrichedJourney: enrichedJourney,
                  );
                },
                onRemoveFavorite: (journeyId) {
                  return ToggleFavoriteJourneyAction.execute(
                    ref: ref,
                    journeyId: journeyId,
                    isFavorite: false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
