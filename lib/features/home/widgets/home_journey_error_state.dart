import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/ui/glass/glass_message_state.dart';

class HomeJourneyErrorState extends StatelessWidget {
  const HomeJourneyErrorState({super.key, required this.onRetryTap});

  final VoidCallback onRetryTap;

  @override
  Widget build(BuildContext context) {
    final colors = GlassColors.of(context);

    return GlassMessageState(
      icon: CupertinoIcons.exclamationmark_triangle_fill,
      title: 'Something went wrong',
      message: 'Check your connection and try again.',
      actionLabel: 'Retry',
      onActionTap: onRetryTap,
      tintColor: colors.statusDanger,
    );
  }
}
