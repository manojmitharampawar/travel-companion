import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/widgets/glass_info_tile.dart';
import 'package:travel_companion/features/journey/widgets/tile_data.dart';

class GlassInfoGrid extends StatelessWidget {
  final Journey journey;
  final TransportType type;

  const GlassInfoGrid({super.key, required this.journey, required this.type});

  @override
  Widget build(BuildContext context) {
    final tiles = <TileData>[
      TileData(CupertinoIcons.arrow_2_circlepath, type.label, 'Transport'),
      TileData(
        CupertinoIcons.calendar,
        AppDateUtils.relativeDay(journey.journeyDate),
        'Date',
      ),
      if (journey.scheduledTime != null)
        TileData(CupertinoIcons.time, journey.scheduledTime!, 'Departure'),
      if (journey.pnr != null)
        TileData(CupertinoIcons.ticket, journey.pnr!, 'PNR'),
      if (journey.travelClass != null)
        TileData(CupertinoIcons.person_2, journey.travelClass!, 'Class'),
      if (journey.berth != null)
        TileData(
          CupertinoIcons.square_grid_2x2,
          journey.berth!,
          'Berth / Seat',
        ),
      if (journey.isRepeating)
        TileData(CupertinoIcons.repeat, journey.repeatDaysDisplay, 'Repeats'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tiles
          .map((t) => GlassInfoTile(data: t, accentColor: type.color))
          .toList(),
    );
  }
}
