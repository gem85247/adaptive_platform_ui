import 'dart:async';

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
///
/// When the cover lifts, the native platform view needs a couple of frames
/// to mount and render; the drawn fallback is kept painted on top for a
/// short grace period so the hand-off doesn't flicker.
class CoveredRouteBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, bool covered) builder;

  const CoveredRouteBuilder({super.key, required this.builder});

  @override
  State<CoveredRouteBuilder> createState() => _CoveredRouteBuilderState();
}

class _CoveredRouteBuilderState extends State<CoveredRouteBuilder> {
  static const _uncoverGrace = Duration(milliseconds: 220);

  Animation<double>? _animation;
  bool _covered = false;
  bool _graceOverlay = false;
  Timer? _graceTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.secondaryAnimation;
    if (!identical(animation, _animation)) {
      _animation?.removeListener(_update);
      _animation = animation;
      _animation?.addListener(_update);
      _covered = animation != null && !animation.isDismissed;
    }
  }

  @override
  void dispose() {
    _animation?.removeListener(_update);
    _graceTimer?.cancel();
    super.dispose();
  }

  void _update() {
    final nowCovered = _animation != null && !_animation!.isDismissed;
    if (nowCovered == _covered) return;

    _graceTimer?.cancel();
    if (!nowCovered) {
      // Uncovering: keep the drawn fallback painted over the mounting
      // platform view until it has rendered.
      _graceOverlay = true;
      _graceTimer = Timer(_uncoverGrace, () {
        if (mounted) setState(() => _graceOverlay = false);
      });
    } else {
      _graceOverlay = false;
    }
    setState(() => _covered = nowCovered);
  }

  @override
  Widget build(BuildContext context) {
    if (_animation == null) return widget.builder(context, false);
    if (_covered) return widget.builder(context, true);
    if (_graceOverlay) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          widget.builder(context, false),
          Positioned.fill(child: widget.builder(context, true)),
        ],
      );
    }
    return widget.builder(context, false);
  }
}
