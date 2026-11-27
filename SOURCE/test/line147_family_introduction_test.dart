import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_family_introduction_preview.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_action.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/screens/connections/zyra_sample_activity.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/state/zyra_developer_samples.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'support/zyra_rendered_text_contrast.dart';
import 'visual/baseline_capture_support.dart' show BaselineHarness;

final _samples = ZyraDeveloperSamples.instance;
const _capture = bool.fromEnvironment('ZYRA_LINE147_CAPTURE');
const _boundary = ValueKey('line147-capture');
const _fontName = 'Line147Poppins';

Future<void> _captureState(WidgetTester tester, String name) async {
  if (!_capture) return;
  await tester.pump(const Duration(milliseconds: 2600));
  await tester.pumpAndSettle();
  final harness = BaselineHarness(
    tester,
    group: 'line147',
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

ZyraFamilyIntroductionPreview _request({bool main = true}) =>
    ZyraFamilyIntroductionPreview(
      id: 'line147-request',
      senderSeekerId: 'draft-self',
      receiverSeekerId: 'draft-aisha',
      senderIsMain: main,
      date: DateTime(2026, 11, 24),
    );

Future<void> _bind({int capacity = 1}) async {
  await ZyraAccountState.synchronize('line147-local-owner');
  _samples.bind(
    authorized: () => true,
    capacity: () => capacity,
    isSeekerOne: () => capacity > 1,
  );
  _samples.recordRealCounts(
    'line147-local-owner',
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
  WidgetTester t,
  Widget child, {
  double scale = 1,
  Size size = const Size(430, 932),
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(
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
  await t.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final text = FontLoader(_fontName);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      text.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([text.load(), icons.load()]);
    ZyraText.testReadingFontFamily = _fontName;
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

  test('an Additional Guardian needs approval before any family reply', () {
    final row = _request(main: false);
    expect(row.phase, ZyraFamilyIntroductionPhase.needsApproval);
    expect(row.answerFamily(ZyraFamilyIntroductionReply.open), isFalse);
    expect(row.approve(yes: true), isTrue);
    expect(row.approve(yes: false), isFalse);
    expect(row.phase, ZyraFamilyIntroductionPhase.awaitingReply);
    expect(row.answerFamily(ZyraFamilyIntroductionReply.think), isTrue);
    expect(row.phase, ZyraFamilyIntroductionPhase.thinking);
    expect(row.reply?.label, 'Let us think about it');
    final rejected = _request(main: false);
    expect(rejected.approve(yes: false), isTrue);
    expect(rejected.phase, ZyraFamilyIntroductionPhase.notApproved);
    expect(rejected.answerFamily(ZyraFamilyIntroductionReply.open), isFalse);
  });

  test('a no stays private until both answer and replays cannot change it', () {
    final row = _request()..answerFamily(ZyraFamilyIntroductionReply.open);
    expect(
      row.answerSeeker(ZyraFamilyIntroductionSide.sender, yes: false),
      isTrue,
    );
    expect(row.phase, ZyraFamilyIntroductionPhase.bothFamiliesOpen);
    expect(row.hasAnswered(ZyraFamilyIntroductionSide.sender), isTrue);
    expect(row.hasAnswered(ZyraFamilyIntroductionSide.receiver), isFalse);
    expect(
      row.answerSeeker(ZyraFamilyIntroductionSide.sender, yes: true),
      isFalse,
    );
    expect(
      row.answerSeeker(ZyraFamilyIntroductionSide.receiver, yes: true),
      isTrue,
    );
    expect(row.phase, ZyraFamilyIntroductionPhase.notTakenForward);
    expect(row.reservePlaces(senderReady: true, receiverReady: true), isFalse);
  });

  test('two yes answers wait for two available places before preparation', () {
    final row = _request()..answerFamily(ZyraFamilyIntroductionReply.open);
    row.answerSeeker(ZyraFamilyIntroductionSide.sender, yes: true);
    row.answerSeeker(ZyraFamilyIntroductionSide.receiver, yes: true);
    expect(row.phase, ZyraFamilyIntroductionPhase.choosingPlace);
    expect(row.reservePlaces(senderReady: true, receiverReady: false), isFalse);
    expect(row.reservePlaces(senderReady: false, receiverReady: true), isFalse);
    expect(row.reservePlaces(senderReady: true, receiverReady: true), isTrue);
    expect(row.phase, ZyraFamilyIntroductionPhase.preparing);
  });

  for (final side in ZyraFamilyIntroductionSide.values) {
    test('Q227 $side can reopen only its own saved answer before its peer', () {
      final peer = side == ZyraFamilyIntroductionSide.sender
          ? ZyraFamilyIntroductionSide.receiver
          : ZyraFamilyIntroductionSide.sender;
      final row = _request()..answerFamily(ZyraFamilyIntroductionReply.open);
      expect(row.canChangeAnswer(side), isFalse);
      expect(row.changeAnswer(side), isFalse);
      expect(row.answerSeeker(side, yes: false), isTrue);
      expect(row.canChangeAnswer(side), isTrue);
      expect(row.canChangeAnswer(peer), isFalse);
      expect(row.changeAnswer(peer), isFalse);
      expect(row.hasAnswered(side), isTrue);
      expect(row.changeAnswer(side), isTrue);
      expect(row.hasAnswered(side), isFalse);
      expect(row.hasAnswered(peer), isFalse);
      expect(row.phase, ZyraFamilyIntroductionPhase.bothFamiliesOpen);
      expect(row.changeAnswer(side), isFalse);
      expect(row.answerSeeker(side, yes: true), isTrue);
      expect(row.answerSeeker(peer, yes: true), isTrue);
      expect(row.phase, ZyraFamilyIntroductionPhase.choosingPlace);
      expect(row.canChangeAnswer(side), isFalse);
      expect(row.canChangeAnswer(peer), isFalse);
      expect(row.changeAnswer(side), isFalse);
      expect(row.changeAnswer(peer), isFalse);
      expect(row.reservePlaces(senderReady: true, receiverReady: true), isTrue);
      expect(row.changeAnswer(side), isFalse);
    });

    test('Q227 $side cannot change a final neutral decline', () {
      final peer = side == ZyraFamilyIntroductionSide.sender
          ? ZyraFamilyIntroductionSide.receiver
          : ZyraFamilyIntroductionSide.sender;
      final row = _request()..answerFamily(ZyraFamilyIntroductionReply.open);
      row.answerSeeker(side, yes: true);
      expect(row.changeAnswer(side), isTrue);
      row.answerSeeker(side, yes: false);
      row.answerSeeker(peer, yes: true);
      expect(row.phase, ZyraFamilyIntroductionPhase.notTakenForward);
      expect(row.canChangeAnswer(side), isFalse);
      expect(row.changeAnswer(side), isFalse);
      expect(row.changeAnswer(peer), isFalse);
      expect(row.answerSeeker(side, yes: true), isFalse);
    });
  }

  for (final later in [
    ZyraFamilyIntroductionReply.open,
    ZyraFamilyIntroductionReply.no,
  ]) {
    test('Q227 thinking stays open until the later $later reply', () {
      final row = _request();
      expect(row.answerFamily(ZyraFamilyIntroductionReply.think), isTrue);
      expect(row.phase, ZyraFamilyIntroductionPhase.thinking);
      expect(row.answerFamily(ZyraFamilyIntroductionReply.think), isFalse);
      expect(
        row.answerSeeker(ZyraFamilyIntroductionSide.sender, yes: true),
        isFalse,
      );
      expect(row.answerFamily(later), isTrue);
      expect(row.reply, later);
      expect(
        row.phase,
        later == ZyraFamilyIntroductionReply.open
            ? ZyraFamilyIntroductionPhase.bothFamiliesOpen
            : ZyraFamilyIntroductionPhase.notTakenUp,
      );
      expect(row.answerFamily(ZyraFamilyIntroductionReply.think), isFalse);
      expect(row.answerFamily(later), isFalse);
    });
  }

  test(
    'a sample share is scoped, idempotent, and clears at account change',
    () async {
      await _bind();
      _samples.setIntroductions(1);
      expect(
        _samples.shareIntroduction('draft-aisha', familyId: 'missing'),
        isFalse,
      );
      expect(_samples.shareIntroduction('draft-noor'), isTrue);
      expect(_samples.shareIntroduction('draft-noor'), isTrue);
      expect(
        _samples.shareIntroduction('draft-aisha', familyId: 'sample-aisha'),
        isTrue,
      );
      expect(_samples.introductionShares, hasLength(2));
      expect(_samples.introductionShares.first.guardianName, 'Hassan');
      final row = _samples.familyIntroduction('sample-aisha')!;
      expect(_samples.familyIntroductionPerson(row)?.firstName, 'Aisha');
      await ZyraAccountState.synchronize('another-line147-owner');
      expect(_samples.introductionShares, isEmpty);
      expect(_samples.familyIntroductions, isEmpty);
      expect(
        _samples.saveFamilyIntroductionAnswer(
          row,
          side: ZyraFamilyIntroductionSide.sender,
          yes: true,
        ),
        isFalse,
      );
    },
  );

  test('one full sample place requires its exact replacement', () async {
    await _bind();
    _samples.setActive(1);
    _samples.setIntroductions(1);
    final original = _samples.activeRows!.single;
    final row = _samples.familyIntroduction('sample-aisha')!;
    _samples.saveFamilyIntroductionAnswer(
      row,
      side: ZyraFamilyIntroductionSide.sender,
      yes: true,
    );
    _samples.saveFamilyIntroductionAnswer(
      row,
      side: ZyraFamilyIntroductionSide.receiver,
      yes: true,
    );
    expect(_samples.reserveFamilyIntroduction(row), isNull);
    expect(_samples.activeRows!.single, original);
    expect(_samples.familyIntroductionPlaceChoices(row), [original]);
    final preparing = _samples.reserveFamilyIntroduction(
      row,
      replace: original,
    );
    expect(preparing?.person.firstName, 'Aisha');
    expect(preparing?.preparing, isTrue);
    expect(_samples.activeRows!.single, preparing);
    expect(_samples.endedRows!.single.person, original.person);
    expect(_samples.sentRows, isNull);
  });

  test(
    'a full peer never costs the Seeker a Journey before confirmation',
    () async {
      await _bind();
      _samples.setActive(1);
      _samples.setIntroductions(1);
      final original = _samples.activeRows!.single;
      final row = _samples.familyIntroduction('sample-aisha')!;
      _samples.saveFamilyIntroductionAnswer(
        row,
        side: ZyraFamilyIntroductionSide.sender,
        yes: true,
      );
      _samples.saveFamilyIntroductionAnswer(
        row,
        side: ZyraFamilyIntroductionSide.receiver,
        yes: true,
      );
      expect(
        _samples.holdFamilyIntroductionPlace(row, replace: original),
        isTrue,
      );
      expect(_samples.heldFamilyEnding(row), original);
      expect(_samples.activeRows!.single, original);
      expect(
        _samples.reserveFamilyIntroduction(row, replace: original),
        isNull,
      );
      expect(_samples.letFamilyIntroductionGo(row), isTrue);
      expect(_samples.confirmFamilyIntroductionPeer(row), isNull);
      expect(_samples.activeRows!.single, original);
      expect(_samples.endedRows, isNull);
    },
  );

  testWidgets('fi05 and fi06 show the fixed-rule confirmation wording', (
    t,
  ) async {
    final actions = <String>[];
    Widget page(bool main) => ZyraGuardianActionPage(
      introduction: false,
      personName: 'Aisha',
      seekerName: main ? 'Adam' : 'Yusuf',
      seekerGender: 'male',
      familyIntroduction: true,
      ownMainGuardian: main,
      onAction: actions.add,
    );
    await _mount(t, page(true));
    expect(find.text('Sent to her Main Guardian'), findsOneWidget);
    expect(find.text('They answer with a set reply'), findsOneWidget);
    expect(find.text('If both families are open'), findsOneWidget);
    expect(find.textContaining('A private chat opens'), findsNothing);
    await _captureState(t, 'fi05-main-430');
    await _tap(t, find.text('Not yet'));
    await _mount(t, page(false));
    expect(find.text('Yusuf’s Main Guardian approves first'), findsOneWidget);
    await _captureState(t, 'fi06-additional-430');
    await _tap(t, find.text('Send request'));
    expect(actions, ['back', 'connect_send']);
  });

  testWidgets('fi09 is Main-only and keeps the locked approval order', (
    t,
  ) async {
    await t.runAsync(() => _bind());
    _samples.seedReceivedFamilyIntroductions();
    final state = ZyraGuardianTabsState()..connectReceived = true;
    Widget page(bool main) => ZyraGuardianTabsPresentation(
      state: state,
      page: 'connect',
      onAction: (_) {},
      seekerGender: 'male',
      photoFor: (_) => null,
      adamMain: main,
      familyIntroductions: _samples.familyIntroductions.toList(),
    );
    await _mount(t, page(true));
    expect(find.text('Received'), findsOneWidget);
    expect(find.text('We’re open to this'), findsOneWidget);
    expect(find.text('Let us think about it'), findsOneWidget);
    expect(find.text('Not at this time'), findsOneWidget);
    expect(
      t.getTopLeft(find.text('Not now')).dx,
      lessThan(t.getTopLeft(find.text('Approve')).dx),
    );
    expect(find.text('Open chat'), findsNothing);
    await _captureState(t, 'fi09-received-430');
    await t.pumpWidget(MaterialApp(home: Scaffold(body: page(false))));
    await t.pumpAndSettle();
    expect(find.text('Received'), findsNothing);
    expect(find.text('Approve'), findsNothing);
    expect(find.text('No requests sent yet.'), findsOneWidget);
  });

  testWidgets('fi01 and fi03 keep answers private and use a paired footer', (
    t,
  ) async {
    await t.runAsync(() => _bind());
    _samples.setIntroductions(1);
    final asked = <(String, String?)>[];
    await _mount(
      t,
      ZyraSampleIntroductionsList(
        wrapTitle: (title) => title,
        onAskMyGuardians: (id, family) => asked.add((id, family)),
      ),
    );
    const header = ValueKey('family-introduction-sample-aisha-header');
    await _tap(t, find.byKey(header));
    expect(find.text('Both families agree to introduce you'), findsOneWidget);
    expect(find.text('View profile'), findsOneWidget);
    await _tap(t, find.text('Ask my Guardians'));
    expect(asked, [('draft-aisha', 'sample-aisha')]);
    final no = find.text('Not for me');
    final yes = find.text('I’d like to begin');
    expect(t.getCenter(no).dx, lessThan(t.getCenter(yes).dx));
    await _captureState(t, 'fi01-introductions-430');
    await _tap(t, no);
    expect(
      find.text('Your answer is saved · waiting for Aisha'),
      findsOneWidget,
    );
    expect(find.textContaining('Aisha won’t see your answer'), findsOneWidget);
    expect(find.text('Not for me'), findsNothing);
    expect(find.text('I’d like to begin'), findsNothing);
    await _captureState(t, 'fi03-private-waiting-430');
    await _tap(t, find.text('Demo: Aisha says yes'));
    await _tap(t, find.text('Past'));
    expect(find.text('Not taken forward'), findsOneWidget);
    expect(find.text('You declined'), findsNothing);
  });
  testWidgets('the second real Seeker answer resolves from the full profile', (
    t,
  ) async {
    await t.runAsync(() => _bind());
    _samples.setIntroductions(1);
    final row = _samples.familyIntroduction('sample-aisha')!;
    expect(
      _samples.saveFamilyIntroductionAnswer(
        row,
        side: ZyraFamilyIntroductionSide.receiver,
        yes: true,
      ),
      isTrue,
    );
    await _mount(t, ZyraSampleIntroductionsList(wrapTitle: (title) => title));
    await _tap(
      t,
      find.byKey(const ValueKey('family-introduction-sample-aisha-header')),
    );
    expect(find.textContaining('You both said yes'), findsNothing);
    await _tap(t, find.text('View profile'));
    expect(find.text('Both families agree to introduce you'), findsOneWidget);
    await _tap(t, find.text('I’d like to begin'));
    expect(row.phase, ZyraFamilyIntroductionPhase.preparing);
    expect(_samples.activeRows!.single.person.id, 'draft-aisha');
    expect(find.text('Journey with Aisha'), findsOneWidget);
  });

  testWidgets(
    'a second real decline moves to Past without revealing who declined',
    (t) async {
      await t.runAsync(() => _bind());
      _samples.setIntroductions(1);
      final row = _samples.familyIntroduction('sample-aisha')!;
      expect(
        _samples.saveFamilyIntroductionAnswer(
          row,
          side: ZyraFamilyIntroductionSide.receiver,
          yes: true,
        ),
        isTrue,
      );
      await _mount(t, ZyraSampleIntroductionsList(wrapTitle: (title) => title));
      await _tap(
        t,
        find.byKey(const ValueKey('family-introduction-sample-aisha-header')),
      );
      await _tap(t, find.text('Not for me'));
      expect(row.phase, ZyraFamilyIntroductionPhase.notTakenForward);
      await _tap(t, find.text('Past'));
      expect(find.text('Not taken forward'), findsOneWidget);
      expect(find.textContaining('You declined'), findsNothing);
      expect(_samples.activeRows, isNull);
    },
  );

  testWidgets(
    '375 with Larger Text wraps the answer pair and preserves labels',
    (t) async {
      await t.runAsync(() => _bind());
      _samples.setIntroductions(1);
      await _mount(
        t,
        ZyraSampleIntroductionsList(wrapTitle: (title) => title),
        scale: 1.7,
        size: const Size(375, 812),
      );
      await _tap(
        t,
        find.byKey(const ValueKey('family-introduction-sample-aisha-header')),
      );
      final no = find.text('Not for me');
      final yes = find.text('I’d like to begin');
      await t.ensureVisible(yes);
      await t.pumpAndSettle();
      expect(t.getCenter(no).dy, lessThan(t.getCenter(yes).dy));
      expect(t.takeException(), isNull);
      await _captureState(t, 'fi01-larger-text-375');
    },
  );
}
