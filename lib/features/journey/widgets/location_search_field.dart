import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/data/repositories/location_repository.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/repositories/station_repository.dart';

class LocationSearchField extends StatefulWidget {
  final String label;
  final LocationPoint? initialValue;
  final ValueChanged<LocationPoint?> onSelected;
  final StationRepository stationRepository;
  final LocationRepository locationRepository;
  final VoidCallback? onPickOnMap;
  final VoidCallback? onUseCurrentLocation;

  /// Transport type for filtering stations (metro/local train only)
  final TransportType? transportType;

  /// Whether to show map and current location buttons
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
        final metroStations =
            await widget.stationRepository.searchMetroStations(query);
        stations =
            metroStations.map((s) => LocationPoint.fromStation(s)).toList();
      } else if (widget.transportType == TransportType.localTrain) {
        final localStations = await widget.stationRepository
            .searchLocalTrainStations(query);
        stations =
            localStations.map((s) => LocationPoint.fromStation(s)).toList();
      } else {
        final foundStations =
            await widget.stationRepository.searchStations(query);
        stations =
            foundStations.map((s) => LocationPoint.fromStation(s)).toList();
      }

      List<LocationPoint> customLocations = [];
      if (widget.transportType != TransportType.metro &&
          widget.transportType != TransportType.localTrain) {
        customLocations =
            await widget.locationRepository.searchLocations(query);
      }

      setState(() {
        _suggestions = [...customLocations.take(5), ...stations.take(15)];
        _showSuggestions = _suggestions.isNotEmpty;
      });
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) setState(() => _isSearching = false);
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
                isStation ? Icons.train : Icons.location_on,
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
              style: TextStyle(
                fontSize: 12,
                color: g.textAlpha(0.45),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: g.border(0.15)),
                  ),
                  child: TextButton(
                    onPressed: _discardTentativeSelection,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          g.textAlpha(0.7),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Change'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498DB),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3498DB)
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () =>
                        _confirmSelection(_tentativeSelection!),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Confirm'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          style: TextStyle(color: g.textAlpha(0.9)),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle:
                TextStyle(color: g.textAlpha(0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: g.border(0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: g.border(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: Color(0xFF3498DB), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFE74C3C)),
            ),
            errorStyle: const TextStyle(color: Color(0xFFE74C3C)),
            filled: true,
            fillColor: g.cardFill(0.06),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            suffixIcon: _isSearching
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: g.textAlpha(0.5),
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.allowMapSelection &&
                          widget.onUseCurrentLocation != null)
                        IconButton(
                          icon: Icon(Icons.my_location,
                              size: 20,
                              color: g.textAlpha(0.5)),
                          tooltip: 'Use current location',
                          onPressed: widget.onUseCurrentLocation,
                        ),
                      if (widget.allowMapSelection &&
                          widget.onPickOnMap != null)
                        IconButton(
                          icon: Icon(Icons.map,
                              size: 20,
                              color: g.textAlpha(0.5)),
                          tooltip: 'Pick on map',
                          onPressed: widget.onPickOnMap,
                        ),
                      if (_selected != null)
                        IconButton(
                          icon: Icon(Icons.clear,
                              size: 20,
                              color: g.textAlpha(0.5)),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _selected = null;
                              _tentativeSelection = null;
                              _suggestions = [];
                            });
                            widget.onSelected(null);
                          },
                        ),
                    ],
                  ),
          ),
          onChanged: _onSearchChanged,
          validator: (value) {
            if (_selected == null) {
              return 'Please select a location';
            }
            return null;
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
                  color: g.dropdownBg.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: g.border(0.1)),
                ),
                child: _tentativeSelection != null
                    ? _buildConfirmationUI(context)
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final loc = _suggestions[index];
                          final isStation = loc.stationCode != null;
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              isStation
                                  ? Icons.train
                                  : Icons.location_on,
                              size: 20,
                              color: isStation
                                  ? const Color(0xFF3498DB)
                                  : const Color(0xFFE74C3C),
                            ),
                            title: Text(
                              loc.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                color: g.textAlpha(0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: loc.address != null
                                ? Text(
                                    loc.address!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: g.textAlpha(0.4),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () => _selectLocation(loc),
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
