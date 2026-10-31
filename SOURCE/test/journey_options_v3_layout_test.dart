// LOCK13 V3 presenter coverage. The shell owns routes and Journey mutation.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/dev/zyra_one_journey_options_page.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_tap_feedback.dart';

const _id = 'v3-sara';
const _font = 'PoppinsJourneyOptionsV3';
const _labels = <ZyraConceptJourneyOption, String>{
  ZyraConceptJourneyOption.profile: 'View Profile',
  ZyraConceptJourneyOption.timeline: 'Timeline',
  ZyraConceptJourneyOption.bio: 'Journey Bio',
  ZyraConceptJourneyOption.compatibility: 'Compatibility score',
  ZyraConceptJourneyOption.guardians: 'Guardians',
  ZyraConceptJourneyOption.report: 'Report',
  ZyraConceptJourneyOption.end: 'End Journey',
};

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Journey options V3 must remain offline.');
  }
}

Finder _row(ZyraConceptJourneyOption option) =>
    find.byKey(ValueKey('draft_options_${option.name}_$_id'));

Finder _card(String group) =>
    find.byKey(ValueKey('journey_options_${group}_card_$_id'));

Finder get _continue => find.byKey(const ValueKey('draft_journey_$_id'));

Future<void> _mount(
  WidgetTester tester, {
  double width = 430,
  double height = 932,
  double scale = 1,
  bool canViewBio = false,
  bool canViewCompatibility = false,
  bool Function()? canAct,
  ValueChanged<ZyraConceptJourneyOption>? onSelected,
  VoidCallback? onContinue,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: ZyraTapFeedback(
          level: () => ZyraHapticLevel.off,
          canAct: canAct ?? () => true,
          child: child!,
        ),
      ),
      home: Scaffold(
        body: ZyraOneJourneyOptionsPage(
          id: _id,
          firstName: 'Sara',
          surname: 'Ahmed',
          details: '27 · Birmingham',
          nationality: 'British',
          stageNumber: 4,
          stageLabel: 'Faith & Values',
          photo: null,
          onContinue: onContinue ?? () {},
          options: ZyraConceptJourneyOptions(
            id: _id,
            firstName: 'Sara',
            inline: true,
            lockedPage: true,
            canEnd: true,
            canViewBio: canViewBio,
            canViewCompatibility: canViewCompatibility,
            onSelected: onSelected ?? (_) {},
            onCancel: () => fail('A V3 row must not cancel its caller.'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectReadable(WidgetTester tester, Finder text) {
  final paragraph = tester.renderObject<RenderParagraph>(text);
  expect(paragraph.didExceedMaxLines, isFalse);
  expect(paragraph.size.width, greaterThan(0));
  expect(paragraph.size.height, greaterThan(0));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  late bool previousFontStubs;
  late String? previousReadingFont;

  setUpAll(() async {
    final font = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });

  setUp(() {
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    previousFontStubs = ZyraText.useTestFontStubs;
    previousReadingFont = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
  });

  tearDown(() {
    HttpOverrides.global = previousNetwork;
    ZyraText.useTestFontStubs = previousFontStubs;
    ZyraText.testReadingFontFamily = previousReadingFont;
    expect(network.attempts, 0);
  });

  testWidgets(
    '430x932 head keeps locked identity and full width gold Continue',
    (tester) async {
      var continued = 0;
      await _mount(tester, onContinue: () => continued++);
      final photo = find.byKey(const ValueKey('journey_options_photo_$_id'));
      expect(tester.getSize(photo), const Size(88, 88));
      final roundPhoto = find.ancestor(
        of: photo,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ClipOval ||
              (widget is Container &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration as BoxDecoration).shape ==
                      BoxShape.circle),
        ),
      );
      final photoWidget = tester.widget(photo);
      final photoIsRound =
          photoWidget is Container &&
          photoWidget.decoration is BoxDecoration &&
          (photoWidget.decoration as BoxDecoration).shape == BoxShape.circle;
      expect(photoIsRound || roundPhoto.evaluate().isNotEmpty, isTrue);
      final name = find.text('Sara Ahmed');
      expect(name, findsOneWidget);
      expect(tester.widget<Text>(name).style!.fontSize, 24);
      expect(tester.widget<Text>(name).style!.fontWeight, FontWeight.w300);
      expect(find.text('STAGE 4 OF 8 · FAITH & VALUES'), findsOneWidget);
      final details = find.text('27 · Birmingham · British');
      expect(details, findsOneWidget);
      expect(
        tester.widget<Text>(details).style!.color,
        isNot(ZyraColors.foreground),
      );
      expect(find.textContaining('Ethnicity'), findsNothing);
      expect(find.byType(ZyraConceptJourneyOptionsButton), findsNothing);
      final ctaBounds = tester.getRect(_continue);
      final cardBounds = tester.getRect(_card('main'));
      expect(ctaBounds.left, closeTo(cardBounds.left, .1));
      expect(ctaBounds.right, closeTo(cardBounds.right, .1));
      final goldFill = find.descendant(
        of: _continue,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  ZyraColors.goldTextFill,
        ),
      );
      expect(goldFill, findsOneWidget);
      await tester.tap(_continue);
      await tester.pump();
      expect(continued, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'three floating cards divide available height 4:1:2 at 46 minimum',
    (tester) async {
      await _mount(tester);
      final main = tester.getRect(_card('main'));
      final guardians = tester.getRect(_card('guardians'));
      final actions = tester.getRect(_card('actions'));
      expect(main.height, closeTo(guardians.height * 4, .1));
      expect(actions.height, closeTo(guardians.height * 2, .1));
      expect(main.bottom, lessThan(guardians.top));
      expect(guardians.bottom, lessThan(actions.top));
      final groups = <String, List<ZyraConceptJourneyOption>>{
        'main': _labels.keys.take(4).toList(),
        'guardians': [ZyraConceptJourneyOption.guardians],
        'actions': [
          ZyraConceptJourneyOption.report,
          ZyraConceptJourneyOption.end,
        ],
      };
      for (final group in groups.entries) {
        final card = _card(group.key);
        final bounds = tester.getRect(card);
        double? rowHeight;
        for (final option in group.value) {
          final row = _row(option);
          expect(find.descendant(of: card, matching: row), findsOneWidget);
          final rect = tester.getRect(row);
          expect(rect.height, greaterThanOrEqualTo(45.99));
          rowHeight ??= rect.height;
          expect(rect.height, closeTo(rowHeight, .1));
          expect(rect.top, greaterThanOrEqualTo(bounds.top - .1));
          expect(rect.bottom, lessThanOrEqualTo(bounds.bottom + .1));
          expect(row.hitTestable(), findsOneWidget);
          _expectReadable(tester, find.text(_labels[option]!));
        }
      }
      expect(
        find.descendant(
          of: find.byType(ZyraConceptJourneyOptions),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.constraints ==
                    BoxConstraints.tight(const Size(38, 38)) &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        ),
        findsNothing,
      );
      final end = _row(ZyraConceptJourneyOption.end);
      expect(
        tester.widget<Text>(find.text('End Journey')).style!.color,
        const Color(0xFFB84A42),
      );
      expect(
        find.descendant(of: end, matching: find.byIcon(Icons.chevron_right)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final bio in [false, true]) {
    for (final compatibility in [false, true]) {
      testWidgets(
        'Bio=$bio Compatibility=$compatibility preserve locks and seven identities',
        (tester) async {
          final selected = <ZyraConceptJourneyOption>[];
          await _mount(
            tester,
            canViewBio: bio,
            canViewCompatibility: compatibility,
            onSelected: selected.add,
          );
          for (final entry in {
            ZyraConceptJourneyOption.bio: bio,
            ZyraConceptJourneyOption.compatibility: compatibility,
          }.entries) {
            final row = _row(entry.key);
            expect(
              find.descendant(
                of: row,
                matching: find.byIcon(Icons.lock_outline),
              ),
              entry.value ? findsNothing : findsOneWidget,
            );
            expect(
              find.descendant(
                of: row,
                matching: find.byIcon(Icons.chevron_right),
              ),
              entry.value ? findsOneWidget : findsNothing,
            );
            if (!entry.value) {
              expect(
                tester
                    .widget<Text>(find.text(_labels[entry.key]!))
                    .style!
                    .color,
                isNot(ZyraColors.foreground),
              );
            }
          }
          for (final option in _labels.keys) {
            expect(_row(option), findsOneWidget);
            await tester.tap(_row(option));
            await tester.pump();
          }
          expect(selected, _labels.keys.toList());
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'shared feedback guard rejects actions after caller loses ownership',
    (tester) async {
      var allowed = true;
      var continued = 0;
      final selected = <ZyraConceptJourneyOption>[];
      await _mount(
        tester,
        canAct: () => allowed,
        onContinue: () => continued++,
        onSelected: selected.add,
      );
      allowed = false;
      await tester.tap(_continue);
      for (final option in _labels.keys) {
        await tester.tap(_row(option));
      }
      await tester.pump();
      expect(continued, 0);
      expect(selected, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [430.0, 320.0]) {
    testWidgets(
      '200% text at width $width scrolls every readable row into reach',
      (tester) async {
        final selected = <ZyraConceptJourneyOption>[];
        await _mount(
          tester,
          width: width,
          height: 700,
          scale: 2,
          onSelected: selected.add,
        );
        final scrolls = find.descendant(
          of: find.byType(ZyraOneJourneyOptionsPage),
          matching: find.byType(Scrollable),
        );
        expect(
          scrolls,
          findsOneWidget,
          reason: 'The whole page owns the large text scrolling gesture.',
        );
        expect(
          tester.state<ScrollableState>(scrolls).position.maxScrollExtent,
          greaterThan(0),
        );
        for (final option in _labels.keys) {
          final row = _row(option);
          await Scrollable.ensureVisible(tester.element(row), alignment: .5);
          await tester.pumpAndSettle();
          expect(row.hitTestable(), findsOneWidget);
          expect(tester.getSize(row).height, greaterThanOrEqualTo(46));
          _expectReadable(tester, find.text(_labels[option]!));
          await tester.tap(row);
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
        expect(selected, _labels.keys.toList());
        expect(find.byType(FittedBox), findsNothing);
      },
    );
  }
}
