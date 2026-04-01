import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/models/enriched_journey.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/features/history/widgets/favorite_journey_card.dart';
import 'package:travel_companion/features/history/widgets/history_shared_widgets.dart';

class FavoriteJourneyBody extends StatelessWidget {
  final AsyncValue<List<EnrichedJourney>> favoritesAsync;
  final double horizontal;
  final double bottomPadding;
  final Future<void> Function() onRefresh;
  final Future<void> Function(EnrichedJourney enriched) onReschedule;
  final Future<void> Function(int journeyId) onRemoveFavorite;

  const FavoriteJourneyBody({
    super.key,
    required this.favoritesAsync,
    required this.horizontal,
    required this.bottomPadding,
    required this.onRefresh,
    required this.onReschedule,
    required this.onRemoveFavorite,
  });

  @override
  Widget build(BuildContext context) {
    if (favoritesAsync.isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }

    if (favoritesAsync.hasError) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
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
                title: 'Error loading favorites',
                subtitle: 'Please try again later',
              ),
            ),
          ),
        ],
      );
    }

    final journeys = favoritesAsync.valueOrNull ?? const <EnrichedJourney>[];
    if (journeys.isEmpty) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                GlassSpacing.lg,
                horizontal,
                bottomPadding,
              ),
              child: const GlassPlaceholder(
                icon: CupertinoIcons.heart,
                iconColor: Color(0xFFFF5252),
                title: 'No favorite journeys yet',
                subtitle:
                    'Star your favorite routes to reschedule them quickly',
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
        CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            GlassSpacing.md,
            horizontal,
            bottomPadding,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final journey = journeys[index].journey;
              return FavoriteJourneyCard(
                enrichedJourney: journeys[index],
                onReschedule: () => onReschedule(journeys[index]),
                onRemoveFavorite: () => onRemoveFavorite(journey.id!),
              );
            }, childCount: journeys.length),
          ),
        ),
      ],
    );
  }
}
