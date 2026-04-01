import 'package:flutter/cupertino.dart';
import 'package:travel_companion/features/settings/application/settings_controller.dart';
import 'package:travel_companion/features/settings/application/settings_state.dart';
import 'package:travel_companion/features/settings/widgets/settings_card.dart';
import 'package:travel_companion/features/settings/widgets/settings_divider.dart';
import 'package:travel_companion/features/settings/widgets/settings_item.dart';
import 'package:travel_companion/features/settings/widgets/settings_section_header.dart';

class SettingsNotificationsSection extends StatelessWidget {
  const SettingsNotificationsSection({
    super.key,
    required this.state,
    required this.controller,
  });

  final SettingsState state;
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SettingsSectionHeader(title: 'Notifications'),
        SettingsCard(
          child: Column(
            children: [
              SettingsItem(
                icon: CupertinoIcons.bell_fill,
                iconColor: const Color(0xFFF39C12),
                title: 'Day before reminder',
                subtitle: 'Get notified 24 hours before your journey',
                trailing: CupertinoSwitch(
                  value: state.dayBeforeReminder,
                  onChanged: controller.setDayBeforeReminder,
                  activeTrackColor: const Color(
                    0xFFF39C12,
                  ).withValues(alpha: 0.75),
                ),
              ),
              const SettingsDivider(),
              SettingsItem(
                icon: CupertinoIcons.bell,
                iconColor: const Color(0xFF9B59B6),
                title: 'Hours before reminder',
                subtitle: 'Get notified 3 hours before departure',
                trailing: CupertinoSwitch(
                  value: state.hoursBeforeReminder,
                  onChanged: controller.setHoursBeforeReminder,
                  activeTrackColor: const Color(
                    0xFF9B59B6,
                  ).withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
