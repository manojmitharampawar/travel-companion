import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass/glass_tokens.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class HomeHeaderSection extends StatelessWidget {
  const HomeHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = GlassColors.of(context);
    final typography = GlassTypography.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upcoming Journeys', style: typography.largeTitle),
        const SizedBox(height: 8),
        Text(
          'Your planned trips at a glance.',
          style: typography.body.copyWith(color: colors.textAlpha(0.65)),
        ),
      ],
    );
  }
}
