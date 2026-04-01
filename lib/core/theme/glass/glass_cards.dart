import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

import 'glass_constants.dart';
import 'glass_tokens.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? tintColor;
  final double? opacity;
  final double? blur;
  final VoidCallback? onTap;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius,
    this.tintColor,
    this.opacity,
    this.blur,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final radius = borderRadius ?? GlassConstants.cardRadius;
    final blurAmt = blur ?? GlassConstants.blurAmount;
    final surfaceColor = tintColor != null
        ? tintColor!.withValues(alpha: opacity ?? GlassConstants.cardOpacity)
        : g.cardFill(opacity ?? GlassConstants.cardOpacity);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmt, sigmaY: blurAmt),
        child: AnimatedContainer(
          duration: GlassMotion.short,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(radius),
            border:
                border ??
                Border.all(
                  color: g.border(0.14),
                  width: GlassConstants.borderWidth,
                ),
            boxShadow: [
              BoxShadow(
                color: g.shadow,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }

    return Padding(
      padding: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: content,
    );
  }
}

class GlassSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  const GlassSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.children,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final typography = GlassTypography.of(context);
    return GlassCard(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassSectionTitle(
            title: title,
            icon: icon,
            color: accentColor,
            typography: typography,
          ),
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
  final GlassTypography typography;

  const _GlassSectionTitle({
    required this.title,
    required this.icon,
    required this.color,
    required this.typography,
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
          style: typography.label.copyWith(color: color, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class GlassChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color? color;
  final bool highlight;

  const GlassChip({
    super.key,
    this.icon,
    required this.label,
    this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final typography = GlassTypography.of(context);
    final chipColor = color ?? g.textAlpha(0.85);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight ? chipColor.withValues(alpha: 0.18) : g.cardFill(0.05),
        borderRadius: BorderRadius.circular(GlassConstants.chipRadius),
        border: Border.all(
          color: highlight ? chipColor.withValues(alpha: 0.35) : g.border(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: chipColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: typography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}

class GlassPickerOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;

  const GlassPickerOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });
}

class GlassPickerField<T> extends StatelessWidget {
  final String label;
  final String? placeholder;
  final IconData? prefixIcon;
  final Color? prefixIconColor;
  final T? value;
  final List<GlassPickerOption<T>> options;
  final ValueChanged<T?> onChanged;
  final bool enableSearch;
  final bool allowClear;

  const GlassPickerField({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.placeholder,
    this.prefixIcon,
    this.prefixIconColor,
    this.value,
    this.enableSearch = false,
    this.allowClear = false,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final typography = GlassTypography.of(context);
    GlassPickerOption<T>? selectedOption;
    if (value != null) {
      try {
        selectedOption = options.firstWhere((o) => o.value == value);
      } catch (_) {
        selectedOption = null;
      }
    }

    final displayLabel =
        selectedOption?.label ?? placeholder ?? 'Select $label';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: typography.caption.copyWith(color: g.textSecondary)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: options.isEmpty
              ? null
              : () async {
                  final selection =
                      await showCupertinoModalPopup<_GlassPickerSelection<T>>(
                        context: context,
                        builder: (_) => _GlassPickerSheet<T>(
                          title: label,
                          options: options,
                          selectedValue: value,
                          enableSearch: enableSearch,
                          allowClear: allowClear,
                        ),
                      );
                  if (selection == null) return;
                  if (selection.cleared) {
                    onChanged(null);
                  } else {
                    onChanged(selection.value);
                  }
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: g.inputFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: g.inputBorder),
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(
                    prefixIcon,
                    color: prefixIconColor ?? g.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    value == null ? (placeholder ?? 'Select') : displayLabel,
                    style: typography.body.copyWith(
                      color: value == null ? g.textHint : g.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 14,
                  color: g.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassPickerSheet<T> extends StatefulWidget {
  final String title;
  final List<GlassPickerOption<T>> options;
  final T? selectedValue;
  final bool enableSearch;
  final bool allowClear;

  const _GlassPickerSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.enableSearch,
    required this.allowClear,
  });

  @override
  State<_GlassPickerSheet<T>> createState() => _GlassPickerSheetState<T>();
}

class _GlassPickerSheetState<T> extends State<_GlassPickerSheet<T>> {
  late List<GlassPickerOption<T>> _filtered;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
  }

  void _handleSearch(String value) {
    setState(() {
      _query = value.trim().toLowerCase();
      if (_query.isEmpty) {
        _filtered = widget.options;
      } else {
        _filtered = widget.options
            .where(
              (o) =>
                  o.label.toLowerCase().contains(_query) ||
                  (o.subtitle?.toLowerCase().contains(_query) ?? false),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final typography = GlassTypography.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.65;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          color: g.bg,
          padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 12),
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: g.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Text(widget.title, style: typography.title),
              if (widget.enableSearch) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CupertinoSearchTextField(
                    onChanged: _handleSearch,
                    style: typography.body,
                    placeholder: 'Search ${widget.title.toLowerCase()}',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No matches',
                          style: typography.caption.copyWith(
                            color: g.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final option = _filtered[index];
                          final isSelected =
                              option.value == widget.selectedValue;
                          return GestureDetector(
                            onTap: () => Navigator.of(
                              context,
                            ).pop(_GlassPickerSelection(value: option.value)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? g.accent.withValues(alpha: 0.12)
                                    : g.cardFill(0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? g.accent.withValues(alpha: 0.35)
                                      : g.border(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (option.icon != null) ...[
                                    Icon(
                                      option.icon,
                                      size: 18,
                                      color: g.textSecondary,
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.label,
                                          style: typography.body.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? g.accent
                                                : g.text,
                                          ),
                                        ),
                                        if (option.subtitle != null)
                                          Text(
                                            option.subtitle!,
                                            style: typography.caption.copyWith(
                                              color: g.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      CupertinoIcons.check_mark_circled_solid,
                                      size: 18,
                                      color: g.accent,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (widget.allowClear && widget.selectedValue != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: CupertinoButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(const _GlassPickerSelection.cleared()),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Clear selection',
                      style: typography.body.copyWith(color: g.statusDanger),
                    ),
                  ),
                ),
              CupertinoButton(
                onPressed: () => Navigator.of(context).pop(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Cancel',
                  style: typography.body.copyWith(color: g.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPickerSelection<T> {
  final T? value;
  final bool cleared;

  const _GlassPickerSelection({this.value}) : cleared = false;
  const _GlassPickerSelection.cleared() : value = null, cleared = true;
}
