import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/data/repositories/location_repository.dart';
import 'package:travel_companion/data/repositories/station_repository.dart';

class LocationSearchField extends StatefulWidget {
  final String label;
  final LocationPoint? initialValue;
  final ValueChanged<LocationPoint?> onSelected;
  final StationRepository stationRepository;
  final LocationRepository locationRepository;
  final VoidCallback? onPickOnMap;
  final VoidCallback? onUseCurrentLocation;
  final TransportType? transportType;
  final bool allowMapSelection;

  const LocationSearchField({
    super.key,
    required this.label,
    this.initialValue,
    required this.onSelected,
    required this.stationRepository,
    required this.locationRepository,
    this.onPickOnMap,
    this.onUseCurrentLocation,
    this.transportType,
    this.allowMapSelection = true,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<LocationPoint> _suggestions = [];
  bool _showSuggestions = false;
  LocationPoint? _selected;
  LocationPoint? _tentativeSelection;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
    if (_selected != null) {
      _controller.text = _selected!.displayName;
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void didUpdateWidget(LocationSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _selected = widget.initialValue;
      _controller.text = _selected?.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      List<LocationPoint> stations = [];

      if (widget.transportType == TransportType.metro) {
        final metroStations = await widget.stationRepository
            .searchMetroStations(query);
        stations = metroStations.map(LocationPoint.fromStation).toList();
      } else if (widget.transportType == TransportType.localTrain) {
        final localStations = await widget.stationRepository
            .searchLocalTrainStations(query);
        stations = localStations.map(LocationPoint.fromStation).toList();
      } else {
        final foundStations = await widget.stationRepository.searchStations(
          query,
        );
        stations = foundStations.map(LocationPoint.fromStation).toList();
      }

      List<LocationPoint> customLocations = [];
      if (widget.transportType != TransportType.metro &&
          widget.transportType != TransportType.localTrain) {
        customLocations = await widget.locationRepository.searchLocations(
          query,
        );
      }

      setState(() {
        _suggestions = [...customLocations.take(5), ...stations.take(15)];
        _showSuggestions = _suggestions.isNotEmpty;
      });
    } catch (_) {
      // Keep UX silent on transient search errors.
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectLocation(LocationPoint location) {
    setState(() {
      _tentativeSelection = location;
    });
  }

  void _confirmSelection(LocationPoint location) {
    setState(() {
      _selected = location;
      _tentativeSelection = null;
      _controller.text = location.displayName;
      _showSuggestions = false;
    });
    _focusNode.unfocus();
    widget.onSelected(location);
  }

  void _discardTentativeSelection() {
    setState(() {
      _tentativeSelection = null;
      _showSuggestions = true;
    });
  }

  Widget _buildConfirmationUI(BuildContext context) {
    final g = GlassColors.of(context);
    final isStation = _tentativeSelection!.stationCode != null;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isStation
                    ? CupertinoIcons.train_style_one
                    : CupertinoIcons.location_solid,
                size: 24,
                color: isStation
                    ? const Color(0xFF3498DB)
                    : const Color(0xFFE74C3C),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm selection?',
                      style: TextStyle(
                        fontSize: 11,
                        color: g.textAlpha(0.45),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tentativeSelection!.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: g.textAlpha(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_tentativeSelection!.address != null) ...[
            const SizedBox(height: 8),
            Text(
              _tentativeSelection!.address!,
              style: TextStyle(fontSize: 12, color: g.textAlpha(0.45)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: g.textAlpha(0.08),
                  borderRadius: BorderRadius.circular(10),
                  onPressed: _discardTentativeSelection,
                  child: Text(
                    'Change',
                    style: TextStyle(color: g.textAlpha(0.7), fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: const Color(0xFF3498DB),
                  borderRadius: BorderRadius.circular(10),
                  onPressed: () => _confirmSelection(_tentativeSelection!),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormField<LocationPoint?>(
          initialValue: _selected,
          validator: (_) =>
              _selected == null ? 'Please select a location' : null,
          builder: (field) {
            final hasError = field.errorText != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: g.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: g.cardFill(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasError
                              ? const Color(0xFFE74C3C)
                              : g.border(0.15),
                        ),
                      ),
                      child: CupertinoTextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: TextStyle(color: g.textAlpha(0.9)),
                        placeholder: 'Search ${widget.label.toLowerCase()}',
                        placeholderStyle: TextStyle(color: g.textAlpha(0.45)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        suffix: _isSearching
                            ? Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CupertinoActivityIndicator(
                                    color: g.textAlpha(0.5),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.allowMapSelection &&
                                      widget.onUseCurrentLocation != null)
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      onPressed: widget.onUseCurrentLocation,
                                      child: Icon(
                                        CupertinoIcons.location_fill,
                                        size: 18,
                                        color: g.textAlpha(0.5),
                                      ),
                                    ),
                                  if (widget.allowMapSelection &&
                                      widget.onPickOnMap != null)
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      onPressed: widget.onPickOnMap,
                                      child: Icon(
                                        CupertinoIcons.map_pin_ellipse,
                                        size: 18,
                                        color: g.textAlpha(0.5),
                                      ),
                                    ),
                                  if (_selected != null)
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      onPressed: () {
                                        _controller.clear();
                                        setState(() {
                                          _selected = null;
                                          _tentativeSelection = null;
                                          _suggestions = [];
                                        });
                                        widget.onSelected(null);
                                        field.didChange(null);
                                      },
                                      child: Icon(
                                        CupertinoIcons.clear_circled_solid,
                                        size: 18,
                                        color: g.textAlpha(0.5),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                        decoration: null,
                        onChanged: (value) {
                          _onSearchChanged(value);
                          field.didChange(_selected);
                        },
                      ),
                    ),
                  ),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 2),
                    child: Text(
                      field.errorText!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFE74C3C),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (_showSuggestions || _tentativeSelection != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.08)
                      : CupertinoColors.white.withValues(alpha: 0.7),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CupertinoColors.white.withValues(
                        alpha: isDark ? 0.14 : 0.75,
                      ),
                      CupertinoColors.white.withValues(
                        alpha: isDark ? 0.04 : 0.5,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: g.border(0.18)),
                ),
                child: _tentativeSelection != null
                    ? _buildConfirmationUI(context)
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final loc = _suggestions[index];
                          final isStation = loc.stationCode != null;
                          return GestureDetector(
                            onTap: () => _selectLocation(loc),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: g.border(0.08),
                                    width: index == _suggestions.length - 1
                                        ? 0
                                        : 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isStation
                                        ? CupertinoIcons.train_style_one
                                        : CupertinoIcons.location_solid,
                                    size: 20,
                                    color: isStation
                                        ? const Color(0xFF3498DB)
                                        : const Color(0xFFE74C3C),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.displayName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: g.textAlpha(0.9),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (loc.address != null)
                                          Text(
                                            loc.address!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: g.textAlpha(0.45),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 12,
                                    color: g.textAlpha(0.35),
                                  ),
                                ],
                              ),
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
}
