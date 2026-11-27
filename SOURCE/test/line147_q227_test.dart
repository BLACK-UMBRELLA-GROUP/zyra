import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_family_introduction_preview.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_one_journey_sample_photos.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/connections/zyra_sample_activity.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/state/zyra_developer_samples.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'support/zyra_rendered_text_contrast.dart';
import 'visual/baseline_capture_support.dart' show BaselineHarness;

final _samples = ZyraDeveloperSamples.instance;
const _capture = bool.fromEnvironment('ZYRA_LINE147_CAPTURE');
const _boundary = ValueKey('line147-q227-capture');
late ZyraOneJourneySamplePhotos _photos;

Future<void> _captureState(WidgetTester tester, String name) async {
  if (!_capture) return;
  await tester.pump(const Duration(milliseconds: 2600));
  await tester.pumpAndSettle();
  final harness = BaselineHarness(
    tester,
    group: 'line147_q227',
    outputRoot: 'build/line147',
    evidenceRoot: 'build/line147',
  );
  await harness.prepareRasterFrame();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final audit = await auditZyraRenderedText(
    tester,
    boundary,
    prepareBeforeCapture: harness.prepareRasterFrame,
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final output = File('build/line147/$name.png');
      await output.parent.create(recursive: true);
      await output.writeAsBytes(png!.buffer.asUint8List());
      await File(
        'build/line147/$name.json',
      ).writeAsString(jsonEncode(audit.toJson()));
    } finally {
      image.dispose();
    }
  });
  expect(audit.failures, isEmpty, reason: '$name: ${audit.failures}');
}

