import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/app_icons.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/metro_line.dart';

class GlassMetroLineSelection extends StatelessWidget {
  final List<MetroLine> lines;
  final bool isLoading;
  final ValueChanged<MetroLine> onSelect;

  const GlassMetroLineSelection({
    super.key,
    required this.lines,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: CupertinoActivityIndicator(color: g.textAlpha(0.7)),
        ),
      );
    }

    if (lines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No metro lines available',
            style: TextStyle(color: g.textAlpha(0.5)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              'Select metro line',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: g.textAlpha(0.9),
              ),
            ),
          ),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16),
                onTap: () => onSelect(line),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 44,
                      decoration: BoxDecoration(
                        color: line.color,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: line.color.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.lineName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: g.text,
                            ),
                          ),
                          if (line.lineCode != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              line.lineCode!,
                              style: TextStyle(
                                fontSize: 12,
                                color: g.textAlpha(0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: line.color.withValues(alpha: 0.2),
                      ),
                      child: Icon(
                        AppIcons.directionsSubway,
                        size: 16,
                        color: line.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(AppIcons.chevronRight, color: g.textAlpha(0.3)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
