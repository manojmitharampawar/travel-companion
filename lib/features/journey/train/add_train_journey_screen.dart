import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/train/train_journey_notifier.dart';
import 'package:travel_companion/features/journey/train/train_journey_state.dart';
import 'package:travel_companion/features/journey/train/widgets/glass_train_route_loaded_banner.dart';
import 'package:travel_companion/features/journey/train/widgets/glass_train_route_preview.dart';
import 'package:travel_companion/features/journey/train/widgets/train_route_connector.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';
import 'package:travel_companion/core/theme/app_icons.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/features/journey/widgets/train_stop_selector.dart';

class AddTrainJourneyScreen extends ConsumerStatefulWidget {
  const AddTrainJourneyScreen({super.key});

  @override
  ConsumerState<AddTrainJourneyScreen> createState() =>
      _AddTrainJourneyScreenState();
}

class _AddTrainJourneyScreenState extends ConsumerState<AddTrainJourneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pnrCtrl = TextEditingController();
  final _trainNumCtrl = TextEditingController();
  final _trainNameCtrl = TextEditingController();
  final _berthCtrl = TextEditingController();

  @override
  void dispose() {
    _pnrCtrl.dispose();
    _trainNumCtrl.dispose();
    _trainNameCtrl.dispose();
    _berthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final accent = g.trainAccent;
    final horizontalPadding = GlassLayout.horizontalPadding(context);
    final bottomPadding = GlassLayout.bottomContentPadding(context);
    final state = ref.watch(trainJourneyNotifierProvider);
    final currentStep = _trainFormStep(state);
    final notifier = ref.read(trainJourneyNotifierProvider.notifier);
    final hasRouteStops = state.trainRouteStops.isNotEmpty;

    ref.listen<TrainJourneyState>(trainJourneyNotifierProvider, (prev, next) {
      if (prev?.trainName != next.trainName && next.trainName.isNotEmpty) {
        _trainNameCtrl.text = next.trainName;
      }
      if (next.savedSuccessfully) {
        Navigator.pop(context, true);
      }
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        AdaptiveFeedback.showToast(context, next.errorMessage!, isError: true);
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: g.bg,
      child: GlassMeshBackground(
        primaryColor: accent,
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _heroHeight(context),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GlassAppBarHero(
                          primaryColor: accent,
                          icon: TransportType.train.icon,
                          title: 'Add Train Journey',
                          subtitle:
                              'PNR autofill, real-time station lookups & alerts',
                        ),
                      ),
                      const TransportFormAppBar(title: 'Train Journey'),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: CupertinoGlassStepper(
                    currentStep: currentStep,
                    accentColor: accent,
                    steps: const [
                      CupertinoGlassStep(title: 'Train'),
                      CupertinoGlassStep(title: 'Route'),
                      CupertinoGlassStep(title: 'Schedule'),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    GlassSectionCard(
                      title: 'Train Details',
                      icon: AppIcons.train,
                      accentColor: accent,
                      children: [
                        GlassCupertinoTextFormField(
                          controller: _pnrCtrl,
                          labelText: 'PNR Number (optional)',
                          hintText: '10-digit PNR',
                          prefixIcon: AppIcons.confirmationNumberOutlined,
                          helperText: 'Auto-detected from SMS if available',
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          onChanged: notifier.setPnr,
                        ),
                        fieldSpacing,
                        GlassCupertinoTextFormField(
                          controller: _trainNumCtrl,
                          labelText: 'Train Number *',
                          hintText: 'e.g. 12301',
                          prefixIcon: AppIcons.pinOutlined,
                          helperText: 'Name and route auto-fill from number',
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          suffix: state.isAutoFilling
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CupertinoActivityIndicator(
                                      radius: 8,
                                      color: GlassColors.of(
                                        context,
                                      ).textSecondary,
                                    ),
                                  ),
                                )
                              : null,
                          onChanged: notifier.setTrainNumber,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Train number is required';
                            }
                            if (v.length < 4) {
                              return 'Enter a valid 4-5 digit number';
                            }
                            return null;
                          },
                        ),
                        fieldSpacing,
                        GlassCupertinoTextFormField(
                          controller: _trainNameCtrl,
                          labelText: 'Train Name (optional)',
                          hintText: 'e.g. Rajdhani Express',
                          prefixIcon: AppIcons.labelOutline,
                          onChanged: notifier.setTrainName,
                        ),
                        if (hasRouteStops) ...[
                          const SizedBox(height: 12),
                          GlassTrainRouteLoadedBanner(
                            stopCount: state.trainRouteStops.length,
                            trainName: state.trainName,
                            accentColor: accent,
                          ),
                        ],
                      ],
                    ),
                    GlassSectionCard(
                      title: 'Journey Route',
                      icon: AppIcons.altRoute,
                      accentColor: accent,
                      children: [
                        if (hasRouteStops)
                          TrainStopSelector(
                            label: 'Boarding Station *',
                            leadingIcon: AppIcons.tripOrigin,
                            stops: state.trainRouteStops,
                            selected: _findStop(
                              state.trainRouteStops,
                              state.boardingStation?.code,
                            ),
                            onChanged: notifier.selectBoardingStop,
                            accentColor: accent,
                            validator: (_) => state.boardingStation == null
                                ? 'Select boarding station'
                                : null,
                          )
                        else
                          StationAutocompleteField(
                            label: 'Boarding Station *',
                            hint: 'Search by name or code',
                            leadingIcon: AppIcons.tripOrigin,
                            selected: state.boardingStation,
                            searchFn: notifier.searchStations,
                            onChanged: notifier.setBoardingStation,
                            accentColor: accent,
                            validator: (s) =>
                                s == null ? 'Select boarding station' : null,
                          ),
                        const SizedBox(height: 10),
                        TrainRouteConnector(accent: accent),
                        const SizedBox(height: 10),
                        if (hasRouteStops)
                          TrainStopSelector(
                            label: 'Destination Station *',
                            leadingIcon: AppIcons.place,
                            stops: state.destinationStops,
                            selected: _findStop(
                              state.trainRouteStops,
                              state.destinationStation?.code,
                            ),
                            onChanged: notifier.selectDestinationStop,
                            accentColor: accent,
                            disabledHint: 'Select boarding station first',
                            validator: (_) => state.destinationStation == null
                                ? 'Select destination station'
                                : null,
                          )
                        else
                          StationAutocompleteField(
                            label: 'Destination Station *',
                            hint: 'Search by name or code',
                            leadingIcon: AppIcons.place,
                            selected: state.destinationStation,
                            searchFn: notifier.searchStations,
                            onChanged: notifier.setDestinationStation,
                            accentColor: accent,
                            validator: (s) =>
                                s == null ? 'Select destination station' : null,
                          ),
                      ],
                    ),
                    if (state.boardingStation != null &&
                        state.destinationStation != null &&
                        state.boardingStation!.latitude != 0 &&
                        state.destinationStation!.latitude != 0)
                      GlassTrainRoutePreview(
                        stops: state.trainRouteStops,
                        boardingCode: state.boardingStation!.code,
                        destinationCode: state.destinationStation!.code,
                        accentColor: accent,
                      ),
                    GlassSectionCard(
                      title: 'Journey Info',
                      icon: AppIcons.infoOutline,
                      accentColor: accent,
                      children: [
                        JourneyDateField(
                          value: state.journeyDate,
                          onChanged: notifier.setJourneyDate,
                          accentColor: accent,
                        ),
                        fieldSpacing,
                        GlassPickerField<String>(
                          label: 'Travel Class (optional)',
                          placeholder: 'Select class',
                          prefixIcon: AppIcons.airlineSeatReclineNormalOutlined,
                          value: state.travelClass?.isEmpty ?? true
                              ? null
                              : state.travelClass,
                          enableSearch: true,
                          allowClear: true,
                          options: const [
                            GlassPickerOption(
                              value: 'SL',
                              label: 'Sleeper — SL',
                            ),
                            GlassPickerOption(
                              value: '3A',
                              label: 'AC 3 Tier — 3A',
                            ),
                            GlassPickerOption(
                              value: '2A',
                              label: 'AC 2 Tier — 2A',
                            ),
                            GlassPickerOption(
                              value: '1A',
                              label: 'First AC — 1A',
                            ),
                            GlassPickerOption(
                              value: '3E',
                              label: 'AC Economy — 3E',
                            ),
                            GlassPickerOption(
                              value: 'CC',
                              label: 'Chair Car — CC',
                            ),
                            GlassPickerOption(
                              value: 'EC',
                              label: 'Exec Chair — EC',
                            ),
                            GlassPickerOption(
                              value: '2S',
                              label: 'Second Sitting — 2S',
                            ),
                          ],
                          onChanged: notifier.setTravelClass,
                        ),
                        fieldSpacing,
                        GlassCupertinoTextFormField(
                          controller: _berthCtrl,
                          labelText: 'Berth / Seat (optional)',
                          hintText: 'e.g. S5/32/SU',
                          prefixIcon: AppIcons.eventSeatOutlined,
                          onChanged: notifier.setBerth,
                        ),
                      ],
                    ),
                    SaveJourneyButton(
                      isSaving: state.isSaving,
                      accentColor: accent,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          notifier.save();
                        }
                      },
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TrainRouteStop? _findStop(List<TrainRouteStop> stops, String? code) {
    if (code == null) return null;
    try {
      return stops.firstWhere((s) => s.stationCode == code);
    } catch (_) {
      return null;
    }
  }

  double _heroHeight(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return topPad + 150;
  }

  int _trainFormStep(TrainJourneyState state) {
    var step = 0;
    if (state.trainRouteStops.isNotEmpty || state.boardingStation != null) {
      step = 1;
    }
    if (state.boardingStation != null && state.destinationStation != null) {
      step = 2;
    }
    return step;
  }
}
