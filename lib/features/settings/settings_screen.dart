import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/features/settings/settings_providers.dart';
import 'package:travel_companion/features/settings/widgets/settings_content.dart';
import 'package:travel_companion/features/settings/widgets/settings_page_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = GlassColors.of(context);
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final horizontal = GlassLayout.horizontalPadding(context);
    final bottomPadding = GlassLayout.bottomContentPadding(context);

    return CupertinoPageScaffold(
      backgroundColor: colors.bg,
      child: GlassMeshBackground(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SettingsPageHeader()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                0,
                horizontal,
                bottomPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: SettingsContent(state: state, controller: controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
