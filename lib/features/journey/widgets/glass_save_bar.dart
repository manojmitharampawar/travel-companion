import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class GlassSaveBar extends StatelessWidget {
  final Color accentColor;
  final bool isLoading;
  final bool isDisabled;
  final String label;
  final IconData icon;
  final VoidCallback onSave;

  const GlassSaveBar({
    super.key,
    required this.accentColor,
    required this.isLoading,
    this.isDisabled = false,
    this.label = 'Save Journey',
    this.icon = CupertinoIcons.checkmark_circle,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: g.bottomBarBg,
            border: Border(top: BorderSide(color: g.bottomBarBorder, width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: isLoading || isDisabled ? null : onSave,
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, color: CupertinoColors.white),
                              const SizedBox(width: 8),
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
