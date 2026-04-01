import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/app_icons.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/metro_schedule.dart';

class GlassMetroScheduleResults extends StatelessWidget {
  final List<UpcomingMetro> trains;
  final bool isLoading;
  final UpcomingMetro? selectedTrain;
  final ValueChanged<UpcomingMetro> onTrainSelected;
  final VoidCallback onRefresh;
  final Color accent;

  const GlassMetroScheduleResults({
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
      title: 'NEXT METROS',
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
                  Icon(AppIcons.refresh, size: 16, color: g.textAlpha(0.5)),
                  const SizedBox(width: 4),
                  Text(
                    'Refresh',
                    style: TextStyle(fontSize: 11, color: g.textAlpha(0.5)),
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
              child: CupertinoActivityIndicator(color: g.textAlpha(0.7)),
            ),
          )
        else if (trains.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    AppIcons.directionsSubwayOutlined,
                    size: 40,
                    color: g.textAlpha(0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No more metros today',
                    style: TextStyle(color: g.textAlpha(0.5)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try swapping direction or check tomorrow',
                    style: TextStyle(fontSize: 12, color: g.textAlpha(0.3)),
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
