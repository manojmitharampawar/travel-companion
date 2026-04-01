import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// iOS-Style Navigation Bar with Subtle Glassmorphism
//
// A modern bottom navigation bar inspired by WhatsApp iOS with:
// - Semi-transparent frosted glass background (80–90% opacity)
// - Light blur effect (gaussian blur σ=10)
// - Soft elevation shadow for floating appearance
// - Animated selection indicator (rounded capsule)
// - Smooth transitions and interactions
// ─────────────────────────────────────────────────────────────────────────────

/// Callback signature for tab selection.
typedef OnTabChanged = void Function(int index);

/// Model for a single navigation tab.
class IOSNavItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;

  const IOSNavItem({required this.label, required this.icon, this.activeIcon});
}

/// iOS-style navigation bar with glassmorphism and animated selection.
class IOSGlassNavigationBar extends StatefulWidget {
  final List<IOSNavItem> items;
  final int selectedIndex;
  final OnTabChanged onTabChanged;
  final Color? tintColor;
  final double? height;
  final bool safeAreaPadding;

  const IOSGlassNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTabChanged,
    this.tintColor,
    this.height,
    this.safeAreaPadding = true,
  });

  @override
  State<IOSGlassNavigationBar> createState() => _IOSGlassNavigationBarState();
}

class _IOSGlassNavigationBarState extends State<IOSGlassNavigationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _indicatorController;
  late Animation<double> _indicatorPosition;

  double _normalizedIndex(int index) {
    final maxIndex = widget.items.length - 1;
    if (maxIndex <= 0) return 0.0;
    return index / maxIndex;
  }

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _indicatorPosition = AlwaysStoppedAnimation<double>(
      _normalizedIndex(widget.selectedIndex),
    );
  }

  @override
  void didUpdateWidget(IOSGlassNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _setupIndicatorAnimation(widget.selectedIndex);
    }
  }

  void _setupIndicatorAnimation(int newIndex) {
    final newPosition = _normalizedIndex(newIndex);

    _indicatorPosition =
        Tween<double>(
          begin: _indicatorPosition.value,
          end: newPosition,
        ).animate(
          CurvedAnimation(
            parent: _indicatorController,
            curve: Curves.easeInOut,
          ),
        );

    _indicatorController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final height = widget.height ?? 66.0;
    final tintColor = widget.tintColor ?? g.accent;

    Widget navBar = ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: g.bottomBarBg,
            border: Border(
              top: BorderSide(color: g.bottomBarBorder, width: 0.5),
            ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(
                    alpha: isDark(context) ? 0.15 : 0.08,
                  ),
                  blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth;
                  return Stack(
                    children: [
                      // Animated selection indicator (rounded capsule)
                      AnimatedBuilder(
                        animation: _indicatorPosition,
                        builder: (context, child) {
                          return Positioned(
                            left: _calculateIndicatorLeft(barWidth),
                            top: 8,
                            child: _SelectedTabIndicator(
                              width: _calculateIndicatorWidth(barWidth),
                              height: 44,
                              color: tintColor.withValues(alpha: 0.12),
                            ),
                          );
                        },
                      ),
                      // Tab items
                      Row(
                        children: List.generate(
                          widget.items.length,
                          (index) => Expanded(
                            child: _IOSNavBarItem(
                              item: widget.items[index],
                              isActive: index == widget.selectedIndex,
                              tintColor: tintColor,
                              onTap: () {
                                widget.onTabChanged(index);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    // Floating elevation effect using shadow
    navBar = Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(
              alpha: isDark(context) ? 0.1 : 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, -2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: navBar,
    );

    if (widget.safeAreaPadding) {
      navBar = SafeArea(top: false, child: navBar);
    }

    return navBar;
  }

  double _calculateIndicatorLeft(double barWidth) {
    final itemWidth = barWidth / widget.items.length;
    final activeSlot = _indicatorPosition.value * (widget.items.length - 1);
    final indicatorWidth = _calculateIndicatorWidth(barWidth);
    return (activeSlot * itemWidth) + ((itemWidth - indicatorWidth) / 2);
  }

  double _calculateIndicatorWidth(double barWidth) {
    final itemWidth = barWidth / widget.items.length;
    return itemWidth * 0.58;
  }

  bool isDark(BuildContext context) {
    return GlassColors.of(context).isDark;
  }
}

/// Single tab item in the navigation bar.
class _IOSNavBarItem extends StatelessWidget {
  final IOSNavItem item;
  final bool isActive;
  final Color tintColor;
  final VoidCallback onTap;

  const _IOSNavBarItem({
    required this.item,
    required this.isActive,
    required this.tintColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final iconColor = isActive ? tintColor : g.iconAlpha(0.6);
    final labelColor = isActive
        ? g.text.withValues(alpha: 0.95)
        : g.text.withValues(alpha: 0.6);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              isActive ? (item.activeIcon ?? item.icon) : item.icon,
              size: 22,
              color: iconColor,
            ),
            const SizedBox(height: 2),
            // Label
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: labelColor,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated selection indicator (rounded capsule behind active tab).
class _SelectedTabIndicator extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _SelectedTabIndicator({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          width: width + 1, // Slightly wider for better visual coverage
          height: height + 0.5, // Slightly taller for better visual coverage
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(
              color: GlassColors.of(context).border(0.08),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
