import 'package:flutter/material.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';

/// A tappable field that opens a bottom-sheet timeline of train stops.
/// Used in AddTrainJourneyScreen once the train number is resolved.
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
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(leadingIcon,
                  color: isDisabled ? Colors.grey.shade400 : accentColor),
              suffixIcon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: isDisabled ? Colors.grey.shade400 : accentColor),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: errorText != null
                      ? Colors.red.shade600
                      : Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 2),
              ),
              errorText: errorText,
              filled: isDisabled,
              fillColor:
                  isDisabled ? Colors.grey.shade50 : Colors.transparent,
            ),
            isEmpty: selected == null,
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 15,
                color: selected != null
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.grey.shade500,
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
                  fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<TrainRouteStop>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrainStopSheet(
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
// Bottom Sheet
// ─────────────────────────────────────────────

class _TrainStopSheet extends StatefulWidget {
  final String label;
  final List<TrainRouteStop> stops;
  final TrainRouteStop? selected;
  final Color accentColor;
  final ValueChanged<TrainRouteStop> onSelected;

  const _TrainStopSheet({
    required this.label,
    required this.stops,
    required this.selected,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  State<_TrainStopSheet> createState() => _TrainStopSheetState();
}

class _TrainStopSheetState extends State<_TrainStopSheet> {
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
    final maxHeight = MediaQuery.of(context).size.height * 0.82;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle + Title ─────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
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
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${widget.stops.length} stops',
                      style: TextStyle(
                          fontSize: 12,
                          color: widget.accentColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Search field ─────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Search station name or code...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: widget.accentColor, width: 1.5),
                ),
              ),
            ),
          ),
          const Divider(height: 8),

          // ── Stop List ────────────────────
          Flexible(
            child: _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('No stops match your search',
                        style: TextStyle(color: Colors.grey.shade500)),
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
                      final isSelected =
                          widget.selected?.stationCode == stop.stationCode;

                      return _StopTile(
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
    );
  }
}

// ─────────────────────────────────────────────
// Individual Stop Tile with timeline connector
// ─────────────────────────────────────────────

class _StopTile extends StatelessWidget {
  final TrainRouteStop stop;
  final bool isFirst;
  final bool isLast;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _StopTile({
    required this.stop,
    required this.isFirst,
    required this.isLast,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isFirst
        ? Colors.green.shade600
        : isLast
            ? Colors.red.shade600
            : isSelected
                ? accentColor
                : Colors.grey.shade400;

    final dotSize = (isFirst || isLast) ? 12.0 : 8.0;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isSelected ? accentColor.withValues(alpha: 0.06) : null,
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
                            ? Border.all(color: Colors.white, width: 2)
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
                                color: isSelected ? accentColor : null,
                              ),
                            ),
                            Text(
                              stop.stationCode,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
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
                                : Colors.grey.shade600,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
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
