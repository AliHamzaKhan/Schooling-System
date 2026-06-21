import 'package:flutter/widgets.dart';

/// Form-factor classification per DESIGN.md grid logic.
/// - mobile: < 600 px (4-col, 16 px gutter)
/// - tablet: 600–1023 px (8-col, 20 px gutter)
/// - desktop: ≥ 1024 px (12-col, 24 px gutter)
enum FormFactor { mobile, tablet, desktop }

class Breakpoints {
  Breakpoints._();

  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  static FormFactor of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < mobileMax) return FormFactor.mobile;
    if (w < tabletMax) return FormFactor.tablet;
    return FormFactor.desktop;
  }

  /// Pick a value per form factor. `tablet` falls back to `desktop` if omitted.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    switch (of(context)) {
      case FormFactor.mobile:
        return mobile;
      case FormFactor.tablet:
        return tablet ?? desktop;
      case FormFactor.desktop:
        return desktop;
    }
  }

  static bool isMobile(BuildContext context) => of(context) == FormFactor.mobile;
  static bool isTablet(BuildContext context) => of(context) == FormFactor.tablet;
  static bool isDesktop(BuildContext context) => of(context) == FormFactor.desktop;
}

/// Convenience builder — passes the current FormFactor to its child builder.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, FormFactor formFactor) builder;
  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => builder(context, Breakpoints.of(context));
}
