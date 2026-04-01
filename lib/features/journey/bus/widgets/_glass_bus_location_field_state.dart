part of '../add_bus_journey_screen.dart';

class _GlassBusLocationFieldState extends State<_GlassBusLocationField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<LocationPoint> _results = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _controller.text = widget.value!.name;
    }
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(_GlassBusLocationField old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) {
      _controller.text = widget.value?.name ?? '';
      if (widget.value != null) _removeOverlay();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) _removeOverlay();
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      _removeOverlay();
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _updateOverlay();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final res = await GeocodingService.search(query);
        if (mounted) {
          setState(() {
            _results = res;
            _isSearching = false;
          });
          if (res.isNotEmpty) {
            _updateOverlay();
          } else {
            _showNoResultsOverlay();
          }
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isSearching = false);
          _removeOverlay();
        }
      }
    });
  }

  void _selectResult(LocationPoint point) {
    _controller.text = point.name;
    _focusNode.unfocus();
    _removeOverlay();
    setState(() {
      _results = [];
      _isSearching = false;
    });
    widget.onSelected(point);
  }

  void _clear() {
    _controller.clear();
    _removeOverlay();
    setState(() {
      _results = [];
      _isSearching = false;
    });
    widget.onSelected(null);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final fieldWidth = renderBox.size.width;
    final g = GlassColors.of(context);
    final isDark = g.isDark;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        width: fieldWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 62),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280),
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
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: g.border(0.18)),
                ),
                child: _isSearching && _results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CupertinoActivityIndicator(
                                radius: 8,
                                color: g.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Searching...',
                              style: TextStyle(
                                color: g.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => Container(
                          margin: const EdgeInsets.only(left: 56, right: 16),
                          height: 1,
                          color: g.divider,
                        ),
                        itemBuilder: (_, i) {
                          final p = _results[i];
                          return GestureDetector(
                            onTap: () => _selectResult(p),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: widget.iconColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      AppIcons.locationOnRounded,
                                      size: 18,
                                      color: widget.iconColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: g.text,
                                          ),
                                        ),
                                        if (p.address != null)
                                          Text(
                                            p.address!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: g.textTertiary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    AppIcons.northWestRounded,
                                    size: 14,
                                    color: g.textHint,
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
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showNoResultsOverlay() {
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final fieldWidth = renderBox.size.width;
    final g = GlassColors.of(context);
    final isDark = g.isDark;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        width: fieldWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 62),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
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
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: g.border(0.18)),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.searchOffRounded,
                      size: 28,
                      color: g.textHint,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No locations found',
                      style: TextStyle(fontSize: 13, color: g.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        _removeOverlay();
                        _focusNode.unfocus();
                        widget.onPickOnMap();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: g.busAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: g.busAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              AppIcons.mapOutlined,
                              size: 16,
                              color: g.busAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pick on map instead',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: g.busAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final isSet = widget.value != null;
    final g = GlassColors.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  color: g.inputFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: g.inputBorder),
                ),
                child: CupertinoTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onSearchChanged,
                  style: TextStyle(color: g.text, fontSize: 14),
                  placeholder: widget.hint,
                  placeholderStyle: TextStyle(color: g.textHint, fontSize: 13),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 6),
                    child: Icon(widget.icon, size: 18, color: widget.iconColor),
                  ),
                  suffix: widget.isDetecting || _isSearching
                      ? Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CupertinoActivityIndicator(
                              radius: 8,
                              color: g.textSecondary,
                            ),
                          ),
                        )
                      : isSet
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: _clear,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Icon(
                              AppIcons.clear,
                              size: 18,
                              color: g.textSecondary,
                            ),
                          ),
                        )
                      : null,
                  decoration: null,
                ),
              ),
            ),
          ),

          // Action row
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                GlassActionChip(
                  icon: AppIcons.mapOutlined,
                  label: 'Pick on map',
                  onTap: () {
                    _focusNode.unfocus();
                    _removeOverlay();
                    widget.onPickOnMap();
                  },
                ),
                if (widget.onDetectGps != null) ...[
                  const SizedBox(width: 8),
                  GlassActionChip(
                    icon: AppIcons.myLocation,
                    label: 'Current location',
                    color: g.originMarker,
                    onTap: widget.isDetecting ? null : widget.onDetectGps,
                  ),
                ],
              ],
            ),
          ),

          // Selected location chip
          if (isSet)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.iconColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.checkCircleRounded,
                      size: 16,
                      color: widget.iconColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.value!.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: widget.iconColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.value!.address != null)
                            Text(
                              widget.value!.address!,
                              style: TextStyle(
                                fontSize: 11,
                                color: g.textTertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${widget.value!.latitude.toStringAsFixed(4)}, '
                      '${widget.value!.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: g.textHint,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

