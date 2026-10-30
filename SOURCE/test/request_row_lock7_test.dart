// LOCK 7 geometry, accessible controls and caller-owned request guards.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_profiles_components.dart';

const _labels = [
  'Request a Journey',
  'Request sent',
  'Received request',
  'Journey archived',
];
const _person = SeekerProfile(
  id: 'lock7',
  firstName: 'Sample',
  age: 28,
  city: 'London',
  gender: 'female',
  photos: [],
);
Finder _key(String value) => find.byKey(ValueKey(value));
Finder get _surface => _key('concept_request_row_surface');
Finder get _previous => _key('concept_previous_profile');
Finder get _next => _key('concept_next_profile');
Finder get _request => _key('draft_profile_lock7');

VoidCallback _semantics(WidgetTester tester) {
  final handle = tester.ensureSemantics();
  var disposed = false;
  void dispose() {
    if (!disposed) handle.dispose();
    disposed = true;
  }

  addTearDown(dispose);
  return dispose;
}

Future<void> _mount(
  WidgetTester tester, {
  String label = 'Request a Journey',
  double scale = 1,
  double width = 430,
  bool enabled = true,
  bool previous = true,
  bool single = true,
  bool readOnly = false,
  bool chrome = true,
  List<String>? taps,
}) async {
  tester.view.physicalSize = Size(width, 932);
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
        child: child!,
      ),
      home: Scaffold(
        body: ZyraBrowseDesigns(
          profiles: const [_person],
          selectedIndex: 0,
          design: ZyraOneJourneyBrowseDesign.portraitCard,
          photoBuilder:
              (_, _, {required width, required height, required alignment}) =>
                  throw StateError('No photos in this fixture'),
          requestRowLabels: single ? _labels : null,
          readOnlyPreview: readOnly,
          showFeedChrome: chrome,
          onPrevious: previous ? () => taps?.add('previous') : null,
          onNext: () => taps?.add('next'),
          onRequest: (_) => taps?.add('request'),
          requestLabel: (_) => label,
          requestSemanticLabel: (_) => label == 'Request sent'
              ? 'Request sent. Tap to cancel request'
              : label,
          invitationSent: (_) => label == 'Request sent',
          canRequest: (_) => enabled,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() async {
    final font = FontLoader('PoppinsLock7');
    for (final weight in ['Regular', 'Light', 'ExtraLight', 'SemiBold']) {
      font.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    await font.load();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsLock7';
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  testWidgets(
    'one glass pill, 68 point arrows, 56 height and three real taps',
    (tester) async {
      final disposeSemantics = _semantics(tester);
      final taps = <String>[];
      await _mount(tester, taps: taps);
      expect(find.byType(ZyraProfilesRequestRow), findsOneWidget);
      expect(find.byType(ZyraProfilesBottomRow), findsNothing);
      expect(tester.getSize(_surface), const Size(390, 56));
      for (final arrow in [_previous, _next]) {
        expect(tester.getSize(arrow), const Size(68, 56));
      }
      expect(tester.getSize(_request), const Size(254, 56));
      final dividers = find.descendant(
        of: _surface,
        matching: find.byType(ColoredBox),
      );
      expect(dividers, findsNWidgets(2));
      for (final divider in dividers.evaluate()) {
        expect(
          tester.getSize(find.byWidget(divider.widget)),
          const Size(1, 28),
        );
      }
      final ink = tester.widget<Container>(
        find.descendant(of: _surface, matching: find.byType(Container)).first,
      );
      final border =
          (ink.foregroundDecoration! as BoxDecoration).border! as Border;
      expect(border.top.color, ZyraColors.journeyGold.withValues(alpha: .6));
      for (final (control, label) in [
        (_previous, 'Previous profile · no decision'),
        (_request, 'Request a Journey'),
        (_next, 'Next profile · no decision'),
      ]) {
        final node = tester.getSemantics(control);
        expect(node.label, label);
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.flagsCollection.isEnabled, ui.Tristate.isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        await tester.tap(control);
      }
      expect(taps, ['previous', 'request', 'next']);
      disposeSemantics();
    },
  );

  testWidgets(
    'first Previous unavailable; sent paint and cancel label retained',
    (tester) async {
      final disposeSemantics = _semantics(tester);
      final taps = <String>[];
      await _mount(tester, label: 'Request sent', previous: false, taps: taps);
      final node = tester.getSemantics(_previous);
      expect(node.label, 'Previous profile · no decision');
      expect(node.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(
        tester
            .widget<Icon>(
              find.descendant(of: _previous, matching: find.byType(Icon)),
            )
            .color,
        ZyraColors.ink(.28),
      );
      expect(
        tester.getSemantics(_request).label,
        'Request sent. Tap to cancel request',
      );
      final text = tester.widget<Text>(find.text('Request sent'));
      expect(text.style!.color, ZyraColors.journeyGold);
      final ink = tester.widget<Container>(
        find.descendant(of: _surface, matching: find.byType(Container)).first,
      );
      expect(
        ((ink.foregroundDecoration! as BoxDecoration).border! as Border)
            .top
            .color,
        ZyraColors.journeyGold,
      );
      await tester.tap(_previous);
      await tester.tap(_request);
      expect(taps, ['request']);
      disposeSemantics();
    },
  );

  for (final width in [430.0, 393.0, 320.0]) {
    testWidgets('200 percent text wraps with stable height at $width', (
      tester,
    ) async {
      double? rowHeight;
      Rect? card;
      for (final label in _labels) {
        await _mount(tester, label: label, scale: 2, width: width);
        final height = tester.getSize(_surface).height;
        expect(height, greaterThan(56));
        rowHeight ??= height;
        expect(height, rowHeight);
        final currentCard = tester.getRect(
          _key('concept_browse_portrait_card'),
        );
        card ??= currentCard;
        expect(currentCard, card);
        expect(tester.getSize(_previous), Size(68, height));
        expect(tester.getSize(_next), Size(68, height));
        final text = find.text(label);
        final paragraph = tester.renderObject<RenderParagraph>(text);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(paragraph.size.height, lessThanOrEqualTo(height - 16));
        if (label == 'Request a Journey') {
          final painter = TextPainter(
            text: TextSpan(text: label, style: tester.widget<Text>(text).style),
            textDirection: TextDirection.ltr,
            textScaler: const TextScaler.linear(2),
          )..layout(maxWidth: paragraph.size.width);
          expect(painter.computeLineMetrics(), hasLength(2));
          painter.dispose();
        }
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets(
    'disabled request does not dispatch and default callers keep their row',
    (tester) async {
      final taps = <String>[];
      await _mount(tester, enabled: false, taps: taps);
      await tester.tap(_request);
      expect(taps, isEmpty);
      await _mount(tester, single: false);
      expect(_surface, findsNothing);
      expect(find.byType(ZyraProfilesBottomRow), findsOneWidget);
      expect(tester.getSize(_previous).width, 48);
      expect(tester.getSize(_next).width, 70);
      await _mount(tester, readOnly: true);
      expect(_surface, findsNothing);
      await _mount(tester, chrome: false);
      expect(_surface, findsNothing);
      expect(find.byType(ZyraProfilesBottomRow), findsNothing);
    },
  );
}
