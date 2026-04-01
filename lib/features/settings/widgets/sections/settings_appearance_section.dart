import 'package:flutter/cupertino.dart';
import 'package:travel_companion/features/settings/widgets/settings_card.dart';
import 'package:travel_companion/features/settings/widgets/settings_item.dart';
import 'package:travel_companion/features/settings/widgets/settings_section_header.dart';
import 'package:travel_companion/features/settings/widgets/settings_theme_mode_selector.dart';

class SettingsAppearanceSection extends StatelessWidget {
  const SettingsAppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SettingsSectionHeader(title: 'Appearance'),
        SettingsCard(
          child: SettingsItem(
            icon: CupertinoIcons.paintbrush_fill,
            iconColor: Color(0xFF9B59B6),
            title: 'App Theme',
            subtitle: 'Choose dark, light, or system default',
            trailing: SettingsThemeModeSelector(),
          ),
        ),
      ],
    );
  }
}
