import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:adaptive_platform_ui/src/widgets/ios26/ios26_native_toolbar.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final List<Map<Object?, Object?>> created = [];

  setUp(() {
    created.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, (call) async {
          if (call.method == 'create') {
            final args = call.arguments as Map<Object?, Object?>;
            final params = args['params'] as Uint8List;
            created.add(
              const StandardMessageCodec().decodeMessage(
                ByteData.sublistView(params),
              ) as Map<Object?, Object?>,
            );
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, null);
  });

  Future<void> pumpToolbar(
    WidgetTester tester, {
    bool showsGradient = true,
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          padding: const EdgeInsets.only(top: 62),
          platformBrightness: brightness,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: IOS26NativeToolbar(
                  title: 'Details',
                  toolbarFade: NativeToolbarFade.content,
                  showsGradient: showsGradient,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // Lets the platform view creation and its watchdog settle.
    await tester.pump(const Duration(milliseconds: 200));
  }

  final fade = find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).gradient != null,
  );

  testWidgets(
    'the fade is drawn in Flutter, running extendBelow under the bar',
    (tester) async {
      await pumpToolbar(tester);

      // Flutter overlays (toasts) paint over Flutter pixels; they could not
      // paint over a native gradient hanging outside the platform view.
      expect(
        tester.getRect(fade),
        const Rect.fromLTRB(0, 0, 800, 62 + 44 + 40),
      );
      expect(tester.getRect(find.byType(UiKitView)).bottom, 62 + 44);
      expect(created.single.keys, isNot(contains('fade')));
      expect(created.single.keys, isNot(contains('showsGradient')));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'showsGradient: false draws no fade (the fixed host draws its own)',
    (tester) async {
      await pumpToolbar(tester, showsGradient: false);

      expect(fade, findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('auto fade follows the platform brightness', (tester) async {
    await pumpToolbar(tester, brightness: Brightness.dark);

    final gradient =
        (tester.widget<DecoratedBox>(fade).decoration as BoxDecoration)
                .gradient!
            as LinearGradient;
    expect(
      gradient.colors.first,
      const Color(0xFF000000).withValues(alpha: 0.95),
    );
    expect(gradient.stops, [0.0, 0.55, 0.8, 1.0]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  test('fixed colors ignore the platform brightness', () {
    const light = NativeToolbarFade(color: NativeToolbarFadeColor.light);
    expect(
      light.gradient(Brightness.dark).colors.first,
      const Color(0xFFFFFFFF).withValues(alpha: 0.85),
    );
    expect(
      NativeToolbarFade.contentDark.gradient(Brightness.light).colors.first,
      const Color(0xFF000000).withValues(alpha: 0.75),
    );
  });
}
