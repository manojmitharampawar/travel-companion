import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';

/// A tappable field that opens a glass bottom-sheet timeline of train stops.
class TrainStopSelector extends StatelessWidget {
  final String label;
  final IconData leadingIcon;
  final TrainRouteStop? selected;
  final List<TrainRouteStop> stops;
  final ValueChanged<TrainRouteStop> onChanged;
  final Color accentColor;
  final String? Function(TrainRouteStop?)? validator;
  final String? disabledHint;

  const TrainStopSelector({
    super.key,
    required this.label,
    required this.leadingIcon,
    required this.stops,
    required this.onChanged,
    this.selected,
    this.accentColor = const Color(0xFF1565C0),
    this.validator,
    this.disabledHint,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final isDisabled = stops.isEmpty;
    final displayText = selected?.displayLabel ??
        (isDisabled
            ? (disabledHint ?? 'Enter train number first')
            : 'Tap to select stop');

    final errorText = validator?.call(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: isDisabled ? null : () => _openSheet(context),
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(leadingIcon,
                  color: isDisabled
                      ? g.textAlpha(0.2)
                      : accentColor),
              suffixIcon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: isDisabled
                      ? g.textAlpha(0.2)
                      : accentColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: g.border(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: errorText != null
                      ? const Color(0xFFE74C3C)
                      : g.border(0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accentColor, width: 2),
              ),
              errorText: errorText,
              errorStyle: const TextStyle(color: Color(0xFFE74C3C)),
              filled: true,
              fillColor: isDisabled
                  ? g.cardFill(0.03)
                  : g.cardFill(0.06),
              labelStyle:
                  TextStyle(color: g.textAlpha(0.6)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            isEmpty: selected == null,
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 15,
                color: selected != null
                    ? g.textAlpha(0.9)
                    : g.textAlpha(0.35),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (stops.isNotEmpty && selected == null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              '${stops.length} stops on this route',
              style: TextStyle(
                fontSize: 11,
                color: accentColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  void _openSheet(BuildContext context) {
    showCupertinoModalPopup<TrainRouteStop>(
      context: context,
      builder: (_) => _GlassTrainStopSheet(
        label: label,
        stops: stops,
        selected: selected,
        accentColor: accentColor,
        onSelected: (stop) {
          Navigator.pop(context);
          onChanged(stop);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Bottom Sheet
// ─────────────────────────────────────────────

class _GlassTrainStopSheet extends StatefulWidget {
  final String label;
  final List<TrainRouteStop> stops;
  final TrainRouteStop? selected;
  final Color accentColor;
  final ValueChanged<TrainRouteStop> onSelected;

  const _GlassTrainStopSheet({
    required this.label,
    required this.stops,
    required this.selected,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  State<_GlassTrainStopSheet> createState() => _GlassTrainStopSheetState();
}

class _GlassTrainStopSheetState extends State<_GlassTrainStopSheet> {
  final _searchCtrl = TextEditingController();
  List<TrainRouteStop> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.stops;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.stops
          : widget.stops.where((s) {
              return s.stationName.toLowerCase().contains(q) ||
                  s.stationCode.toLowerCase().contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.82;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: g.bg.withValues(alpha: 0.92),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: g.border(0.15),
                width: 1.2,
              ),
              left: BorderSide(
                color: g.border(0.08),
              ),
              right: BorderSide(
                color: g.border(0.08),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle + Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: g.textAlpha(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.alt_route_rounded,
                            color: widget.accentColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Select ${widget.label}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: g.text,
                            ),
                          ),
                        ),
                        Text(
                          '${widget.stops.length} stops',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: false,
                  style: TextStyle(
                      color: g.textAlpha(0.9)),
                  decoration: glassInputDecoration(
                    labelText: 'Search station...',
                    hintText: 'Name or code',
                    prefixIcon: Icons.search,
                  ),
                ),
              ),
              Divider(
                height: 8,
                color: g.divider,
              ),

              // Stop List
              Flexible(
                child: _filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No stops match your search',
                          style: TextStyle(
                            color: g.textAlpha(0.4),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        padding: const EdgeInsets.only(bottom: 24),
                        itemBuilder: (_, i) {
                          final stop = _filtered[i];
                          final isFirst = stop.stopSequence ==
                              widget.stops.first.stopSequence;
                          final isLast = stop.stopSequence ==
                              widget.stops.last.stopSequence;
                          final isSelected = widget.selected?.stationCode ==
                              stop.stationCode;

                          return _GlassStopTile(
                            stop: stop,
                            isFirst: isFirst,
                            isLast: isLast,
                            isSelected: isSelected,
                            accentColor: widget.accentColor,
                            onTap: () => widget.onSelected(stop),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Stop Tile
// ─────────────────────────────────────────────

class _GlassStopTile extends StatelessWidget {
  final TrainRouteStop stop;
  final bool isFirst;
  final bool isLast;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _GlassStopTile({
    required this.stop,
    required this.isFirst,
    required this.isLast,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final dotColor = isFirst
        ? const Color(0xFF27AE60)
        : isLast
            ? const Color(0xFFE74C3C)
            : isSelected
                ? accentColor
                : g.textAlpha(0.25);

    final dotSize = (isFirst || isLast) ? 12.0 : 8.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isSelected ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline column
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    if (!isFirst)
                      Expanded(
                        flex: 1,
                        child: Container(
                          width: 2,
                          color: accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                    Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? accentColor : dotColor,
                        border: isSelected
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        flex: 1,
                        child: Container(
                          width: 2,
                          color: accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              stop.stationName,
                              style: TextStyle(
                                fontSize: isFirst || isLast ? 14 : 13,
                                fontWeight: isFirst || isLast || isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected
                                    ? accentColor
                                    : g.textAlpha(0.85),
                              ),
                            ),
                            Text(
                              stop.stationCode,
                              style: TextStyle(
                                fontSize: 11,
                                color: g.textAlpha(0.4),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (stop.timeDisplay.isNotEmpty)
                        Text(
                          stop.timeDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? accentColor
                                : g.textAlpha(0.5),
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.check_circle_rounded,
                              size: 18, color: accentColor),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
