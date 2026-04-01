import 'dart:ui';

import 'package:flutter/cupertino.dart';

/// Model for each step in [CupertinoGlassStepper].
class CupertinoGlassStep {
  final String title;
  final IconData? icon;

  const CupertinoGlassStep({required this.title, this.icon});
}

/// Reusable horizontal glassmorphism stepper with Cupertino-like styling.
class CupertinoGlassStepper extends StatefulWidget {
  final List<CupertinoGlassStep> steps;
  final int? currentStep;
  final ValueChanged<int>? onStepChanged;
  final Color accentColor;
  final EdgeInsetsGeometry padding;

  const CupertinoGlassStepper({
    super.key,
    required this.steps,
    required this.accentColor,
    this.currentStep,
    this.onStepChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  @override
  State<CupertinoGlassStepper> createState() => _CupertinoGlassStepperState();
}

class _CupertinoGlassStepperState extends State<CupertinoGlassStepper> {
  late int _internalStep;
  static const double _nodeWidth = 76;
  static const double _connectorWidth = 28;
  static const double _indicatorSize = 30;
  static const double _labelGap = 6;

  bool get _isControlled => widget.currentStep != null;
  int get _effectiveStep => (_isControlled ? widget.currentStep : _internalStep)!
      .clamp(0, widget.steps.isEmpty ? 0 : widget.steps.length - 1);

  @override
  void initState() {
    super.initState();
    _internalStep = widget.currentStep ?? 0;
  }

  @override
  void didUpdateWidget(covariant CupertinoGlassStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isControlled) {
      _internalStep = widget.currentStep ?? _internalStep;
    }
  }

  void _onStepTap(int index) {
    if (!_isControlled) {
      setState(() => _internalStep = index);
    }
    widget.onStepChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final baseFill = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.09)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.52);
    final borderColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.16)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.55);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFFFFF).withValues(alpha: isDark ? 0.14 : 0.68),
                const Color(0xFFFFFFFF).withValues(alpha: isDark ? 0.05 : 0.38),
              ],
            ),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: isDark ? 0.32 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFFFFFFFF).withValues(alpha: isDark ? 0.04 : 0.4),
                blurRadius: 8,
                offset: const Offset(0, -1),
              ),
            ],
            color: baseFill,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: List.generate(widget.steps.length * 2 - 1, (index) {
                    if (index.isOdd) {
                      return _StepperConnector(
                        width: _connectorWidth,
                        accentColor: widget.accentColor,
                        progress: _connectorProgress(index ~/ 2),
                        isDark: isDark,
                      );
                    }
                    final stepIndex = index ~/ 2;
                    return _StepperNode(
                      width: _nodeWidth,
                      indicatorSize: _indicatorSize,
                      step: widget.steps[stepIndex],
                      index: stepIndex,
                      isCompleted: stepIndex < _effectiveStep,
                      isCurrent: stepIndex == _effectiveStep,
                      accentColor: widget.accentColor,
                      isDark: isDark,
                      onTap: () => _onStepTap(stepIndex),
                    );
                  }),
                ),
                const SizedBox(height: _labelGap),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(widget.steps.length * 2 - 1, (index) {
                    if (index.isOdd) {
                      return const SizedBox(width: _connectorWidth);
                    }
                    final stepIndex = index ~/ 2;
                    final isCompleted = stepIndex < _effectiveStep;
                    final isCurrent = stepIndex == _effectiveStep;
                    return SizedBox(
                      width: _nodeWidth,
                      child: Text(
                        widget.steps[stepIndex].title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CupertinoTheme.of(context).textTheme.textStyle
                            .copyWith(
                              fontSize: 11,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: (isCompleted || isCurrent
                                      ? CupertinoColors.label.resolveFrom(
                                          context,
                                        )
                                      : CupertinoColors.secondaryLabel
                                            .resolveFrom(context))
                                  .withValues(alpha: isCurrent ? 0.95 : 0.75),
                              letterSpacing: -0.15,
                            ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _connectorProgress(int connectorIndex) {
    if (_effectiveStep > connectorIndex) return 1;
    if (_effectiveStep == connectorIndex) return 0.5;
    return 0;
  }
}

class _StepperNode extends StatelessWidget {
  final double width;
  final double indicatorSize;
  final CupertinoGlassStep step;
  final int index;
  final bool isCompleted;
  final bool isCurrent;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _StepperNode({
    required this.width,
    required this.indicatorSize,
    required this.step,
    required this.index,
    required this.isCompleted,
    required this.isCurrent,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFuture = !isCompleted && !isCurrent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.96, end: isCurrent ? 1.05 : 1),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: indicatorSize,
              height: indicatorSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isCompleted || isCurrent
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withValues(alpha: 1),
                          accentColor.withValues(alpha: 0.8),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFFFFFF).withValues(alpha: isDark ? 0.12 : 0.58),
                          const Color(0xFFFFFFFF).withValues(alpha: isDark ? 0.05 : 0.38),
                        ],
                      ),
                border: Border.all(
                  color: isCurrent
                      ? const Color(0xFFFFFFFF).withValues(alpha: 0.78)
                      : const Color(0xFFFFFFFF).withValues(alpha: 0.28),
                  width: isCurrent ? 1.4 : 1,
                ),
                boxShadow: [
                  if (isCurrent)
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.42),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: isDark ? 0.32 : 0.08),
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(child: _buildIndicatorContent(isFuture)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorContent(bool isFuture) {
    if (isCompleted) {
      return const Icon(CupertinoIcons.check_mark, size: 15, color: Color(0xFFFFFFFF));
    }

    if (step.icon != null) {
      return Icon(
        step.icon,
        size: 16,
        color: isFuture ? CupertinoColors.tertiaryLabel : const Color(0xFFFFFFFF),
      );
    }

    return Text(
      '${index + 1}',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isFuture ? CupertinoColors.tertiaryLabel : const Color(0xFFFFFFFF),
      ),
    );
  }
}

class _StepperConnector extends StatelessWidget {
  final double width;
  final Color accentColor;
  final double progress;
  final bool isDark;

  const _StepperConnector({
    required this.width,
    required this.accentColor,
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: const Color(0xFFFFFFFF).withValues(alpha: isDark ? 0.18 : 0.45),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: width * progress,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.55),
                  accentColor.withValues(alpha: 0.95),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
