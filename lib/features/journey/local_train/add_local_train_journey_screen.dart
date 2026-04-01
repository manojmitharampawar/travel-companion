import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/app_icons.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/features/journey/local_train/local_train_journey_notifier.dart';
import 'package:travel_companion/features/journey/local_train/local_train_journey_state.dart';
import 'package:travel_companion/features/journey/local_train/widgets/glass_local_train_line_selection.dart';
import 'package:travel_companion/features/journey/local_train/widgets/glass_local_train_schedule_results.dart';
import 'package:travel_companion/features/journey/local_train/widgets/glass_local_train_selected_line_chip.dart';
import 'package:travel_companion/features/journey/local_train/widgets/glass_local_train_station_selection.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';

class AddLocalTrainJourneyScreen extends ConsumerWidget {
  const AddLocalTrainJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = GlassColors.of(context);
    final accent = colors.localTrainAccent;
    final accentLight = colors.localTrainAccentLight;
    final state = ref.watch(localTrainJourneyNotifierProvider);
    final notifier = ref.read(localTrainJourneyNotifierProvider.notifier);
    final horizontalPadding = GlassLayout.horizontalPadding(context);
    final bottomPadding = GlassLayout.bottomContentPadding(context) + 80;

    ref.listen<LocalTrainJourneyState>(localTrainJourneyNotifierProvider, (
      prev,
      next,
    ) {
      if (next.savedSuccessfully) Navigator.pop(context, true);
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        AdaptiveFeedback.showToast(context, next.errorMessage!, isError: true);
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: colors.bg,
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
                            icon: TransportType.localTrain.icon,
                            title: 'Local Train Schedule',
                            subtitle: 'Find next trains & start tracking',
                          ),
                        ),
                        const TransportFormAppBar(
                          title: 'Local Train Schedule',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: CupertinoGlassStepper(
                  currentStep: state.currentStep,
                  accentColor: accent,
                  steps: const [
                    CupertinoGlassStep(title: 'Select Line'),
                    CupertinoGlassStep(title: 'Pick Stations'),
                    CupertinoGlassStep(title: 'Choose Train'),
                  ],
                  onStepChanged: (step) {
                    if (step == 0 && state.currentStep > 0) {
                      notifier.goBackToLineSelection();
                    } else if (step == 1 && state.currentStep > 1) {
                      notifier.goBackToStationSelection();
                    }
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(top: 12, bottom: bottomPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (state.currentStep == 0)
                    GlassLocalTrainLineSelection(
                      lines: state.availableLines,
                      isLoading: state.isLoadingLines,
                      onSelect: notifier.selectLine,
                      accent: accent,
                    ),
                  if (state.currentStep >= 1)
                    GlassLocalTrainSelectedLineChip(
                      line: state.selectedLine!,
                      onChangePressed: notifier.goBackToLineSelection,
                    ),
                  if (state.currentStep >= 1)
                    GlassLocalTrainStationSelection(
                      stations: state.lineStations,
                      isLoading: state.isLoadingStations,
                      sourceStation: state.sourceStation,
                      destStation: state.destStation,
                      onSourceChanged: notifier.setSourceStation,
                      onDestChanged: notifier.setDestStation,
                      onSwap: notifier.swapStations,
                      accent: accent,
                    ),
                  if (state.currentStep >= 2) ...[
                    GlassLocalTrainScheduleResults(
                      trains: state.upcomingTrains,
                      isLoading: state.isLoadingSchedule,
                      selectedTrain: state.selectedTrain,
                      onTrainSelected: notifier.selectTrain,
                      onRefresh: notifier.fetchUpcomingTrains,
                      accent: accent,
                    ),
                    if (state.selectedTrain != null) ...[
                      GlassSectionCard(
                        title: 'OPTIONS',
                        icon: AppIcons.tune,
                        accentColor: accent,
                        children: [
                          GlassPickerField<String>(
                            label: 'Class (optional)',
                            placeholder: 'Choose your coach',
                            prefixIcon:
                                AppIcons.airlineSeatReclineNormalOutlined,
                            prefixIconColor: GlassColors.of(
                              context,
                            ).textSecondary,
                            value:
                                (state.travelClass == null ||
                                    state.travelClass!.isEmpty)
                                ? null
                                : state.travelClass,
                            options: const [
                              GlassPickerOption(
                                value: 'FC',
                                label: 'First Class — FC',
                              ),
                              GlassPickerOption(
                                value: 'SC',
                                label: 'Second Class — SC',
                              ),
                              GlassPickerOption(
                                value: 'Ladies',
                                label: 'Ladies Coach',
                              ),
                              GlassPickerOption(
                                value: 'Divyang',
                                label: 'Divyang Coach',
                              ),
                            ],
                            onChanged: notifier.setTravelClass,
                          ),
                        ],
                      ),
                      GlassButton(
                        label: 'Start Journey & Track',
                        icon: AppIcons.playArrowRounded,
                        accentColor: accent,
                        isLoading: state.isSaving,
                        onPressed: notifier.save,
                      ),
                    ],
                  ],
                  SizedBox(height: GlassSpacing.xxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
