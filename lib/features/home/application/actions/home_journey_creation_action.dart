import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/ui/adaptive_navigation.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/history/application/history_journey_queries.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/home/widgets/home_action_sheet_row.dart';
import 'package:travel_companion/features/journey/bus/add_bus_journey_screen.dart';
import 'package:travel_companion/features/journey/local_train/add_local_train_journey_screen.dart';
import 'package:travel_companion/features/journey/metro/add_metro_journey_screen.dart';
import 'package:travel_companion/features/journey/quick_trip_screen.dart';
import 'package:travel_companion/features/journey/train/add_train_journey_screen.dart';

class HomeJourneyCreationAction {
  const HomeJourneyCreationAction._();

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) {
        return CupertinoActionSheet(
          title: const Text('Add Journey'),
          message: const Text('Choose how you want to travel'),
          actions: [
            for (final type in TransportType.values)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(popupContext).pop();
                  _openJourneyForm(context, ref, type);
                },
                child: HomeActionSheetRow(
                  icon: type.icon,
                  color: type.color,
                  label: type.label,
                ),
              ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(popupContext).pop();
                _openQuickTrip(context, ref);
              },
              child: const HomeActionSheetRow(
                icon: CupertinoIcons.bolt_fill,
                color: Color(0xFF27AE60),
                label: 'Quick Trip',
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(popupContext).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  static Future<void> _openQuickTrip(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await Navigator.push(context, adaptivePageRoute(const QuickTripScreen()));
    _refreshHomeData(ref);
  }

  static Future<void> _openJourneyForm(
    BuildContext context,
    WidgetRef ref,
    TransportType type,
  ) async {
    final screen = switch (type) {
      TransportType.train => const AddTrainJourneyScreen(),
      TransportType.bus => const AddBusJourneyScreen(),
      TransportType.metro => const AddMetroJourneyScreen(),
      TransportType.localTrain => const AddLocalTrainJourneyScreen(),
    };

    final isCreated = await Navigator.push<bool>(
      context,
      adaptivePageRoute(screen),
    );

    if (isCreated == true) {
      _refreshHomeData(ref);
    }
  }

  static void _refreshHomeData(WidgetRef ref) {
    ref.invalidate(upcomingJourneysProvider);
    ref.invalidate(historyJourneysProvider);
  }
}
