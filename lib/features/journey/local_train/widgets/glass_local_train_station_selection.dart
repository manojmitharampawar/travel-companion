import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/app_icons.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/local_train_schedule.dart';

class GlassLocalTrainStationSelection extends StatelessWidget {
  final List<LocalTrainStation> stations;
  final bool isLoading;
  final LocalTrainStation? sourceStation;
  final LocalTrainStation? destStation;
  final ValueChanged<LocalTrainStation?> onSourceChanged;
  final ValueChanged<LocalTrainStation?> onDestChanged;
  final VoidCallback onSwap;
  final Color accent;

  const GlassLocalTrainStationSelection({
    super.key,
    required this.stations,
    required this.isLoading,
    required this.sourceStation,
    required this.destStation,
    required this.onSourceChanged,
    required this.onDestChanged,
    required this.onSwap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: CupertinoActivityIndicator(color: g.loadingIndicator),
        ),
      );
    }

    final srcFiltered = destStation != null
        ? stations.where((s) => s.id != destStation!.id).toList()
        : stations;
    final dstFiltered = sourceStation != null
        ? stations.where((s) => s.id != sourceStation!.id).toList()
        : stations;

    return GlassSectionCard(
      title: 'SELECT STATIONS',
      icon: AppIcons.altRoute,
      accentColor: accent,
      children: [
        GlassPickerField<int>(
          label: 'From (Source)',
          placeholder: 'Select starting station',
          prefixIcon: AppIcons.tripOrigin,
          prefixIconColor: const Color(0xFF69F0AE),
          value: sourceStation?.id,
          enableSearch: true,
          allowClear: true,
          options: srcFiltered
              .map(
                (s) => GlassPickerOption<int>(
                  value: s.id,
                  label: s.name,
                  subtitle: s.code,
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id == null) return onSourceChanged(null);
            onSourceChanged(stations.firstWhere((s) => s.id == id));
          },
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: onSwap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Icon(AppIcons.swapVert, size: 20, color: accent),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GlassPickerField<int>(
          label: 'To (Destination)',
          placeholder: 'Where are you heading?',
          prefixIcon: AppIcons.place,
          prefixIconColor: const Color(0xFFFF8A80),
          value: destStation?.id,
          enableSearch: true,
          allowClear: true,
          options: dstFiltered
              .map(
                (s) => GlassPickerOption<int>(
                  value: s.id,
                  label: s.name,
                  subtitle: s.code,
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id == null) return onDestChanged(null);
            onDestChanged(stations.firstWhere((s) => s.id == id));
          },
        ),
      ],
    );
  }
}
