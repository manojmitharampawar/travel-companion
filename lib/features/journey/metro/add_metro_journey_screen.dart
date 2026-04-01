import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/core/theme/app_icons.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/metro/metro_journey_notifier.dart';
import 'package:travel_companion/features/journey/metro/metro_journey_state.dart';
import 'package:travel_companion/features/journey/metro/widgets/glass_metro_city_selection.dart';
import 'package:travel_companion/features/journey/metro/widgets/glass_metro_line_selection.dart';
import 'package:travel_companion/features/journey/metro/widgets/glass_metro_schedule_results.dart';
import 'package:travel_companion/features/journey/metro/widgets/glass_metro_selected_chip.dart';
import 'package:travel_companion/features/journey/metro/widgets/glass_metro_selected_line_chip.dart';
import 'package:travel_companion/features/journey/metro/widgets/glass_metro_station_selection.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';

class AddMetroJourneyScreen extends ConsumerWidget {
  const AddMetroJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = GlassColors.of(context);
    final accent = g.metroAccent;
    final accentLight = g.metroAccentLight;
    final state = ref.watch(metroJourneyNotifierProvider);
    final notifier = ref.read(metroJourneyNotifierProvider.notifier);
    ref.listen<MetroJourneyState>(metroJourneyNotifierProvider, (prev, next) {
      if (next.savedSuccessfully) Navigator.pop(context, true);
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        AdaptiveFeedback.showToast(context, next.errorMessage!, isError: true);
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: GlassColors.of(context).bg,
      child: GlassMeshBackground(
        primaryColor: accent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Builder(
                builder: (ctx) {
                  final topPad = MediaQuery.paddingOf(ctx).top;
                  final height = topPad + 44 + 80;
                  return SizedBox(
                    height: height,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GlassAppBarHero(
                            primaryColor: accent,
                            secondaryColor: accentLight,
                            icon: TransportType.metro.icon,
                            title: 'Metro Schedule',
                            subtitle: 'Find next metro & start tracking',
                          ),
                        ),
                        const TransportFormAppBar(title: 'Metro Schedule'),
                      ],
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: CupertinoGlassStepper(
                currentStep: state.currentStep,
                accentColor: accent,
                steps: const [
                  CupertinoGlassStep(title: 'City'),
                  CupertinoGlassStep(title: 'Line'),
                  CupertinoGlassStep(title: 'Stations'),
                  CupertinoGlassStep(title: 'Schedule'),
                ],
                onStepChanged: (step) {
                  if (step == 0 && state.currentStep > 0) {
                    notifier.goBackToCitySelection();
                  } else if (step == 1 && state.currentStep > 1) {
                    notifier.goBackToLineSelection();
                  }
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (state.currentStep == 0)
                    GlassMetroCitySelection(
                      cities: state.availableCities,
                      isLoading: state.isLoadingCities,
                      onSelect: notifier.setCity,
                      accent: accent,
                    ),
                  if (state.currentStep >= 1)
                    GlassMetroSelectedChip(
                      icon: AppIcons.locationCity,
                      label: state.city,
                      color: accent,
                      onChangePressed: notifier.goBackToCitySelection,
                    ),
                  if (state.currentStep == 1)
                    GlassMetroLineSelection(
                      lines: state.availableLines,
                      isLoading: state.isLoadingLines,
                      onSelect: notifier.selectLine,
                    ),
                  if (state.currentStep >= 2)
                    GlassMetroSelectedLineChip(
                      line: state.selectedLine!,
                      onChangePressed: notifier.goBackToLineSelection,
                    ),
                  if (state.currentStep >= 2)
                    GlassMetroStationSelection(
                      stations: state.stationsOnLine,
                      isLoading: state.isLoadingStations,
                      sourceStation: state.sourceStation,
                      destStation: state.destStation,
                      onSourceChanged: notifier.setSourceStation,
                      onDestChanged: notifier.setDestStation,
                      onSwap: notifier.swapStations,
                      accent: accent,
                    ),
                  if (state.currentStep >= 3) ...[
                    GlassMetroScheduleResults(
                      trains: state.upcomingTrains,
                      isLoading: state.isLoadingSchedule,
                      selectedTrain: state.selectedTrain,
                      onTrainSelected: notifier.selectTrain,
                      onRefresh: notifier.fetchUpcomingTrains,
                      accent: accent,
                    ),
                    if (state.selectedTrain != null)
                      GlassButton(
                        label: 'Start Journey & Track',
                        icon: AppIcons.playArrowRounded,
                        accentColor: accent,
                        isLoading: state.isSaving,
                        onPressed: notifier.save,
                      ),
                  ],
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
