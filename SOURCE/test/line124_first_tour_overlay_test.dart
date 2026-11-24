import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_first_tour_overlay.dart';
import 'package:zyra/dev/zyra_first_tour_steps.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_tap_feedback.dart';

Finder _key(String value) => find.byKey(ValueKey(value));
const _tab = Rect.fromLTWH(42, 856, 44, 44);

Future<void> _mount(
  WidgetTester tester, {
  int index = 2,
  bool guardian = false,
  bool quiet = true,
  double textScale = 1,
  Rect? target = const Rect.fromLTWH(20, 140, 390, 700),
  VoidCallback? onNext,
  VoidCallback? onBack,
  VoidCallback? onUnderlying,
  bool Function()? canAct,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: quiet,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: ZyraTapFeedback(
          level: () => ZyraHapticLevel.off,
          canAct: () => true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onUnderlying ?? () {},
                child: Semantics(
                  label: 'Underlying real control',
                  button: true,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned.fill(
                child: ZyraFirstTourOverlay(
                  index: index,
                  guardian: guardian,
                  firstName: guardian ? 'Hassan' : 'Adam',
                  onNext: onNext ?? () {},
                  onBack: onBack ?? () {},
                  canAct: canAct,
                  navBarTop: () => 850,
                  targetRect: (key) => key.startsWith('floating-nav-item-')
                      ? _tab.shift(
                          Offset(int.parse(key.split('-').last) * 73, 0),
                        )
                      : target,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  testWidgets('The overlay consumes blank, lit and button taps exactly once', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var next = 0, back = 0, underlying = 0;
    await _mount(
      tester,
      onNext: () => next++,
      onBack: () => back++,
      onUnderlying: () => underlying++,
    );
    await tester.tapAt(const Offset(350, 300));
    await tester.pump();
    expect(next, 1);
    await tester.tapAt(const Offset(20, 300));
    await tester.pump();
    expect(back, 1);
    await tester.tap(_key('first_tour_next'));
    await tester.pump();
    expect(next, 2);
    expect(underlying, 0);
  });

  testWidgets('Q175 tall-item cut-out ends before its measured note and tab', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(tester);
    final note = tester.getRect(_key('first_tour_note'));
    final lit = tester.getRect(_key('first_tour_target'));
    final tab = tester.getRect(_key('first_tour_tab'));
    expect(lit.height, greaterThanOrEqualTo(64));
    expect(lit.bottom, lessThan(848));
    expect(note.top - lit.bottom, closeTo(14, .01));
    expect(note.bottom, lessThanOrEqualTo(838.01));
    expect(note.overlaps(lit), isFalse);
    expect(note.overlaps(tab), isFalse);
    expect(note.left, 20);
    expect(note.right, 410);
  });

  testWidgets('A small upper target puts its measured note below', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(
      tester,
      index: 4,
      target: const Rect.fromLTWH(160, 180, 100, 48),
    );
    final note = tester.getRect(_key('first_tour_note'));
    final lit = tester.getRect(_key('first_tour_target'));
    expect(note.top - lit.bottom, closeTo(14, .01));
    expect(note.bottom, lessThanOrEqualTo(838.01));
  });

  testWidgets(
    'The t09-like target puts the note above and leaves nav visible',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(
        tester,
        index: 9,
        target: const Rect.fromLTWH(45, 600, 340, 100),
      );
      final note = tester.getRect(_key('first_tour_note'));
      final lit = tester.getRect(_key('first_tour_target'));
      final tab = tester.getRect(_key('first_tour_tab'));
      expect(lit.top - note.bottom, closeTo(14, .01));
      expect(note.top, greaterThanOrEqualTo(48));
      expect(note.overlaps(tab), isFalse);
      expect(note.overlaps(lit), isFalse);
    },
  );

  testWidgets(
    'Missing, empty and offscreen items use the tab without changing copy',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final target in <Rect?>[
        null,
        Rect.zero,
        const Rect.fromLTWH(20, 1200, 200, 100),
      ]) {
        await _mount(tester, index: 6, target: target);
        expect(
          tester.getRect(_key('first_tour_target')),
          tester.getRect(_key('first_tour_tab')),
        );
        expect(find.text('Nothing here yet'), findsOneWidget);
        expect(
          tester.getRect(_key('first_tour_note')).bottom,
          lessThan(tester.getRect(_key('first_tour_tab')).top),
        );
      }
    },
  );

  testWidgets('Larger text is measured before cropping the target', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(tester, textScale: 2);
    final note = tester.getRect(_key('first_tour_note'));
    final lit = tester.getRect(_key('first_tour_target'));
    expect(note.overlaps(lit), isFalse);
    expect(note.bottom, lessThanOrEqualTo(838.01));
    expect(lit.height, greaterThanOrEqualTo(64));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Q195 Reduced Motion omits tap and swipe cues while guidance and Next remain',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final guardian in [false, true]) {
        final steps = guardian ? zyraGuardianTourSteps : zyraSeekerTourSteps;
        for (final index in [
          steps.indexWhere((step) => !step.swipe) + 1,
          steps.indexWhere((step) => step.swipe) + 1,
        ]) {
          var next = 0, underlying = 0;
          await _mount(
            tester,
            guardian: guardian,
            index: index,
            onNext: () => next++,
            onUnderlying: () => underlying++,
          );
          expect(_key('first_tour_touch'), findsNothing);
          expect(_key('first_tour_target'), findsOneWidget);
          expect(_key('first_tour_arrow'), findsOneWidget);
          expect(_key('first_tour_note'), findsOneWidget);
          expect(_key('first_tour_next'), findsOneWidget);
          await tester.tap(_key('first_tour_next'));
          await tester.pump();
          expect(next, 1);
          expect(underlying, 0);
          await tester.pump(const Duration(seconds: 30));
          expect(_key('first_tour_touch'), findsNothing);
          expect(next, 1);
        }
      }
    },
  );

  testWidgets('Q195 motion-on cue retains its locked appearance and loop', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var next = 0;
    await _mount(tester, quiet: false, index: 4, onNext: () => next++);
    await tester.pump(const Duration(milliseconds: 100));
    final cue = _key('first_tour_touch');
    expect(tester.getSize(cue), const Size(40, 40));
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(of: cue, matching: find.byType(DecoratedBox)),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, const Color(0x99FFFFFF));
    final border = decoration.border! as Border;
    expect(border.top.color, const Color(0xFFA9792E));
    expect(border.top.width, 2);
    expect(decoration.boxShadow, const [
      BoxShadow(color: Color(0x402B2420), offset: Offset(0, 4), blurRadius: 14),
    ]);
    final earlyScale = tester.widget<Transform>(cue).transform.entry(0, 0);
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester.widget<Transform>(cue).transform.entry(0, 0),
      isNot(earlyScale),
    );
    await tester.pump(const Duration(seconds: 4));
    expect(cue, findsOneWidget);
    expect(next, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Q195 live Reduce Motion hides and restores only the looping cue',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(tester, quiet: false, index: 4);
      await tester.pump(const Duration(milliseconds: 350));
      final state = tester.state(find.byType(ZyraFirstTourOverlay));
      final positions = {
        for (final key in [
          'first_tour_target',
          'first_tour_arrow',
          'first_tour_note',
          'first_tour_next',
        ])
          key: tester.getRect(_key(key)),
      };
      expect(_key('first_tour_touch'), findsOneWidget);
      await _mount(tester, quiet: true, index: 4);
      expect(
        identical(tester.state(find.byType(ZyraFirstTourOverlay)), state),
        isTrue,
      );
      expect(_key('first_tour_touch'), findsNothing);
      for (final entry in positions.entries) {
        expect(tester.getRect(_key(entry.key)), entry.value);
      }
      await _mount(tester, quiet: false, index: 4);
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        identical(tester.state(find.byType(ZyraFirstTourOverlay)), state),
        isTrue,
      );
      expect(_key('first_tour_touch'), findsOneWidget);
      for (final entry in positions.entries) {
        expect(tester.getRect(_key(entry.key)), entry.value);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Swipe loops without moving the real page or advancing', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var next = 0, underlying = 0;
    await _mount(
      tester,
      quiet: false,
      onNext: () => next++,
      onUnderlying: () => underlying++,
    );
    await tester.pump(const Duration(milliseconds: 350));
    final early = tester.getRect(_key('first_tour_touch'));
    await tester.pump(const Duration(milliseconds: 700));
    final late = tester.getRect(_key('first_tour_touch'));
    expect(late.center.dx, lessThan(early.center.dx));
    expect(next, 0);
    expect(underlying, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'VoiceOver has title, line and Next button while real controls are hidden',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      await _mount(tester, index: 4);
      expect(find.bySemanticsLabel('Underlying real control'), findsNothing);
      expect(find.bySemanticsLabel('Ready to begin?'), findsOneWidget);
      expect(
        find.bySemanticsLabel(zyraSeekerTourSteps[3].body),
        findsOneWidget,
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Next'))
            .flagsCollection
            .isButton,
        isTrue,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'Welcome and end have their button copy; final step says Finish',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var next = 0;
      await _mount(tester, index: 0, onNext: () => next++);
      expect(find.text('Hi Adam, welcome'), findsOneWidget);
      expect(find.text('Let’s go'), findsOneWidget);
      final mark = tester.widget<Text>(find.text('ZYRA')).style!;
      expect(mark.fontFamily, 'Poppins');
      expect(mark.fontSize, 22);
      expect(mark.fontWeight, FontWeight.w600);
      expect(_key('first_tour_target'), findsNothing);
      await tester.tap(_key('first_tour_next'));
      expect(next, 1);
      await _mount(tester, index: 18);
      expect(find.text('Finish'), findsOneWidget);
      await _mount(tester, index: 15, guardian: true);
      expect(find.text('That’s everything, Hassan'), findsOneWidget);
      expect(find.text('Start using ZYRA'), findsOneWidget);
    },
  );

  testWidgets('Revoked owner cannot use captured Next or background tap', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var admitted = true;
    var next = 0;
    await _mount(tester, onNext: () => next++, canAct: () => admitted);
    final tap = tester.widget<GestureDetector>(_key('first_tour_next')).onTap!;
    admitted = false;
    tap();
    await tester.tapAt(const Offset(350, 300));
    expect(next, 0);
  });
}
