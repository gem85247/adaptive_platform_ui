import 'package:flutter/widgets.dart';

/// Rebuilds with `covered: true` while the enclosing route is covered by
/// another route (sheet presentation, push) — i.e. whenever the route's
/// secondary animation is not dismissed.
///
/// Platform views cannot follow route transforms: when a covering route
/// scales or translates the presenting page (e.g. `CupertinoSheetRoute`),
/// UiKitView-backed widgets render as scuffed grey quads. Wrap them in this
/// builder and return the drawn fallback while [covered] is true — the page
/// is scaled and dimmed then, so the swap is imperceptible.
class CoveredRouteBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool covered) builder;

  const CoveredRouteBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.secondaryAnimation;
    if (animation == null) return builder(context, false);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => builder(context, !animation.isDismissed),
    );
  }
}
