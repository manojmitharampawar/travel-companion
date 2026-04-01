import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/core/ui/adaptive_navigation.dart';
import 'package:travel_companion/core/services/geocoding_service.dart';
import 'package:travel_companion/core/services/routing_service.dart';
import 'package:travel_companion/core/services/tile_cache_service.dart';
import 'package:travel_companion/core/theme/app_icons.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/features/journey/bus/bus_journey_notifier.dart';
import 'package:travel_companion/features/journey/bus/bus_journey_state.dart';
import 'package:travel_companion/features/journey/bus/widgets/glass_action_chip.dart';
import 'package:travel_companion/features/journey/bus/widgets/glass_bus_detail_field.dart';
import 'package:travel_companion/features/journey/bus/widgets/glass_map_info_chip.dart';
import 'package:travel_companion/features/journey/bus/widgets/glass_offline_map_card.dart';
import 'package:travel_companion/features/journey/bus/widgets/route_marker.dart';
import 'package:travel_companion/features/journey/bus/widgets/glass_swap_button.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';
import 'package:travel_companion/features/map/bus_map_picker_screen.dart';

part 'widgets/_glass_bus_location_field.dart';
part 'widgets/_glass_bus_location_field_state.dart';
part 'widgets/_glass_bus_route_map_preview.dart';
part 'widgets/_glass_bus_route_map_preview_state.dart';


const _kTileUrl =
    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';
const _kDarkTileUrl =
    'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';

class AddBusJourneyScreen extends ConsumerStatefulWidget {
  const AddBusJourneyScreen({super.key});

  @override
  ConsumerState<AddBusJourneyScreen> createState() =>
      _AddBusJourneyScreenState();
}

class _AddBusJourneyScreenState extends ConsumerState<AddBusJourneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeCtrl = TextEditingController();
  final _operatorCtrl = TextEditingController();

  @override
  void dispose() {
    _routeCtrl.dispose();
    _operatorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(busJourneyNotifierProvider);
    final notifier = ref.read(busJourneyNotifierProvider.notifier);
    final g = GlassColors.of(context);
    final horizontalPadding = GlassLayout.horizontalPadding(context);
    final bottomPadding = GlassLayout.bottomContentPadding(context);
    final currentStep = _busFormStep(state);

    ref.listen<BusJourneyState>(busJourneyNotifierProvider, (prev, next) {
      if (next.savedSuccessfully) Navigator.pop(context, true);
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        AdaptiveFeedback.showToast(context, next.errorMessage!, isError: true);
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: g.bg,
      child: GlassMeshBackground(
        primaryColor: g.busAccent,
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: const TransportFormAppBar(
                  title: 'Bus Journey',
                  subtitle: 'Plan route and schedule',
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    0,
                  ),
                  child: CupertinoGlassStepper(
                    currentStep: currentStep,
                    accentColor: g.busAccent,
                    steps: const [
                      CupertinoGlassStep(title: 'Locations'),
                      CupertinoGlassStep(title: 'Route'),
                      CupertinoGlassStep(title: 'Schedule'),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  bottomPadding,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    GlassSectionCard(
                      title: 'Route',
                      icon: AppIcons.altRoute,
                      accentColor: g.busAccent,
                      children: [
                        _GlassBusLocationField(
                          label: 'Origin',
                          hint: 'Boarding stop or area',
                          icon: AppIcons.tripOrigin,
                          iconColor: g.originMarker,
                          value: state.origin,
                          isDetecting: state.isDetectingLocation,
                          onSelected: notifier.setOrigin,
                          onDetectGps: notifier.detectCurrentLocation,
                          onPickOnMap: () => _openMapPicker(
                            title: 'Origin',
                            current: state.origin,
                            onResult: notifier.setOrigin,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassSwapButton(
                          visible:
                              state.origin != null || state.destination != null,
                          accent: g.busAccent,
                          onTap: notifier.swapLocations,
                        ),
                        _GlassBusLocationField(
                          label: 'Destination',
                          hint: 'Destination stop or area',
                          icon: AppIcons.locationOn,
                          iconColor: g.destMarker,
                          value: state.destination,
                          onSelected: notifier.setDestination,
                          onPickOnMap: () => _openMapPicker(
                            title: 'Destination',
                            current: state.destination,
                            onResult: notifier.setDestination,
                          ),
                        ),
                      ],
                    ),
                    if (state.origin != null || state.destination != null)
                      GlassCard(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        padding: EdgeInsets.zero,
                        child: _GlassBusRouteMapPreview(
                          origin: state.origin,
                          destination: state.destination,
                          routeResult: state.routeResult,
                          isFetchingRoute: state.isFetchingRoute,
                        ),
                      ),
                    if (state.origin != null && state.destination != null)
                      GlassOfflineMapCard(
                        isCaching: state.isCachingTiles,
                        progress: state.tileCacheProgress,
                        isCached: state.tilesCached,
                        onDownload: notifier.downloadMapForOffline,
                      ),
                    GlassSectionCard(
                      title: 'Bus Details',
                      icon: AppIcons.directionsBus,
                      accentColor: g.busAccent,
                      children: [
                        GlassBusDetailField(
                          controller: _routeCtrl,
                          label: 'Route Number (optional)',
                          hintText: 'e.g. 500LTD, AC47',
                          icon: AppIcons.confirmationNumberOutlined,
                          accentColor: g.busAccent,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: notifier.setRouteNumber,
                        ),
                        fieldSpacing,
                        GlassBusDetailField(
                          controller: _operatorCtrl,
                          label: 'Operator / Service (optional)',
                          hintText: 'e.g. MSRTC, KSRTC, Volvo',
                          icon: AppIcons.businessOutlined,
                          accentColor: g.busAccent,
                          onChanged: notifier.setOperatorName,
                        ),
                      ],
                    ),
                    GlassSectionCard(
                      title: 'Schedule',
                      icon: AppIcons.schedule,
                      accentColor: g.busAccent,
                      children: [
                        JourneyDateField(
                          value: state.journeyDate,
                          onChanged: notifier.setJourneyDate,
                          accentColor: g.busAccent,
                        ),
                        fieldSpacing,
                        JourneyTimeField(
                          value: state.departureTime,
                          onChanged: notifier.setDepartureTime,
                          accentColor: g.busAccent,
                        ),
                      ],
                    ),
                    SaveJourneyButton(
                      isSaving: state.isSaving,
                      accentColor: g.busAccent,
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

  int _busFormStep(BusJourneyState state) {
    var step = 0;
    if (state.origin != null || state.destination != null) {
      step = 1;
    }
    if (state.origin != null &&
        state.destination != null &&
        (state.routeResult != null ||
            state.departureTime != null ||
            state.tilesCached)) {
      step = 2;
    }
    return step;
  }

  Future<void> _openMapPicker({
    required String title,
    required LocationPoint? current,
    required ValueChanged<LocationPoint?> onResult,
  }) async {
    final g = GlassColors.of(context);
    final result = await Navigator.push<LocationPoint>(
      context,
      adaptivePageRoute(
        BusMapPickerScreen(
          title: title,
          accentColor: g.busAccent,
          initialLocation: current,
        ),
      ),
    );
    if (result != null) {
      onResult(result);
    }
  }
}

