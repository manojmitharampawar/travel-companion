import 'package:flutter/cupertino.dart';
import 'package:travel_companion/features/settings/widgets/settings_about_card.dart';
import 'package:travel_companion/features/settings/widgets/settings_card.dart';
import 'package:travel_companion/features/settings/widgets/settings_section_header.dart';

class SettingsAboutSection extends StatelessWidget {
  const SettingsAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SettingsSectionHeader(title: 'About'),
        SettingsCard(child: SettingsAboutCard()),
      ],
    );
  }
}
