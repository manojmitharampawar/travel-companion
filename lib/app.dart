import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/app_theme.dart';
import 'package:travel_companion/features/home/home_screen.dart';
import 'package:travel_companion/providers/app_providers.dart';

class TravelCompanionApp extends ConsumerWidget {
  const TravelCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final platformBrightness = View.of(context).platformDispatcher.platformBrightness;
    final brightness = AppTheme.resolveBrightness(
      themeMode: themeMode,
      platformBrightness: platformBrightness,
    );
    final cupertinoTheme = AppTheme.cupertinoTheme(brightness);
    final materialTheme = AppTheme.materialCompatibilityTheme(brightness);

    return CupertinoApp(
      title: 'Travel Companion',
      debugShowCheckedModeBanner: false,
      theme: cupertinoTheme,
      builder: (context, child) {
        return CupertinoTheme(
          data: cupertinoTheme,
          child: material.Theme(
            data: materialTheme,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const HomeScreen(),
    );
  }
}
