import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/app_theme_mode.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/providers/app_providers.dart';

class SettingsThemeModeSelector extends ConsumerWidget {
  const SettingsThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);
    final g = GlassColors.of(context);
    final modes = const [
      (AppThemeMode.dark, CupertinoIcons.moon_fill),
      (AppThemeMode.light, CupertinoIcons.sun_max_fill),
      (AppThemeMode.system, CupertinoIcons.circle_lefthalf_fill),
    ];

    return Container(
      decoration: BoxDecoration(
        color: g.cardFill(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: g.border(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(modes.length, (index) {
          final (mode, icon) = modes[index];
          final isActive = currentMode == mode;
          final isFirst = index == 0;
          final isLast = index == modes.length - 1;

          return GestureDetector(
            onTap: () => ref.read(themeModeProvider.notifier).setMode(mode),
            child: Container(
              decoration: BoxDecoration(
                color: isActive
                    ? g.statusInfo.withValues(alpha: 0.15)
                    : const Color(0x00000000),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isFirst ? 10 : 0),
                  bottomLeft: Radius.circular(isFirst ? 10 : 0),
                  topRight: Radius.circular(isLast ? 10 : 0),
                  bottomRight: Radius.circular(isLast ? 10 : 0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isActive ? g.statusInfo : g.textTertiary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
