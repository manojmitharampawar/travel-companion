import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/app_theme.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/ui/ios_navigation_bar.dart';
import 'package:travel_companion/features/history/favorite_journeys_screen.dart';
import 'package:travel_companion/features/history/history_screen.dart';
import 'package:travel_companion/features/home/application/actions/home_journey_creation_action.dart';
import 'package:travel_companion/features/home/home_screen.dart';
import 'package:travel_companion/features/settings/settings_screen.dart';
import 'package:travel_companion/providers/app_providers.dart';

class TravelCompanionApp extends ConsumerWidget {
  const TravelCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final platformBrightness = View.of(
      context,
    ).platformDispatcher.platformBrightness;
    final brightness = AppTheme.resolveBrightness(
      themeMode: themeMode,
      platformBrightness: platformBrightness,
    );
    final cupertinoTheme = AppTheme.cupertinoTheme(brightness);

    return CupertinoApp(
      title: 'Travel Companion',
      debugShowCheckedModeBanner: false,
      theme: cupertinoTheme,
      builder: (context, child) {
        return CupertinoTheme(
          data: cupertinoTheme,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const GlassNavigationShell(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab controller that intercepts the Add-button pseudo-tab (index 2).
//
// When index 2 is set, the controller stays at the current real tab and
// fires [onAddTap] instead, so no content switch ever occurs.
// ─────────────────────────────────────────────────────────────────────────────

class _SafeTabController extends CupertinoTabController {
  final VoidCallback onAddTap;

  /// Prevents multiple sheets opening when the Add button is tapped rapidly.
  bool _sheetPending = false;

  _SafeTabController({required this.onAddTap}) : super(initialIndex: 0);

  @override
  set index(int newIndex) {
    if (newIndex == _kAddTabIndex) {
      // Guard: ignore the tap if a sheet is already opening or visible.
      if (_sheetPending) return;
      _sheetPending = true;
      // Immediately re-notify listeners so the tab bar redraws with the
      // current tab still selected (prevents the button looking "stuck").
      notifyListeners();
      onAddTap();
      return;
    }
    super.index = newIndex;
  }

  /// Call after the sheet is dismissed to re-enable the Add button.
  void clearSheetPending() => _sheetPending = false;
}

/// Virtual tab index reserved for the "Add Journey" action button.
const int _kAddTabIndex = 2;

// ─────────────────────────────────────────────────────────────────────────────
// Root navigation shell — CupertinoTabScaffold with glassmorphic tab bar
//
// Layout  : [Home] [Favourites] [╋ Add] [History] [Settings]  (5 visual slots)
// Style   : WhatsApp-style — icon-only (no labels), filled icons when active
// Height  : 48 dp content + system bottom inset
// Blur    : BackdropFilter σ=18 behind a transparent CupertinoTabBar
// ─────────────────────────────────────────────────────────────────────────────

class GlassNavigationShell extends ConsumerStatefulWidget {
  const GlassNavigationShell({super.key});

  @override
  ConsumerState<GlassNavigationShell> createState() =>
      _GlassNavigationShellState();
}

class _GlassNavigationShellState extends ConsumerState<GlassNavigationShell> {
  late final _SafeTabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = _SafeTabController(
      onAddTap: () async {
        await HomeJourneyCreationAction.show(context, ref);
        _tabController.clearSheetPending();
      },
    );
    // Listen for index changes to update the UI
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);

    // Build tab items for the iOS navigation bar
    final navItems = [
      IOSNavItem(
        label: 'Home',
        icon: CupertinoIcons.house,
        activeIcon: CupertinoIcons.house_fill,
      ),
      IOSNavItem(
        label: 'Saved',
        icon: CupertinoIcons.heart,
        activeIcon: CupertinoIcons.heart_fill,
      ),
      IOSNavItem(label: 'New', icon: CupertinoIcons.add),
      IOSNavItem(
        label: 'Trips',
        icon: CupertinoIcons.clock,
        activeIcon: CupertinoIcons.clock_fill,
      ),
      IOSNavItem(
        label: 'Settings',
        icon: CupertinoIcons.gear,
        activeIcon: CupertinoIcons.gear_solid,
      ),
    ];

    // Map tab index to content widgets
    final tabViews = [
      const HomeScreen(),
      const FavoriteJourneysScreen(),
      const HomeScreen(), // Fallback for Add
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return CupertinoPageScaffold(
      backgroundColor: g.bg,
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _tabController.index,
              children: tabViews,
            ),
          ),
          IOSGlassNavigationBar(
            items: navItems,
            selectedIndex: _tabController.index,
            onTabChanged: (index) {
              _tabController.index = index;
            },
            tintColor: g.accent,
          ),
        ],
      ),
    );
  }
}
