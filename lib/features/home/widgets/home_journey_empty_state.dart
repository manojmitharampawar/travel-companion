import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/ui/glass/glass_message_state.dart';

class HomeJourneyEmptyState extends StatelessWidget {
  const HomeJourneyEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = GlassColors.of(context);

    return GlassMessageState(
      icon: CupertinoIcons.train_style_one,
      title: 'No Upcoming Journeys',
      message:
          'Add your first journey to start receiving GPS-based arrival alerts.',
      tintColor: colors.accent,
    );
  }
}
