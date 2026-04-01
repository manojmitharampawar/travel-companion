import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/features/history/widgets/history_glow_orb.dart';

class HistoryBackgroundOrbs extends StatelessWidget {
  const HistoryBackgroundOrbs({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GlassColors.of(context).bg,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            left: -60,
            child: HistoryGlowOrb(
              color: GlassColors.of(context).accent,
              size: 200,
            ),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: const HistoryGlowOrb(
              color: GlassConstants.meshPurple,
              size: 180,
            ),
          ),
          Positioned(
            top: 300,
            left: -30,
            child: const HistoryGlowOrb(
              color: GlassConstants.meshCyan,
              size: 130,
            ),
          ),
        ],
      ),
    );
  }
}
