import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/features/history/application/actions/toggle_favorite_journey_action.dart';
import 'package:travel_companion/features/history/application/history_journey_queries.dart';
import 'package:travel_companion/features/history/widgets/history_journey_card.dart';
import 'package:travel_companion/features/history/widgets/history_shared_widgets.dart';

class HistoryJourneysScreen extends ConsumerWidget {
  const HistoryJourneysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontal = GlassLayout.horizontalPadding(context);
    final bottomPadding = GlassLayout.bottomContentPadding(context);
    final historyAsync = ref.watch(historyJourneysProvider);

    if (historyAsync.isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }

    if (historyAsync.hasError) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async => ref.invalidate(historyJourneysProvider),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                GlassSpacing.lg,
                horizontal,
                bottomPadding,
              ),
              child: const GlassPlaceholder(
                icon: CupertinoIcons.exclamationmark_triangle,
                iconColor: Color(0xFFE74C3C),
                title: 'Error loading history',
                subtitle: 'Please try again later',
              ),
            ),
          ),
        ],
      );
    }

    final journeys = historyAsync.valueOrNull ?? const [];
    if (journeys.isEmpty) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async => ref.invalidate(historyJourneysProvider),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                GlassSpacing.lg,
                horizontal,
                bottomPadding,
              ),
              child: GlassPlaceholder(
                icon: CupertinoIcons.clock,
                iconColor: CupertinoColors.white.withValues(alpha: 0.3),
                title: 'No journey history yet',
                subtitle: 'Your completed journeys will appear here',
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async => ref.invalidate(historyJourneysProvider),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            GlassSpacing.md,
            horizontal,
            bottomPadding,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return HistoryJourneyCard(
                enrichedJourney: journeys[index],
                onToggleFavorite: () async {
                  final journey = journeys[index].journey;
                  await ToggleFavoriteJourneyAction.execute(
                    ref: ref,
                    journeyId: journey.id!,
                    isFavorite: !journey.isFavorite,
                  );
                },
              );
            }, childCount: journeys.length),
          ),
        ),
      ],
    );
  }
}
