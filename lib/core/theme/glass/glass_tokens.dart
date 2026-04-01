import 'package:flutter/cupertino.dart';

class GlassSpacing {
  GlassSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double mega = 56;
  static const double giga = 72;

  static EdgeInsets all(double value) => EdgeInsets.all(value);
  static EdgeInsets horizontal(double value) =>
      EdgeInsets.symmetric(horizontal: value);
  static EdgeInsets vertical(double value) =>
      EdgeInsets.symmetric(vertical: value);
}

class GlassMotion {
  GlassMotion._();

  static const Duration micro = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 360);
  static const Duration long = Duration(milliseconds: 500);

  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve smooth = Curves.easeInOut;
}

class GlassBreakpoints {
  GlassBreakpoints._();

  static const double compact = 600;
  static const double medium = 940;
  static const double expanded = 1280;
}

class GlassLayout {
  GlassLayout._();

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= GlassBreakpoints.expanded) return 64;
    if (width >= GlassBreakpoints.medium) return 40;
    if (width >= GlassBreakpoints.compact) return 24;
    return 16;
  }

  static EdgeInsets responsiveScreenPadding(
    BuildContext context, {
    double top = 0,
    double bottom = 0,
  }) {
    final horizontal = horizontalPadding(context);
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }

  static double heroTopPadding(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return topInset + GlassSpacing.lg;
  }

  static double bottomContentPadding(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return bottomInset + GlassSpacing.xxxl;
  }

  static EdgeInsets sectionSpacing({bool dense = false}) {
    return EdgeInsets.only(bottom: dense ? GlassSpacing.md : GlassSpacing.lg);
  }
}

class GlassTypography {
  final TextStyle largeTitle;
  final TextStyle title;
  final TextStyle subtitle;
  final TextStyle body;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle mono;

  GlassTypography._({
    required this.largeTitle,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.label,
    required this.caption,
    required this.mono,
  });

  factory GlassTypography.of(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final textTheme = theme.textTheme;
    final baseColor = theme.primaryColor;

    return GlassTypography._(
      largeTitle: textTheme.navLargeTitleTextStyle.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      title: textTheme.navTitleTextStyle.copyWith(fontWeight: FontWeight.w700),
      subtitle: textTheme.textStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: baseColor.withValues(alpha: 0.85),
      ),
      body: textTheme.textStyle.copyWith(fontSize: 15, height: 1.35),
      label: textTheme.textStyle.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      caption: textTheme.tabLabelTextStyle.copyWith(
        fontSize: 12,
        color: textTheme.tabLabelTextStyle.color?.withValues(alpha: 0.8),
      ),
      mono: const TextStyle(
        fontFamily: 'SFMono',
        fontSize: 13,
        letterSpacing: 0.3,
      ),
    );
  }
}
