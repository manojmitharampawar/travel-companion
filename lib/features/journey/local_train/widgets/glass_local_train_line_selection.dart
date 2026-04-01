import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/app_icons.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/local_train_line.dart';

class GlassLocalTrainLineSelection extends StatelessWidget {
  final List<LocalTrainLine> lines;
  final bool isLoading;
  final ValueChanged<LocalTrainLine> onSelect;
  final Color accent;

  const GlassLocalTrainLineSelection({
    super.key,
    required this.lines,
    required this.isLoading,
    required this.onSelect,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: CupertinoActivityIndicator(color: g.loadingIndicator),
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
              'Choose your line',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: g.text,
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
                        color: line.lineColor,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: line.lineColor.withValues(alpha: 0.5),
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
                          const SizedBox(height: 3),
                          Text(
                            '${line.startStation ?? ''} → ${line.endStation ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: g.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: line.lineColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: line.lineColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        line.lineCode,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: line.lineColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(AppIcons.chevronRight, color: g.textHint),
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
