import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/app_icons.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/local_train_schedule.dart';

class GlassLocalTrainScheduleResults extends StatelessWidget {
  final List<UpcomingTrain> trains;
  final bool isLoading;
  final UpcomingTrain? selectedTrain;
  final ValueChanged<UpcomingTrain> onTrainSelected;
  final VoidCallback onRefresh;
  final Color accent;

  const GlassLocalTrainScheduleResults({
    super.key,
    required this.trains,
    required this.isLoading,
    required this.selectedTrain,
    required this.onTrainSelected,
    required this.onRefresh,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return GlassSectionCard(
      title: 'NEXT TRAINS',
      icon: AppIcons.schedule,
      accentColor: accent,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: onRefresh,
              child: Row(
                children: [
                  Icon(AppIcons.refresh, size: 16, color: g.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Refresh',
                    style: TextStyle(fontSize: 11, color: g.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isLoading)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: CupertinoActivityIndicator(color: g.loadingIndicator),
            ),
          )
        else if (trains.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(AppIcons.trainOutlined, size: 40, color: g.textHint),
                  const SizedBox(height: 8),
                  Text(
                    'No more trains today',
                    style: TextStyle(color: g.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try swapping direction or check tomorrow',
                    style: TextStyle(fontSize: 12, color: g.textHint),
                  ),
                ],
              ),
            ),
          )
        else
          ...trains.map(
            (t) => GlassTrainCard(
              formattedDeparture: t.formattedDeparture,
              formattedArrival: t.formattedArrival,
              travelDuration: t.travelDuration,
              stopsCount: t.stopsCount,
              trainTypeLabel: t.trainTypeLabel,
              isFast: t.trainType == 'FAST' || t.trainType == 'SEMI_FAST',
              lineColor: t.lineColor,
              isSelected: selectedTrain?.schedule.id == t.schedule.id,
              onTap: () => onTrainSelected(t),
              accent: accent,
            ),
          ),
      ],
    );
  }
}
