import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_companion/data/models/station.dart';
import 'package:travel_companion/data/models/transport_type.dart';

// ─────────────────────────────────────────────
// 1. TransportHeroHeader
// ─────────────────────────────────────────────

/// Full-width gradient hero block used in each transport screen's SliverAppBar.
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
    final base = type.color;
    final dark = Color.lerp(base, Colors.black, 0.25)!;
    // Push content below status bar + back-button row so it never hides under the clock/battery.
    final topPad = MediaQuery.paddingOf(context).top + kToolbarHeight + 4;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, dark],
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, topPad, 24, 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(type.icon, size: 34, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
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
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
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
// 2. FormSectionCard
// ─────────────────────────────────────────────

/// Card that wraps a labelled form section.
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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: title, icon: icon, color: accentColor),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionTitle({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 3. JourneyDateField
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
              colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: accentColor),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Journey Date',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('EEE, dd MMM yyyy').format(value),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            Icon(Icons.expand_more, size: 22, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 4. JourneyTimeField
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
              colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: accentColor),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Departure Time (optional)',
          prefixIcon: const Icon(Icons.schedule_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
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
                color: value != null ? null : Colors.grey.shade500,
              ),
            ),
            if (value == null)
              Icon(Icons.expand_more, size: 22, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 5. StationAutocompleteField
// ─────────────────────────────────────────────

/// Autocomplete field for railway/metro/local-train stations.
/// Pass a [searchFn] that returns matching [Station] objects.
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
  State<StationAutocompleteField> createState() => _StationAutocompleteFieldState();
}

class _StationAutocompleteFieldState extends State<StationAutocompleteField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<Station> _suggestions = [];
  bool _showDropdown = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.selected != null) {
      _controller.text = widget.selected!.displayName;
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && mounted) {
        setState(() => _showDropdown = false);
      }
    });
  }

  @override
  void didUpdateWidget(StationAutocompleteField old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      _controller.text = widget.selected?.displayName ?? '';
      if (widget.selected != null) {
        setState(() => _showDropdown = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showDropdown = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await widget.searchFn(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _showDropdown = results.isNotEmpty;
        });
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _select(Station station) {
    _controller.text = station.displayName;
    _focusNode.unfocus();
    setState(() => _showDropdown = false);
    widget.onChanged(station);
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _suggestions = [];
      _showDropdown = false;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: Icon(widget.leadingIcon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : widget.selected != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _clear,
                      )
                    : const Icon(Icons.search, size: 20),
          ),
          onChanged: _search,
          validator: (_) => widget.validator?.call(widget.selected),
        ),
        if (_showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 2),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _suggestions.length,
              itemBuilder: (ctx, i) {
                final s = _suggestions[i];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: widget.accentColor.withValues(alpha: 0.12),
                    child: Text(
                      s.code.length >= 2 ? s.code.substring(0, 2) : s.code,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('${s.code}${s.state != null ? ' · ${s.state}' : ''}',
                      style: const TextStyle(fontSize: 12)),
                  onTap: () => _select(s),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 6. SaveJourneyButton
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: FilledButton.icon(
        onPressed: isSaving ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        icon: isSaving
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Icon(Icons.check_circle_outline, size: 22),
        label: Text(isSaving ? 'Saving...' : label),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 7. FieldSpacing — consistent gap between form fields
// ─────────────────────────────────────────────
const fieldSpacing = SizedBox(height: 16);
