import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/glass/glass_tokens.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/ui/glass/glass_orb_background.dart';
import 'package:travel_companion/features/history/application/history_journey_queries.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/home/widgets/home_header_section.dart';
import 'package:travel_companion/features/home/widgets/home_journey_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = GlassColors.of(context);
    final horizontalPadding = GlassLayout.horizontalPadding(context);
    final heroTopPadding = GlassLayout.heroTopPadding(context);

    return CupertinoPageScaffold(
      backgroundColor: colors.bg,
      child: Stack(
        children: [
          const GlassOrbBackground(),
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  ref.invalidate(upcomingJourneysProvider);
                  ref.invalidate(historyJourneysProvider);
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    heroTopPadding,
                    horizontalPadding,
                    GlassSpacing.lg,
                  ),
                  child: const HomeHeaderSection(),
                ),
              ),
              const HomeJourneyList(),
            ],
          ),
        ],
      ),
    );
  }
}
