/// One stop in the iOS 26 native toolbar readability fade.
class NativeToolbarFadeStop {
  const NativeToolbarFadeStop({
    required this.location,
    required this.opacity,
  }) : assert(location >= 0.0 && location <= 1.0),
       assert(opacity >= 0.0 && opacity <= 1.0);

  /// Vertical position in the fade (0 = top of toolbar, 1 = bottom of fade).
  final double location;

  /// Opacity of the scrim color at [location].
  final double opacity;

  Map<String, dynamic> toNativeMap() => {
        'location': location,
        'opacity': opacity,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NativeToolbarFadeStop &&
        other.location == location &&
        other.opacity == opacity;
  }

  @override
  int get hashCode => Object.hash(location, opacity);
}

/// How the toolbar fade picks its base color.
enum NativeToolbarFadeColor {
  /// White in light mode, black in dark mode.
  auto,

  /// Always white (covers content behind dark title text).
  light,

  /// Always black (dark scrim).
  dark,
}

/// Configurable fade behind the iOS 26 native toolbar.
///
/// The toolbar itself is clear liquid glass; this gradient sits behind it so
/// title/actions stay readable over scrolling content. Defaults match the
/// historical package behaviour.
class NativeToolbarFade {
  const NativeToolbarFade({
    this.stops = standardStops,
    this.color = NativeToolbarFadeColor.auto,
    this.extendBelow = 30.0,
  }) : assert(extendBelow >= 0.0);

  /// Historical default — fades early (status-bar region).
  static const List<NativeToolbarFadeStop> standardStops = [
    NativeToolbarFadeStop(location: 0.0, opacity: 0.85),
    NativeToolbarFadeStop(location: 0.4, opacity: 0.6),
    NativeToolbarFadeStop(location: 0.7, opacity: 0.2),
    NativeToolbarFadeStop(location: 1.0, opacity: 0.0),
  ];

  /// Holds opacity through the title row, then drops under the bar.
  /// Use on screens where content scrolls under the toolbar (e.g. conversation).
  static const NativeToolbarFade content = NativeToolbarFade(
    stops: [
      NativeToolbarFadeStop(location: 0.0, opacity: 0.95),
      NativeToolbarFadeStop(location: 0.55, opacity: 0.9),
      NativeToolbarFadeStop(location: 0.8, opacity: 0.4),
      NativeToolbarFadeStop(location: 1.0, opacity: 0.0),
    ],
    extendBelow: 40.0,
  );

  /// Same curve as [content] but always a black scrim.
  static const NativeToolbarFade contentDark = NativeToolbarFade(
    stops: [
      NativeToolbarFadeStop(location: 0.0, opacity: 0.75),
      NativeToolbarFadeStop(location: 0.55, opacity: 0.65),
      NativeToolbarFadeStop(location: 0.8, opacity: 0.3),
      NativeToolbarFadeStop(location: 1.0, opacity: 0.0),
    ],
    color: NativeToolbarFadeColor.dark,
    extendBelow: 40.0,
  );

  static const NativeToolbarFade standard = NativeToolbarFade();

  /// Opacity stops from top → bottom. Must be non-empty and sorted by location.
  final List<NativeToolbarFadeStop> stops;

  /// Base color of the scrim.
  final NativeToolbarFadeColor color;

  /// Extra points the fade extends below the toolbar bounds.
  final double extendBelow;

  Map<String, dynamic> toNativeMap() => {
        'stops': stops.map((s) => s.toNativeMap()).toList(),
        'colorMode': color.name,
        'extendBelow': extendBelow,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NativeToolbarFade &&
        other.color == color &&
        other.extendBelow == extendBelow &&
        _listEquals(other.stops, stops);
  }

  @override
  int get hashCode => Object.hash(color, extendBelow, Object.hashAll(stops));

  static bool _listEquals(List<NativeToolbarFadeStop> a, List<NativeToolbarFadeStop> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
