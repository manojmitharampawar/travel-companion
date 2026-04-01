import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/app_icons.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class GlassOfflineMapCard extends StatelessWidget {
  const GlassOfflineMapCard({
    super.key,
    required this.isCaching,
    required this.progress,
    required this.isCached,
    required this.onDownload,
  });

  final bool isCaching;
  final int progress;
  final bool isCached;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isCached
                  ? g.busAccent.withValues(alpha: 0.1)
                  : g.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCached
                    ? g.busAccent.withValues(alpha: 0.25)
                    : g.inputBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCached
                        ? g.busAccent.withValues(alpha: 0.15)
                        : g.cardFill(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCached
                        ? AppIcons.offlinePinRounded
                        : AppIcons.cloudDownloadOutlined,
                    size: 20,
                    color: isCached ? g.busAccent : g.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCached
                            ? 'Map saved for offline'
                            : isCaching
                            ? 'Downloading map tiles...'
                            : 'Save map for offline use',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCached ? g.busAccent : g.textAlpha(0.8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (isCaching)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 4,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(color: g.border(0.1)),
                                ),
                                FractionallySizedBox(
                                  widthFactor: (progress / 100).clamp(0, 1),
                                  alignment: Alignment.centerLeft,
                                  child: Container(color: g.busAccent),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Text(
                          isCached
                              ? 'Route map available without internet'
                              : 'Download route tiles for journey tracking',
                          style: TextStyle(fontSize: 11, color: g.textTertiary),
                        ),
                    ],
                  ),
                ),
                if (!isCached && !isCaching)
                  GestureDetector(
                    onTap: onDownload,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: g.busAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: g.busAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Download',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: g.busAccent,
                        ),
                      ),
                    ),
                  ),
                if (isCaching)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '$progress%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: g.busAccent,
                      ),
                    ),
                  ),
                if (isCached)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      AppIcons.checkCircleRounded,
                      size: 20,
                      color: g.busAccent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