Future<void> _bind() async {
  await ZyraAccountState.synchronize('line147-q227-local-owner');
  _samples.bind(
    authorized: () => true,
    capacity: () => 1,
    isSeekerOne: () => false,
  );
  _samples.recordRealCounts(
    'line147-q227-local-owner',
    ZyraAccountState.generation,
    active: 0,
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  required double width,
  required double scale,
}) async {
  tester.view.physicalSize = Size(width, width == 430 ? 932 : 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: RepaintBoundary(
        key: _boundary,
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String? _photoFor(String id) {
  final index = draftProfiles.indexWhere((person) => person.id == 'draft-$id');
  return index < 0 ? null : _photos.forIndex(index).first;
}

Widget _guardianPage(ZyraGuardianTabsState state, List<String> actions) =>
    ZyraGuardianTabsPresentation(
      state: state,
      page: 'connect',
      onAction: actions.add,
      seekerGender: 'male',
      photoFor: _photoFor,
      familyIntroductions: _samples.familyIntroductions.toList(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final text = FontLoader('Line147Q227Poppins');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      text.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([text.load(), icons.load()]);
    _photos = await ZyraOneJourneySamplePhotos.load();
    ZyraText.testReadingFontFamily = 'Line147Q227Poppins';
  });

  tearDownAll(() => ZyraText.testReadingFontFamily = null);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
  });

  tearDown(() {
    _samples.unbind();
    AppState.instance.resetForAccountChange();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
  });

  for (final setting in [(430.0, 1.0), (375.0, 2.0)]) {
    final (width, scale) = setting;
    final suffix = '${width.toInt()}-${scale == 1 ? 'normal' : 'larger'}';

    testWidgets('Q227 Change my answer resaves privately $suffix', (
      tester,
    ) async {
      await tester.runAsync(() => _bind());
      _samples.setIntroductions(1);
      final row = _samples.familyIntroduction('sample-aisha')!;
      final person = draftProfiles.firstWhere((p) => p.id == 'draft-aisha');
      await tester.runAsync(() async {
        for (
          var attempt = 0;
          _samples.profileFor(person).photos.isEmpty && attempt < 200;
          attempt++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      expect(_samples.profileFor(person).photos, isNotEmpty);
      await _mount(
        tester,
        ZyraSampleIntroductionsList(wrapTitle: (title) => title),
        width: width,
        scale: scale,
      );
      await _tap(
        tester,
        find.byKey(const ValueKey('family-introduction-sample-aisha-header')),
      );
      await _tap(tester, find.text('Not for me'));
      expect(row.hasAnswered(ZyraFamilyIntroductionSide.sender), isTrue);
      expect(row.hasAnswered(ZyraFamilyIntroductionSide.receiver), isFalse);
      expect(
        find.textContaining('Aisha won’t see your answer'),
        findsOneWidget,
      );
      expect(find.text('Not for me'), findsNothing);
      await tester.ensureVisible(find.text('Change my answer'));
      await tester.pumpAndSettle();
      await _captureState(tester, 'fi03-q227-saved-$suffix');
      final card = tester.widget<ZyraRequestActivityCard>(
        find.byKey(const ValueKey('family-introduction-sample-aisha')),
      );
      final staleChange = card.quietAction!.onTap!;
      await _tap(tester, find.text('Change my answer'));
      expect(row.hasAnswered(ZyraFamilyIntroductionSide.sender), isFalse);
      expect(find.text('Change my answer'), findsNothing);
      expect(
        find.text('Your answer is saved · waiting for Aisha'),
        findsNothing,
      );
      expect(find.text('Not for me'), findsOneWidget);
      expect(find.text('I’d like to begin'), findsOneWidget);
      await tester.ensureVisible(find.text('I’d like to begin'));
      await tester.pumpAndSettle();
      await _captureState(tester, 'fi01-q227-reopened-$suffix');
      await _tap(tester, find.text('I’d like to begin'));
      expect(row.hasAnswered(ZyraFamilyIntroductionSide.sender), isTrue);
      expect(find.text('Change my answer'), findsOneWidget);
      expect(
        find.text('Your answer is saved · waiting for Aisha'),
        findsOneWidget,
      );
      await _tap(tester, find.text('Demo: Aisha says no'));
      expect(row.phase, ZyraFamilyIntroductionPhase.notTakenForward);
      expect(find.text('Change my answer'), findsNothing);
      staleChange();
      await tester.pumpAndSettle();
      expect(row.phase, ZyraFamilyIntroductionPhase.notTakenForward);
      expect(row.hasAnswered(ZyraFamilyIntroductionSide.sender), isTrue);
      expect(_samples.activeRows, isNull);
      await _tap(tester, find.text('Past'));
      expect(find.text('Not taken forward'), findsOneWidget);
      expect(find.textContaining('You declined'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Q227 Sent keeps the thinking reply $suffix', (tester) async {
      await tester.runAsync(() => _bind());
      expect(
        _samples.sendFamilyIntroduction(
          seekerId: 'draft-self',
          peerId: 'draft-aisha',
          main: true,
        ),
        isTrue,
      );
      final row = _samples.familyIntroductions.single;
      expect(
        _samples.answerFamilyIntroduction(
          row,
          ZyraFamilyIntroductionReply.think,
        ),
        isTrue,
      );
      final actions = <String>[];
      await _mount(
        tester,
        _guardianPage(ZyraGuardianTabsState(), actions),
        width: width,
        scale: scale,
      );
      expect(
        find.text('They replied: “Let us think about it”'),
        findsOneWidget,
      );
      expect(find.text('Waiting for a response'), findsNothing);
      expect(find.text('You replied: “Let us think about it”'), findsNothing);
      expect(find.text('We’re open to this'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      await _captureState(tester, 'fi11-q227-thinking-$suffix');
      await _tap(tester, find.text('Demo: they reply “We’re open to this”'));
      expect(actions, ['family_introduction:open:${row.id}:thinking']);
      expect(row.phase, ZyraFamilyIntroductionPhase.thinking);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Q227 Received thinking keeps the later answer pair $suffix', (
      tester,
    ) async {
      await tester.runAsync(() => _bind());
      _samples.seedReceivedFamilyIntroductions();
      final row = _samples.familyIntroduction('received-noor')!;
      expect(
        _samples.answerFamilyIntroduction(
          row,
          ZyraFamilyIntroductionReply.think,
        ),
        isTrue,
      );
      final actions = <String>[];
      await _mount(
        tester,
        _guardianPage(ZyraGuardianTabsState()..connectReceived = true, actions),
        width: width,
        scale: scale,
      );
      expect(find.text('You replied: “Let us think about it”'), findsOneWidget);
      expect(find.text('They replied: “Let us think about it”'), findsNothing);
      expect(find.text('Let us think about it'), findsNothing);
      final no = find.text('Not at this time');
      final yes = find.text('We’re open to this');
      expect(no, findsOneWidget);
      expect(yes, findsOneWidget);
      if (scale == 1) {
        expect(tester.getCenter(no).dx, lessThan(tester.getCenter(yes).dx));
      } else {
        expect(tester.getCenter(no).dy, lessThan(tester.getCenter(yes).dy));
      }
      expect(find.byType(TextField), findsNothing);
      await _captureState(tester, 'fi12-q227-thinking-$suffix');
      await _tap(tester, no);
      expect(actions, ['family_introduction:no:received-noor:thinking']);
      await _tap(tester, yes);
      expect(actions.last, 'family_introduction:open:received-noor:thinking');
      expect(row.phase, ZyraFamilyIntroductionPhase.thinking);
      expect(tester.takeException(), isNull);
    });
  }
}
