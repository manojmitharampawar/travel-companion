import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class SettingsAboutCard extends StatelessWidget {
  const SettingsAboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: g.statusInfo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.tram_fill,
                  size: 24,
                  color: g.statusInfo,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Travel Companion',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: g.textAlpha(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(fontSize: 12, color: g.textAlpha(0.4)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: g.statusInfo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: g.statusInfo.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'Never miss your stop again. Sleep worry-free with GPS-based arrival alerts.',
                  style: TextStyle(
                    fontSize: 13,
                    color: g.statusInfo.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
