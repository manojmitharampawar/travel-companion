import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/station.dart';
import 'package:travel_companion/providers/app_providers.dart';

class GlassStationSearchField extends ConsumerStatefulWidget {
  final String label;
  final Station? selectedStation;
  final Color accentColor;
  final ValueChanged<Station> onSelected;

  const GlassStationSearchField({
    super.key,
    required this.label,
    required this.selectedStation,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  ConsumerState<GlassStationSearchField> createState() =>
      _GlassStationSearchFieldState();
}

class _GlassStationSearchFieldState
    extends ConsumerState<GlassStationSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<Station> _suggestions = [];
  bool _showSuggestions = false;
  bool _hasSelectedStation = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedStation != null) {
      _controller.text = widget.selectedStation!.displayName;
      _hasSelectedStation = true;
    }
  }

  @override
  void didUpdateWidget(GlassStationSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedStation != oldWidget.selectedStation &&
        widget.selectedStation != null) {
      _controller.text = widget.selectedStation!.displayName;
      _hasSelectedStation = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormField<bool>(
          validator: (_) =>
              _hasSelectedStation ? null : 'Please select a station',
          builder: (field) {
            final hasError = field.hasError;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    widget.label,
                    style: TextStyle(color: g.textSecondary, fontSize: 12),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: g.inputFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasError
                          ? const Color(0xFFE74C3C)
                          : (_focusNode.hasFocus
                                ? widget.accentColor
                                : g.inputBorder),
                      width: _focusNode.hasFocus ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 18,
                        color: widget.accentColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: const BoxDecoration(
                            color: Color(0x00000000),
                          ),
                          style: TextStyle(color: g.text),
                          placeholder: 'Search station',
                          placeholderStyle: TextStyle(color: g.textHint),
                          onChanged: (value) {
                            setState(() => _hasSelectedStation = false);
                            _onSearchChanged(value);
                          },
                        ),
                      ),
                      if (_controller.text.isNotEmpty)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(24, 24),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _hasSelectedStation = false;
                              _suggestions = [];
                              _showSuggestions = false;
                            });
                          },
                          child: Icon(
                            CupertinoIcons.clear_circled_solid,
                            size: 18,
                            color: g.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      field.errorText!,
                      style: const TextStyle(
                        color: Color(0xFFE74C3C),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: g.dropdownBg.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: g.border(0.1)),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final station = _suggestions[index];
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      minimumSize: Size.zero,
                      alignment: Alignment.centerLeft,
                      onPressed: () {
                        _controller.text = station.displayName;
                        widget.onSelected(station);
                        setState(() {
                          _hasSelectedStation = true;
                          _showSuggestions = false;
                          _suggestions = [];
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.tram_fill,
                            size: 18,
                            color: widget.accentColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  station.name,
                                  style: TextStyle(color: g.text, fontSize: 14),
                                ),
                                Text(
                                  station.code,
                                  style: TextStyle(
                                    color: g.textTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final stationRepo = ref.read(stationRepositoryProvider);
    final results = await stationRepo.searchStations(query);

    setState(() {
      _suggestions = results;
      _showSuggestions = true;
    });
  }
}
