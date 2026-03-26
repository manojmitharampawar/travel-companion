import 'package:flutter/material.dart';
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
  LocationPoint? _tentativeSelection; // Temp selection pending confirmation
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
    // Sync when parent changes the value externally (e.g., map picker, current location)
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
      
      // For metro and local train, search only stations
      if (widget.transportType == TransportType.metro) {
        final metroStations = await widget.stationRepository.searchMetroStations(query);
        stations = metroStations.map((s) => LocationPoint.fromStation(s)).toList();
      } else if (widget.transportType == TransportType.localTrain) {
        final localStations = await widget.stationRepository.searchLocalTrainStations(query);
        stations = localStations.map((s) => LocationPoint.fromStation(s)).toList();
      } else {
        // For bus and other types, search both stations and custom locations
        final foundStations = await widget.stationRepository.searchStations(query);
        stations = foundStations.map((s) => LocationPoint.fromStation(s)).toList();
      }

      // For bus, also include custom locations
      List<LocationPoint> customLocations = [];
      if (widget.transportType != TransportType.metro && 
          widget.transportType != TransportType.localTrain) {
        customLocations = await widget.locationRepository.searchLocations(query);
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
      // Don't immediately call onSelected - wait for confirmation
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
                color: isStation ? Colors.blue : Colors.red,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm selection?',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tentativeSelection!.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _discardTentativeSelection,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Change'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _confirmSelection(_tentativeSelection!),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Confirm'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.allowMapSelection && widget.onUseCurrentLocation != null)
                        IconButton(
                          icon: const Icon(Icons.my_location, size: 20),
                          tooltip: 'Use current location',
                          onPressed: widget.onUseCurrentLocation,
                        ),
                      if (widget.allowMapSelection && widget.onPickOnMap != null)
                        IconButton(
                          icon: const Icon(Icons.map, size: 20),
                          tooltip: 'Pick on map',
                          onPressed: widget.onPickOnMap,
                        ),
                      if (_selected != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
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
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
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
                          isStation ? Icons.train : Icons.location_on,
                          size: 20,
                          color: isStation ? Colors.blue : Colors.red,
                        ),
                        title: Text(
                          loc.displayName,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: loc.address != null
                            ? Text(
                                loc.address!,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () => _selectLocation(loc),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
