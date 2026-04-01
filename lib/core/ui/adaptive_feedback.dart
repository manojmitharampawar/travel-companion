import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class AdaptiveFeedback {
  AdaptiveFeedback._();

  static void showToast(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final g = GlassColors.of(context);
    final background = isError
        ? const Color(0xFFE74C3C)
        : const Color(0xFF27AE60);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 16,
        right: 16,
        bottom: MediaQuery.paddingOf(ctx).bottom + 24,
        child: IgnorePointer(
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: g.border(0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    unawaited(Future<void>.delayed(duration, entry.remove));
  }
}
