import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/app_icons.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class GlassMetroCitySelection extends StatelessWidget {
  final List<String> cities;
  final bool isLoading;
  final ValueChanged<String> onSelect;
  final Color accent;

  const GlassMetroCitySelection({
    super.key,
    required this.cities,
    required this.isLoading,
    required this.onSelect,
    required this.accent,
  });

  static const _cityIcons = <String, IconData>{
    'Delhi': AppIcons.accountBalance,
    'Mumbai': AppIcons.locationCity,
    'Bangalore': AppIcons.apartment,
    'Kolkata': AppIcons.templeHindu,
    'Chennai': AppIcons.templeBuddhist,
    'Hyderabad': AppIcons.mosque,
  };

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              'Choose your city',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: g.textAlpha(0.9),
              ),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cities.map((city) {
              return GestureDetector(
                onTap: () => onSelect(city),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: g.cardFill(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: g.border(0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _cityIcons[city] ?? AppIcons.locationCity,
                            size: 18,
                            color: accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            city,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: g.text,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
