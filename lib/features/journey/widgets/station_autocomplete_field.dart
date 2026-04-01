import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/station.dart';

class StationAutocompleteField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData leadingIcon;
  final Station? selected;
  final Future<List<Station>> Function(String query) searchFn;
  final ValueChanged<Station?> onChanged;
  final Color accentColor;
  final String? Function(Station?)? validator;

  const StationAutocompleteField({
    super.key,
    required this.label,
    required this.hint,
    required this.leadingIcon,
    required this.selected,
    required this.searchFn,
    required this.onChanged,
    required this.accentColor,
    this.validator,
  });

  @override
  State<StationAutocompleteField> createState() =>
      _StationAutocompleteFieldState();
}

class _StationAutocompleteFieldState extends State<StationAutocompleteField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  List<Station> _suggestions = [];
  bool _isSearching = false;
  OverlayEntry? _overlayEntry;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.selected != null) {
      _controller.text = widget.selected!.displayName;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(StationAutocompleteField old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      _controller.text = widget.selected?.displayName ?? '';
      if (widget.selected != null) _hideOverlay();
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) _hideOverlay();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _hideOverlay();
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showOverlay() {
    _hideOverlay();
    if (_suggestions.isEmpty) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final fieldWidth = renderBox?.size.width ?? 300;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        width: fieldWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 58),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Builder(
                builder: (ctx) {
                  final g = GlassColors.of(ctx);
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 240),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withValues(alpha: 0.08),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          CupertinoColors.white.withValues(alpha: 0.14),
                          CupertinoColors.white.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: g.border(0.18)),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _suggestions.length,
                      itemBuilder: (_, i) {
                        final s = _suggestions[i];
                        return CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          onPressed: () => _select(s),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: widget.accentColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  s.code.length >= 2
                                      ? s.code.substring(0, 2)
                                      : s.code,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: widget.accentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: g.textAlpha(0.9),
                                      ),
                                    ),
                                    Text(
                                      '${s.code}${s.state != null ? ' - ${s.state}' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: g.textAlpha(0.5),
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
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  Future<void> _search(String query) async {
    _debounce?.cancel();
    if (query.length < 2) {
      _suggestions = [];
      _hideOverlay();
      if (mounted) setState(() {});
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await widget.searchFn(query);
        if (mounted) {
          _suggestions = results;
          if (results.isNotEmpty) {
            _showOverlay();
          } else {
            _hideOverlay();
          }
        }
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _select(Station station) {
    _controller.text = station.displayName;
    _focusNode.unfocus();
    _hideOverlay();
    widget.onChanged(station);
  }

  void _clear() {
    _controller.clear();
    _suggestions = [];
    _hideOverlay();
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return FormField<Station?>(
      initialValue: widget.selected,
      validator: (_) => widget.validator?.call(widget.selected),
      builder: (field) {
        final hasError = field.errorText != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: g.inputFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasError
                            ? const Color(0xFFE74C3C)
                            : g.inputBorder,
                      ),
                    ),
                    child: CupertinoTextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: TextStyle(color: g.textAlpha(0.9), fontSize: 15),
                      placeholder: widget.hint,
                      placeholderStyle: TextStyle(
                        color: g.textHint,
                        fontSize: 14,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 6),
                        child: Icon(widget.leadingIcon, color: g.textSecondary),
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
                          : widget.selected != null
                          ? CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              onPressed: _clear,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  CupertinoIcons.clear,
                                  size: 18,
                                  color: g.textAlpha(0.5),
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Icon(
                                CupertinoIcons.search,
                                size: 20,
                                color: g.textAlpha(0.4),
                              ),
                            ),
                      decoration: null,
                      onChanged: (value) {
                        _search(value);
                        field.didChange(widget.selected);
                      },
                    ),
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
    );
  }
}
