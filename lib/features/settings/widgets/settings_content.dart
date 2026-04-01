import 'package:flutter/cupertino.dart';
import 'package:travel_companion/features/settings/application/settings_controller.dart';
import 'package:travel_companion/features/settings/application/settings_state.dart';
import 'package:travel_companion/features/settings/widgets/sections/settings_about_section.dart';
import 'package:travel_companion/features/settings/widgets/sections/settings_appearance_section.dart';
import 'package:travel_companion/features/settings/widgets/sections/settings_map_section.dart';
import 'package:travel_companion/features/settings/widgets/sections/settings_notifications_section.dart';
import 'package:travel_companion/features/settings/widgets/sections/settings_permissions_section.dart';
import 'package:travel_companion/features/settings/widgets/sections/settings_tracking_section.dart';

class SettingsContent extends StatelessWidget {
  const SettingsContent({
    super.key,
    required this.state,
    required this.controller,
  });

  final SettingsState state;
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return Column(
      children: [
        SettingsNotificationsSection(state: state, controller: controller),
        SettingsTrackingSection(state: state, controller: controller),
        const SettingsAppearanceSection(),
        const SettingsMapSection(),
        const SettingsPermissionsSection(),
        const SettingsAboutSection(),
      ],
    );
  }
}
