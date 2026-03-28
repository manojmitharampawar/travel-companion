import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';
import 'package:travel_companion/data/models/station.dart';
import 'package:travel_companion/data/models/transport_type.dart';

// Glass design constants shared across journey forms
const _kBgColor = Color(0xFF0A0E21);

// ─────────────────────────────────────────────
// 1. TransportHeroHeader — glass version
// ─────────────────────────────────────────────

class TransportHeroHeader extends StatelessWidget {
  final TransportType type;
  final String title;
  final String subtitle;

  const TransportHeroHeader({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top + kToolbarHeight + 4;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            type.color.withValues(alpha: 0.6),
            _kBgColor,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative orbs
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -10,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    type.color.withValues(alpha: 0.15),
                    type.color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(24, topPad, 24, 24),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(type.icon, size: 32, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 2. FormSectionCard — glass version
// ─────────────────────────────────────────────

class FormSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;

  const FormSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassSectionTitle(title: title, icon: icon, color: accentColor),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _GlassSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _GlassSectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 3. JourneyDateField — glass version
// ─────────────────────────────────────────────

class JourneyDateField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final Color accentColor;

  const JourneyDateField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme:
                  Theme.of(ctx).colorScheme.copyWith(primary: accentColor),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _glassInputDecoration(
          labelText: 'Journey Date',
          prefixIcon: Icons.calendar_today_outlined,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('EEE, dd MMM yyyy').format(value),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            Icon(Icons.expand_more,
                size: 22, color: Colors.white.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 4. JourneyTimeField — glass version
// ─────────────────────────────────────────────

class JourneyTimeField extends StatelessWidget {
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;
  final Color accentColor;

  const JourneyTimeField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme:
                  Theme.of(ctx).colorScheme.copyWith(primary: accentColor),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _glassInputDecoration(
          labelText: 'Departure Time (optional)',
          prefixIcon: Icons.schedule_outlined,
          suffixIcon: value != null
              ? IconButton(
                  icon: Icon(Icons.clear,
                      size: 18, color: Colors.white.withValues(alpha: 0.5)),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value?.format(context) ?? 'Tap to set time',
              style: TextStyle(
                fontSize: 15,
                fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                color: value != null
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.4),
              ),
            ),
            if (value == null)
              Icon(Icons.expand_more,
                  size: 22, color: Colors.white.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 5. StationAutocompleteField — glass version
// ─────────────────────────────────────────────

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
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(14),
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 240),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2340).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _suggestions.length,
                    itemBuilder: (_, i) {
                      final s = _suggestions[i];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              widget.accentColor.withValues(alpha: 0.2),
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
                        title: Text(
                          s.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        subtitle: Text(
                          '${s.code}${s.state != null ? ' · ${s.state}' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        onTap: () => _select(s),
                      );
                    },
                  ),
                ),
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
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
        decoration: _glassInputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: widget.leadingIcon,
          suffixIcon: _isSearching
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                )
              : widget.selected != null
                  ? IconButton(
                      icon: Icon(Icons.clear,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.5)),
                      onPressed: _clear,
                    )
                  : Icon(Icons.search,
                      size: 20, color: Colors.white.withValues(alpha: 0.4)),
        ),
        onChanged: _search,
        validator: (_) => widget.validator?.call(widget.selected),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 6. SaveJourneyButton — glass version
// ─────────────────────────────────────────────

class SaveJourneyButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onPressed;
  final Color accentColor;
  final String label;

  const SaveJourneyButton({
    super.key,
    required this.isSaving,
    required this.onPressed,
    required this.accentColor,
    this.label = 'Save Journey',
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      label: label,
      icon: Icons.check_circle_outline,
      onPressed: isSaving ? null : onPressed,
      accentColor: accentColor,
      isLoading: isSaving,
    );
  }
}

// ─────────────────────────────────────────────
// 7. FieldSpacing
// ─────────────────────────────────────────────
const fieldSpacing = SizedBox(height: 16);

// ─────────────────────────────────────────────
// Glass Input Decoration helper
// ─────────────────────────────────────────────

InputDecoration _glassInputDecoration({
  required String labelText,
  String? hintText,
  IconData? prefixIcon,
  Widget? suffixIcon,
  String? helperText,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    helperText: helperText,
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: Colors.white.withValues(alpha: 0.5))
        : null,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide:
          BorderSide(color: Colors.white.withValues(alpha: 0.35), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE74C3C)),
    ),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
    helperStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
    counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
    errorStyle: const TextStyle(color: Color(0xFFE74C3C)),
  );
}

/// Exposes glass input decoration for use in other screens
InputDecoration glassInputDecoration({
  required String labelText,
  String? hintText,
  IconData? prefixIcon,
  Widget? suffixIcon,
  String? helperText,
}) =>
    _glassInputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      helperText: helperText,
    );
