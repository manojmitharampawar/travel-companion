import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/features/settings/application/actions/check_location_permission_action.dart';
import 'package:travel_companion/features/settings/widgets/settings_card.dart';
import 'package:travel_companion/features/settings/widgets/settings_item.dart';
import 'package:travel_companion/features/settings/widgets/settings_section_header.dart';
import 'package:travel_companion/features/settings/widgets/settings_small_button.dart';

class SettingsPermissionsSection extends StatelessWidget {
  const SettingsPermissionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = GlassColors.of(context);

    return Column(
      children: [
        const SettingsSectionHeader(title: 'Permissions'),
        SettingsCard(
          child: SettingsItem(
            icon: CupertinoIcons.location_fill,
            iconColor: const Color(0xFFE74C3C),
            title: 'Location Permission',
            subtitle: 'Required for journey tracking and alarms',
            trailing: SettingsSmallButton(
              label: 'Check',
              color: colors.statusInfo,
              onTap: () => CheckLocationPermissionAction.execute(context),
            ),
          ),
        ),
      ],
    );
  }
}
