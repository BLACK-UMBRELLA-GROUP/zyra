import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_choice_card.dart';

const _first = ValueKey('first-onboarding-choice');
const _second = ValueKey('second-onboarding-choice');

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool disableAnimations = false,
  bool accessibleNavigation = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
          accessibleNavigation: accessibleNavigation,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    ),
  );
}

Semantics _choiceSemantics(WidgetTester tester, String label) =>
    tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == label,
      ),
    );

AnimatedContainer _cardContainer(WidgetTester tester, Key key) =>
    tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(key),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is AnimatedContainer &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).borderRadius ==
                  BorderRadius.circular(20),
        ),
      ),
    );

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  testWidgets('standalone choice uses the shared frost and gold card tokens', (
    tester,
  ) async {
    var selected = false;
    late StateSetter rebuild;
    await _mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return ZyraOnboardingChoiceCard(
            key: _first,
            label: 'Male',
            selected: selected,
            icon: Icons.male_rounded,
            onTap: () {},
          );
        },
      ),
    );
    var container = _cardContainer(tester, _first);
    var decoration = container.decoration! as BoxDecoration;
    expect(container.duration, const Duration(milliseconds: 480));
    expect(container.curve, Curves.easeInOutCubic);
    expect(decoration.color, ZyraColors.frostFill);
    expect(decoration.borderRadius, BorderRadius.circular(20));
    expect((decoration.border! as Border).top.color, ZyraColors.frostBorder);
    final initialHeight = tester.getSize(find.byKey(_first)).height;
    expect(initialHeight, greaterThanOrEqualTo(72));
    expect(find.byIcon(Icons.male_rounded), findsOneWidget);
    expect(tester.widget<Text>(find.text('Male')).style!.fontSize, 17);

    rebuild(() => selected = true);
    await tester.pump();
    container = _cardContainer(tester, _first);
    decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, ZyraColors.journeyGold.withValues(alpha: .13));
    expect(
      (decoration.border! as Border).top.color,
      ZyraColors.journeyGold.withValues(alpha: .85),
    );
    expect(find.byType(AnimatedSwitcher), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(_first),
        matching: find.byType(AnimatedOpacity),
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(_first)).height, initialHeight);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom leading artwork remains inside the single card action', (
    tester,
  ) async {
    const artworkKey = ValueKey('custom-choice-leading');
    await _mount(
      tester,
      ZyraOnboardingChoiceCard(
        label: 'A custom option',
        selected: false,
        leading: const Text('A', key: artworkKey),
        onTap: () {},
      ),
    );
    expect(find.byKey(artworkKey), findsOneWidget);
    expect(
      _choiceSemantics(tester, 'A custom option').excludeSemantics,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap selects once and does not navigate or auto-advance', (
    tester,
  ) async {
    var taps = 0;
    await _mount(
      tester,
      ZyraOnboardingChoiceCard(
        key: _first,
        label: 'Female',
        selected: false,
        onTap: () => taps++,
      ),
    );
    await tester.tap(find.byKey(_first));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(find.text('Female'), findsOneWidget);
    expect(find.byType(ZyraOnboardingChoiceCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single choice announces one selected exclusive button', (
    tester,
  ) async {
    var taps = 0;
    await _mount(
      tester,
      ZyraOnboardingChoiceCard(
        label: 'Male',
        selected: true,
        onTap: () => taps++,
      ),
    );
    final semantics = _choiceSemantics(tester, 'Male');
    expect(semantics.excludeSemantics, isTrue);
    expect(semantics.properties.button, isTrue);
    expect(semantics.properties.selected, isTrue);
    expect(semantics.properties.inMutuallyExclusiveGroup, isTrue);
    expect(semantics.properties.checked, isNull);
    expect(semantics.properties.onTap, isNotNull);
    semantics.properties.onTap!();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple choice announces checked without an exclusive group', (
    tester,
  ) async {
    await _mount(
      tester,
      ZyraOnboardingChoiceCard(
        label: 'Selected interest',
        selected: true,
        multiple: true,
        onTap: () {},
      ),
    );
    final semantics = _choiceSemantics(tester, 'Selected interest');
    expect(semantics.excludeSemantics, isTrue);
    expect(semantics.properties.button, isTrue);
    expect(semantics.properties.checked, isTrue);
    expect(semantics.properties.inMutuallyExclusiveGroup, isNot(isTrue));
    expect(semantics.properties.onTap, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rapid choice reversals retain unique state and readable options',
    (tester) async {
      String? selected;
      await _mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              ZyraOnboardingChoiceCard(
                key: _first,
                label: 'Male',
                selected: selected == 'male',
                onTap: () => setState(() => selected = 'male'),
              ),
              const SizedBox(height: 14),
              ZyraOnboardingChoiceCard(
                key: _second,
                label: 'Female',
                selected: selected == 'female',
                onTap: () => setState(() => selected = 'female'),
              ),
            ],
          ),
        ),
      );
      for (final key in [_first, _second, _first, _second, _first]) {
        await tester.tap(find.byKey(key));
        await tester.pump(const Duration(milliseconds: 40));
        expect(find.text('Male'), findsOneWidget);
        expect(find.text('Female'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpAndSettle();
      expect(selected, 'male');
      expect(_choiceSemantics(tester, 'Male').properties.selected, isTrue);
      expect(_choiceSemantics(tester, 'Female').properties.selected, isFalse);
      expect(find.byType(AnimatedSwitcher), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final accessible in [false, true]) {
    final setting = accessible ? 'accessible navigation' : 'reduced motion';
    testWidgets('$setting settles selection without an animation delay', (
      tester,
    ) async {
      var selected = false;
      await _mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => ZyraOnboardingChoiceCard(
            key: _first,
            label: 'Male',
            selected: selected,
            onTap: () => setState(() => selected = true),
          ),
        ),
        disableAnimations: !accessible,
        accessibleNavigation: accessible,
      );
      await tester.tap(find.byKey(_first));
      await tester.pump();
      expect(_cardContainer(tester, _first).duration, Duration.zero);
      final mark = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byKey(_first),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(mark.duration, Duration.zero);
      expect(mark.opacity, 1);
      expect(_choiceSemantics(tester, 'Male').properties.selected, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '$setting shows entrance content completely on the first frame',
      (tester) async {
        await _mount(
          tester,
          const ZyraOnboardingChoiceEntrance(child: Text('Ready immediately')),
          disableAnimations: !accessible,
          accessibleNavigation: accessible,
        );
        expect(find.text('Ready immediately'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(ZyraOnboardingChoiceEntrance),
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('compact large-text labels grow naturally without clipping', (
    tester,
  ) async {
    const label =
        'A meaningful longer onboarding answer that remains fully readable';
    await _mount(
      tester,
      ZyraOnboardingChoiceCard(
        key: _first,
        label: label,
        selected: false,
        icon: Icons.person_outline_rounded,
        onTap: () {},
      ),
      size: const Size(320, 568),
      textScale: 1.4,
    );
    final cardRect = tester.getRect(find.byKey(_first));
    final textRect = tester.getRect(find.text(label));
    expect(cardRect.height, greaterThan(72));
    expect(textRect.left, greaterThanOrEqualTo(cardRect.left));
    expect(textRect.right, lessThanOrEqualTo(cardRect.right));
    expect(textRect.top, greaterThanOrEqualTo(cardRect.top));
    expect(textRect.bottom, lessThanOrEqualTo(cardRect.bottom));
    final text = tester.widget<Text>(find.text(label));
    expect(text.maxLines, isNull);
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    expect(find.byKey(_first).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('choice entrance completes gently without replay on rebuild', (
    tester,
  ) async {
    late StateSetter rebuild;
    await _mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return const ZyraOnboardingChoiceEntrance(child: Text('My choices'));
        },
      ),
    );
    final entrance = find.byType(ZyraOnboardingChoiceEntrance);
    final tween = tester.widget<TweenAnimationBuilder<double>>(
      find.descendant(
        of: entrance,
        matching: find.byWidgetPredicate(
          (widget) => widget is TweenAnimationBuilder<double>,
        ),
      ),
    );
    expect(tween.duration, const Duration(milliseconds: 520));
    expect(tween.curve, Curves.easeOutCubic);
    Finder opacity() =>
        find.descendant(of: entrance, matching: find.byType(Opacity));
    Finder translation() =>
        find.descendant(of: entrance, matching: find.byType(Transform));
    final firstOpacity = tester.widget<Opacity>(opacity()).opacity;
    expect(
      tester.widget<Transform>(translation()).transform.getTranslation().y,
      12,
    );
    await tester.pump(const Duration(milliseconds: 260));
    final midOpacity = tester.widget<Opacity>(opacity()).opacity;
    expect(midOpacity, greaterThan(firstOpacity));
    expect(midOpacity, lessThan(1));
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(opacity()).opacity, 1);
    expect(
      tester.widget<Transform>(translation()).transform.getTranslation().y,
      0,
    );
    rebuild(() {});
    await tester.pump();
    expect(tester.widget<Opacity>(opacity()).opacity, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing an unfinished choice entrance is safe', (
    tester,
  ) async {
    await _mount(
      tester,
      const ZyraOnboardingChoiceEntrance(child: Text('Leaving safely')),
    );
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
