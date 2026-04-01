import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/features/settings/widgets/settings_card.dart';
import 'package:travel_companion/features/settings/widgets/settings_divider.dart';
import 'package:travel_companion/features/settings/widgets/settings_item.dart';
import 'package:travel_companion/features/settings/widgets/settings_section_header.dart';
import 'package:travel_companion/providers/app_providers.dart';

class SettingsMapSection extends ConsumerWidget {
  const SettingsMapSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SettingsSectionHeader(title: 'Map'),
        SettingsCard(
          child: Column(
            children: [
              SettingsItem(
                icon: CupertinoIcons.layers_alt_fill,
                iconColor: const Color(0xFF1565C0),
                title: 'Railway Track Overlay',
                subtitle: 'Show OpenRailwayMap tracks on train journey map',
                trailing: CupertinoSwitch(
                  value: ref.watch(railwayOverlayProvider),
                  onChanged: (_) {
                    ref.read(railwayOverlayProvider.notifier).toggle();
                  },
                  activeTrackColor: const Color(
                    0xFF1565C0,
                  ).withValues(alpha: 0.75),
                ),
              ),
              const SettingsDivider(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Railway overlay uses OpenRailwayMap tiles (OpenStreetMap data). Requires internet and may use additional data.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
