import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/glass/glass_tokens.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/history/application/history_journey_queries.dart';
import 'package:travel_companion/features/home/widgets/home_journey_card.dart';
import 'package:travel_companion/features/home/widgets/home_journey_empty_state.dart';
import 'package:travel_companion/features/home/widgets/home_journey_error_state.dart';

class HomeJourneyList extends ConsumerWidget {
  const HomeJourneyList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeysAsync = ref.watch(upcomingJourneysProvider);
    final colors = GlassColors.of(context);

    return journeysAsync.when(
      loading: () => SliverFillRemaining(
        child: Center(
          child: CupertinoActivityIndicator(color: colors.secondaryAccent),
        ),
      ),
      error: (_, _) => SliverFillRemaining(
        child: HomeJourneyErrorState(
          onRetryTap: () {
            ref.invalidate(upcomingJourneysProvider);
            ref.invalidate(historyJourneysProvider);
          },
        ),
      ),
      data: (journeys) {
        if (journeys.isEmpty) {
          return const SliverFillRemaining(child: HomeJourneyEmptyState());
        }

        final horizontalPadding = GlassLayout.horizontalPadding(context);
        final listBottomPadding = GlassLayout.bottomContentPadding(context);

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            listBottomPadding,
          ),
          sliver: SliverList.builder(
            itemBuilder: (context, index) {
              return HomeJourneyCard(enrichedJourney: journeys[index]);
            },
            itemCount: journeys.length,
          ),
        );
      },
    );
  }
}
