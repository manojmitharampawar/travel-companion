import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/features/history/history_journeys_screen.dart';
import 'package:travel_companion/features/history/favorite_journeys_screen.dart';
import 'package:travel_companion/features/history/widgets/history_shared_widgets.dart';

/// Main History screen with tabbed interface.
///
/// SOLID-S: Single Responsibility - orchestrates tab container and delegates
/// content to HistoryJourneysScreen and FavoriteJourneysScreen.
///
/// Supports light/dark theme via GlassColors.of(context).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return DefaultTabController(
      length: 2,
      child: CupertinoPageScaffold(
        backgroundColor: g.bg,
        child: Stack(
          children: [
            // Background orbs
            const HistoryBackgroundOrbs(),

            // Content
            Column(
              children: [
                // Glass app bar with tabs
                _buildGlassAppBarWithTabs(context),

                // Tab body: delegate to separate screen components
                const Expanded(
                  child: TabBarView(
                    children: [
                      HistoryJourneysScreen(),
                      FavoriteJourneysScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassAppBarWithTabs(BuildContext context) {
    final g = GlassColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                g.accent.withValues(alpha: 0.5),
                g.bg.withValues(alpha: 0.9),
              ],
            ),
            border: Border(bottom: BorderSide(color: g.border(0.1))),
          ),
          child: Column(
            children: [
              SizedBox(height: topPad),
              // App bar row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: g.appBarForeground,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Journey History',
                        style: TextStyle(
                          color: g.appBarForeground,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tab bar
              TabBar(
                labelColor: g.appBarForeground,
                unselectedLabelColor: g.textAlpha(0.38),
                indicatorColor: const Color(0xFFFF9800),
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('History'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Favorites'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
