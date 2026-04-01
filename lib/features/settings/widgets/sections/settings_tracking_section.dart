import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/features/settings/application/settings_controller.dart';
import 'package:travel_companion/features/settings/application/settings_state.dart';
import 'package:travel_companion/features/settings/widgets/settings_card.dart';
import 'package:travel_companion/features/settings/widgets/settings_divider.dart';
import 'package:travel_companion/features/settings/widgets/settings_item.dart';
import 'package:travel_companion/features/settings/widgets/settings_section_header.dart';

class SettingsTrackingSection extends StatelessWidget {
  const SettingsTrackingSection({
    super.key,
    required this.state,
    required this.controller,
  });

  final SettingsState state;
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final colors = GlassColors.of(context);

    return Column(
      children: [
        const SettingsSectionHeader(title: 'Journey Tracking'),
        SettingsCard(
          child: Column(
            children: [
              SettingsItem(
                icon: CupertinoIcons.location_solid,
                iconColor: const Color(0xFF27AE60),
                title: 'Auto-start tracking',
                subtitle:
                    'Automatically start GPS tracking near boarding station',
                trailing: CupertinoSwitch(
                  value: state.autoStartTracking,
                  onChanged: controller.setAutoStartTracking,
                  activeTrackColor: const Color(
                    0xFF27AE60,
                  ).withValues(alpha: 0.75),
                ),
              ),
              const SettingsDivider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: GlassPickerField<String>(
                  label: 'Alarm distance',
                  prefixIcon: CupertinoIcons.location,
                  prefixIconColor: colors.statusInfo,
                  value: state.alarmDistance,
                  options: const [
                    GlassPickerOption(value: '5', label: '5 km'),
                    GlassPickerOption(value: '10', label: '10 km'),
                    GlassPickerOption(value: '15', label: '15 km'),
                    GlassPickerOption(value: '20', label: '20 km'),
                    GlassPickerOption(value: '30', label: '30 km'),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.setAlarmDistance(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
