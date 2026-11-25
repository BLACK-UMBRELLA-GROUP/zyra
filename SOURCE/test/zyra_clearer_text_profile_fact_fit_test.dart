import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_reference_data.dart';
import 'package:zyra/dev/zyra_signup_preview.dart';
import 'package:zyra/dev/zyra_signup_preview_controller.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';

const _report = String.fromEnvironment('ZYRA_LINE126_FACT_FIT_REPORT');
const _font = 'Q191Poppins';
const _boundary = ValueKey('fact-fit-boundary');
final _rows = <Map<String, Object?>>[];

Future<void> _mount(
  WidgetTester tester,
  SeekerProfile profile,
  double width,
  double scale, {
  bool bold = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, width == 430 ? 932 : 667);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: TextScaler.linear(scale),
          boldText: bold,
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: RepaintBoundary(
          key: _boundary,
          child: ZyraBrowseDesigns(
            profiles: [profile],
            selectedIndex: 0,
            design: ZyraOneJourneyBrowseDesign.portraitCard,
            photoBuilder:
                (
                  context,
                  photo, {
                  required width,
                  required height,
                  required alignment,
                }) => const ColoredBox(color: Colors.teal),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Map<String, double> _rect(Rect rect) => {
  'left': rect.left,
  'top': rect.top,
  'width': rect.width,
  'height': rect.height,
};

void main() {
  setUpAll(() async {
    final font = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await font.load();
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });
  tearDownAll(() {
    if (_report.isNotEmpty) {
      final file = File(_report);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode({'rows': _rows}));
    }
  });

  for (final basic in [false, true]) {
    for (final width in [430.0, 375.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('Fact tiles basic=$basic at $width/$scale', (tester) async {
          final previousShadows = debugDisableShadows;
          try {
            debugDisableShadows = false;
            final profile = SeekerProfile(
              id: 'fact-fit',
              firstName: 'Sara',
              surnameLine: 'Ahmed',
              age: 27,
              city: 'Birmingham',
              publicNationality: 'British',
              publicEthnicity: 'South Asian',
              gender: 'female',
              photos: const ['admitted-photo'],
              seekerPlan: basic ? ZyraPlan.basic : ZyraPlan.one,
            );
            await _mount(tester, profile, width, scale);
            final facts = [
              ('AGE', '27'),
              ('LOCATION', profile.city),
              ('NATIONALITY', profile.publicNationality!),
              ('ETHNICITY', profile.publicEthnicity!),
            ];
            final rectangles = <String, Rect>{};
            final fullRows = <String>[];
            final page = tester.getRect(
              find.byKey(const ValueKey('concept_browse_details_fact-fit')),
            );
            final fullWidth = page.width - 32;
            final halfWidth = (fullWidth - 10) / 2;
            for (final fact in facts) {
              final tile = find.byKey(
                ValueKey('profile-detail-tile-${fact.$1}'),
              );
              final rect = tester.getRect(tile);
              rectangles[fact.$1] = rect;
              final texts = find.descendant(
                of: tile,
                matching: find.byType(Text),
              );
              expect(texts, findsNWidgets(2));
              var needsFullRow = false;
              for (var index = 0; index < 2; index++) {
                final finder = texts.at(index);
                final widget = tester.widget<Text>(finder);
                final render = tester.renderObject<RenderParagraph>(
                  find.descendant(of: finder, matching: find.byType(RichText)),
                );
                final original = index == 0 ? fact.$1 : fact.$2;
                final display = render.text.toPlainText();
                expect(display.replaceAll(RegExp(r'\s+'), ' '), original);
                expect(widget.style!.fontSize, index == 0 ? 11 : 15);
                expect(widget.style!.fontWeight, FontWeight.w400);
                expect(widget.style!.letterSpacing, index == 0 ? 1.1 : 0);
                expect(widget.textScaler, isNull);
                expect(widget.maxLines, isNull);
                expect(render.didExceedMaxLines, isFalse);
                for (final word in RegExp(r'\S+').allMatches(display)) {
                  final boxes = render.getBoxesForSelection(
                    TextSelection(
                      baseOffset: word.start,
                      extentOffset: word.end,
                    ),
                  );
                  expect(boxes, isNotEmpty);
                  expect(
                    boxes.every(
                      (box) => (box.top - boxes.first.top).abs() < .01,
                    ),
                    isTrue,
                    reason: '$width/$scale split ${word.group(0)}',
                  );
                  final painter = TextPainter(
                    text: TextSpan(
                      text: word.group(0),
                      style: render.text.style,
                    ),
                    textScaler: render.textScaler,
                    textDirection: render.textDirection,
                  )..layout();
                  needsFullRow |= painter.width > halfWidth - 30;
                  expect(
                    painter.width,
                    lessThanOrEqualTo(rect.width - 30 + .01),
                  );
                  final textRect = tester.getRect(finder);
                  expect(
                    boxes.every(
                      (box) =>
                          textRect.left + box.left >= rect.left + 14 - .01 &&
                          textRect.left + box.right <= rect.right - 14 + .01,
                    ),
                    isTrue,
                    reason:
                        '$width/$scale keeps ${word.group(0)} inside its tile',
                  );
                  painter.dispose();
                }
              }
              expect(
                rect.width,
                closeTo(needsFullRow ? fullWidth : halfWidth, .01),
              );
              if (needsFullRow) fullRows.add(fact.$1);
            }
            for (var i = 0; i < facts.length; i++) {
              if (!fullRows.contains(facts[i].$1)) continue;
              final full = rectangles[facts[i].$1]!;
              expect(full.left, closeTo(page.left + 16, .01));
              for (var j = 0; j < i; j++) {
                expect(
                  full.top,
                  greaterThanOrEqualTo(rectangles[facts[j].$1]!.bottom + 10),
                );
              }
              for (var j = i + 1; j < facts.length; j++) {
                expect(
                  rectangles[facts[j].$1]!.top,
                  greaterThanOrEqualTo(full.bottom + 10),
                );
              }
            }
            final avatar = tester.getSize(
              find.byKey(
                const ValueKey('concept_browse_details_avatar_fact-fit'),
              ),
            );
            expect(avatar.width, inInclusiveRange(72.0, 150.0));
            expect(avatar.height, avatar.width);
            if (width == 430 && scale == 1) {
              expect(fullRows, isEmpty);
              expect(rectangles['AGE']!.top, rectangles['LOCATION']!.top);
              expect(
                rectangles['NATIONALITY']!.top,
                rectangles['ETHNICITY']!.top,
              );
              expect(
                rectangles['LOCATION']!.left - rectangles['AGE']!.right,
                10,
              );
              expect(
                rectangles['NATIONALITY']!.top - rectangles['AGE']!.bottom,
                10,
              );
            }
            String? raster;
            if (width == 430 && scale == 1) {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(_boundary),
              );
              raster = await tester.runAsync(() async {
                final image = await boundary.toImage(pixelRatio: 1);
                try {
                  final bytes = await image.toByteData(
                    format: ui.ImageByteFormat.rawRgba,
                  );
                  return sha256.convert(bytes!.buffer.asUint8List()).toString();
                } finally {
                  image.dispose();
                }
              });
            }
            _rows.add({
              'basic': basic,
              'width': width,
              'scale': scale,
              'full_rows': fullRows,
              'tiles': rectangles.map(
                (key, rect) => MapEntry(key, _rect(rect)),
              ),
              '430_normal_raster_sha256': raster,
            });
          } finally {
            debugDisableShadows = previousShadows;
          }
        });
      }
    }
  }

  for (final (city, bold) in [
    ('Northern Stratford-upon-Avon', false),
    ('Birmingham', true),
  ]) {
    testWidgets('Whole fact words retain stored hyphens and bold=$bold', (
      tester,
    ) async {
      final profile = SeekerProfile(
        id: 'fact-words',
        firstName: 'Sara',
        age: 27,
        city: city,
        gender: 'female',
        photos: const ['admitted-photo'],
      );
      await _mount(tester, profile, 375, 1.3, bold: bold);
      final tile = find.byKey(const ValueKey('profile-detail-tile-LOCATION'));
      final page = tester.getRect(
        find.byKey(const ValueKey('concept_browse_details_fact-words')),
      );
      expect(tester.getSize(tile).width, closeTo(page.width - 32, .01));
      final value = find
          .descendant(of: tile, matching: find.byType(Text))
          .at(1);
      final widget = tester.widget<Text>(value);
      final render = tester.renderObject<RenderParagraph>(
        find.descendant(of: value, matching: find.byType(RichText)),
      );
      final display = render.text.toPlainText();
      expect(display.replaceAll(RegExp(r'\s+'), ' '), city);
      expect(widget.style!.fontSize, 15);
      expect(
        render.text.style!.fontWeight,
        bold ? FontWeight.bold : FontWeight.w400,
      );
      if (!bold && display != city) {
        expect(display, 'Northern\nStratford-upon-Avon');
        expect(widget.semanticsLabel, city);
        expect(widget.softWrap, isFalse);
      }
      for (final word in RegExp(r'\S+').allMatches(display)) {
        final boxes = render.getBoxesForSelection(
          TextSelection(baseOffset: word.start, extentOffset: word.end),
        );
        expect(boxes, isNotEmpty);
        expect(
          boxes.every((box) => (box.top - boxes.first.top).abs() < .01),
          isTrue,
          reason: 'The whole word ${word.group(0)} remains on one line.',
        );
        final textRect = tester.getRect(value);
        final tileRect = tester.getRect(tile);
        expect(
          boxes.every(
            (box) =>
                textRect.left + box.left >= tileRect.left + 14 - .01 &&
                textRect.left + box.right <= tileRect.right - 14 + .01,
          ),
          isTrue,
        );
      }
    });
  }

  testWidgets('multiword fact values stay half width when every word fits', (
    tester,
  ) async {
    const profile = SeekerProfile(
      id: 'short-fact-words',
      firstName: 'Sara',
      age: 27,
      city: 'New York City',
      gender: 'female',
      photos: ['admitted-photo'],
    );
    await _mount(tester, profile, 375, 1.3);
    final page = tester.getRect(
      find.byKey(const ValueKey('concept_browse_details_short-fact-words')),
    );
    final tile = tester.getRect(
      find.byKey(const ValueKey('profile-detail-tile-LOCATION')),
    );
    expect(tile.width, closeTo((page.width - 42) / 2, .01));
    expect(
      tile.top,
      tester.getRect(find.byKey(const ValueKey('profile-detail-tile-AGE'))).top,
    );
  });

  testWidgets('Birmingham uses a full row and one whole line at 200%', (
    tester,
  ) async {
    const profile = SeekerProfile(
      id: 'long-fact-word',
      firstName: 'Sara',
      age: 27,
      city: 'Birmingham',
      gender: 'female',
      photos: ['admitted-photo'],
    );
    await _mount(tester, profile, 375, 2);
    final tile = find.byKey(const ValueKey('profile-detail-tile-LOCATION'));
    final page = tester.getRect(
      find.byKey(const ValueKey('concept_browse_details_long-fact-word')),
    );
    expect(tester.getSize(tile).width, closeTo(page.width - 32, .01));
    final value = find.descendant(of: tile, matching: find.text('Birmingham'));
    expect(value, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: value, matching: find.byType(RichText)),
    );
    final boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 10),
    );
    expect(boxes, isNotEmpty);
    expect(
      boxes.every((box) => (box.top - boxes.first.top).abs() < .01),
      isTrue,
    );
    final textRect = tester.getRect(value);
    final tileRect = tester.getRect(tile);
    expect(
      boxes.every(
        (box) =>
            textRect.left + box.left >= tileRect.left + 14 - .01 &&
            textRect.left + box.right <= tileRect.right - 14 + .01,
      ),
      isTrue,
    );
  });

  testWidgets('fixed fact lists fit the full-row text room at 375 and 200%', (
    tester,
  ) async {
    // Read the actual preview picker choices. This also covers the ethnicity
    // samples absent from zyraEthnicityNames, without duplicating town data or
    // introducing a production API solely for this test.
    final picker = ZyraSignupPreviewController();
    addTearDown(picker.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    final sampleLists = <ZyraSignupStep, Set<String>>{};
    Set<String> visibleChoices() => {
      for (final widget in tester.widgetList<InkWell>(find.byType(InkWell)))
        if (widget.key case ValueKey<String>(
          value: final value,
        ) when value.startsWith('signup_choice_'))
          value.substring('signup_choice_'.length),
    };
    for (final step in [
      ZyraSignupStep.location,
      ZyraSignupStep.nationality,
      ZyraSignupStep.ethnicity,
    ]) {
      picker.setStep(step);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZyraSignupPreview(
              key: ValueKey(step),
              controller: picker,
              canAct: () => true,
              preferencesBuilder: (_) => const SizedBox.shrink(),
              onPause: () {},
              onEnter: () {},
              onShareCode: () {},
              samplePhotos: const [],
              ownCode: '',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      sampleLists[step] = visibleChoices();
      expect(sampleLists[step], isNotEmpty);
      if (step == ZyraSignupStep.location) {
        expect(sampleLists[step], hasLength(6));
        final stored = <String>{};
        for (final choice in sampleLists[step]!) {
          tester
              .widget<InkWell>(find.byKey(ValueKey('signup_choice_$choice')))
              .onTap!();
          stored.add(picker.location!);
          await tester.pump();
        }
        sampleLists[step] = stored;
      } else if (step == ZyraSignupStep.ethnicity) {
        // The seven sample options are paged six at a time; British is the
        // seventh and is admitted by the same search field as the app uses.
        await tester.enterText(
          find.byKey(const ValueKey('signup_search')),
          'British',
        );
        await tester.pump();
        sampleLists[step]!.addAll(visibleChoices());
        expect(sampleLists[step], contains('British'));
      }
    }
    final today = DateTime(2026, 11, 25);
    final ages = <String>{};
    final birth = ZyraSignupPreviewController(now: () => today)
      ..setStep(ZyraSignupStep.dateOfBirth)
      ..setDay('1')
      ..setMonth('1');
    for (var year = 1; year <= today.year; year++) {
      birth.setYear('$year'.padLeft(4, '0'));
      if (birth.canContinue) ages.add('${birth.age}');
    }
    birth.dispose();
    expect(ages, isNotEmpty);
    final lists = {
      'AGE': ages,
      'LOCATION': sampleLists[ZyraSignupStep.location]!,
      'NATIONALITY': {
        ...zyraNationalityNames,
        ...sampleLists[ZyraSignupStep.nationality]!,
      },
      'ETHNICITY': {
        ...zyraEthnicityNames,
        ...sampleLists[ZyraSignupStep.ethnicity]!,
      },
    };
    const profile = SeekerProfile(
      id: 'fixed-list-room',
      firstName: 'Sara',
      age: 27,
      city: 'Birmingham',
      gender: 'female',
      photos: ['admitted-photo'],
    );
    for (final bold in [false, true]) {
      await _mount(tester, profile, 375, 2, bold: bold);
      final tile = find.byKey(const ValueKey('profile-detail-tile-LOCATION'));
      final room = tester.getSize(tile).width - 30;
      final value = find.descendant(
        of: tile,
        matching: find.text('Birmingham'),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: value, matching: find.byType(RichText)),
      );
      for (final list in lists.entries) {
        var longestWord = '';
        var longestWidth = 0.0;
        final words = {
          for (final choice in list.value)
            ...choice.split(RegExp(r'\s+')).where((word) => word.isNotEmpty),
        };
        for (final word in words) {
          final painter = TextPainter(
            text: TextSpan(text: word, style: paragraph.text.style),
            textScaler: paragraph.textScaler,
            textDirection: paragraph.textDirection,
          )..layout();
          final width = painter.width;
          painter.dispose();
          if (width > longestWidth) {
            longestWord = word;
            longestWidth = width;
          }
          expect(
            width,
            lessThanOrEqualTo(room + .01),
            reason:
                'QUESTION Q221: ${list.key} word "$word" needs $width pt '
                'but full-row text room is $room pt at 375/200%, bold=$bold. '
                'Refer the list to ZYRA Claude; do not alter the layout.',
          );
        }
        _rows.add({
          'list': list.key,
          'bold': bold,
          'width': 375,
          'scale': 2,
          'words_checked': words.length,
          'longest_word': longestWord,
          'longest_word_width': longestWidth,
          'full_row_text_room': room,
        });
      }
    }
  });
}
