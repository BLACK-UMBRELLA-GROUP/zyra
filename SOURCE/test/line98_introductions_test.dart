import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/screens/connections/zyra_sample_activity.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/state/zyra_developer_samples.dart';
import 'package:zyra/theme/zyra_text.dart';

final _samples = ZyraDeveloperSamples.instance;
const _owner = 'line98-introduction-owner';

Future<void> _bind({DateTime Function()? clock}) async {
  await ZyraAccountState.synchronize(_owner);
  _samples.bind(
    authorized: () => true,
    capacity: () => 3,
    isSeekerOne: () => true,
    clock: clock,
  );
  _samples.recordRealCounts(_owner, ZyraAccountState.generation, active: 0);
}

class _Offline extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Introduction previews must stay local.');
  }
}

Future<void> _mount(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
  });
  tearDown(() {
    _samples.clear();
    _samples.unbind();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
  });

  test('unverified introduction cannot send or enter Past', () async {
    await _bind();
    _samples.setIntroductions(1);
    final noor = _samples.introductionRows!.single;
    _samples.setUnverified(true);
    expect(_samples.canRequestIntroduction(noor), isFalse);
    expect(_samples.requestIntroduction(noor), isFalse);
    expect(_samples.sentRows, isNull);
    expect(_samples.pastIntroductions, isEmpty);
    expect(_samples.hasIntroduction(noor), isTrue);
  });

  test(
    'introduction actions keep source Guardian and newest-first Past without expiry',
    () async {
      var now = DateTime(2026, 11, 19, 12);
      await _bind(clock: () => now);
      _samples.setIntroductions(3);
      final noor = _samples.introductionRows!.first;
      final hana = _samples.introductionRows![1];
      expect(_samples.declineIntroduction(noor), isTrue);
      expect(_samples.declineIntroduction(noor), isFalse);
      expect(
        _samples.hasDeclinedIntroduction(noor.id, 'draft-guardian-hassan'),
        isTrue,
      );
      expect(
        _samples.hasDeclinedIntroduction(noor.id, 'draft-guardian-khadija'),
        isFalse,
      );
      now = now.add(const Duration(minutes: 1));
      expect(_samples.requestIntroduction(hana), isTrue);
      expect(_samples.sentRows!.single.person, same(hana));
      expect(_samples.pastIntroductions.map((r) => r.label), [
        'Journey requested',
        'You declined',
      ]);
      expect(
        _samples.pastIntroductions.last.introduction.guardianName,
        'Hassan',
      );
      expect(
        _samples.pastIntroductions.first.introduction.guardianName,
        'Khadija',
      );
      now = now.add(const Duration(days: 500));
      expect(_samples.pastIntroductions.length, 2);
      _samples.unbind();
      expect(_samples.pastIntroductions, isEmpty);
      expect(_samples.requestIntroduction(hana), isFalse);
      expect(_samples.declineIntroduction(noor), isFalse);
    },
  );

  testWidgets(
    'Introductions reuse request cards, allow one open, and move both results to Past',
    (tester) async {
      final offline = _Offline();
      await HttpOverrides.runWithHttpOverrides(() async {
        await tester.runAsync(() => _bind());
        _samples.setIntroductions(3);
        await _mount(
          tester,
          ZyraSampleIntroductionsList(wrapTitle: (title) => title),
        );
        expect(find.text('Received'), findsOneWidget);
        expect(find.text('Past'), findsOneWidget);
        // LOCK 49 adds the family card above the three one-way cards.
        expect(find.byType(ZyraRequestActivityCard), findsNWidgets(4));
        await _tap(
          tester,
          find.byKey(const ValueKey('sample-introduction-draft-noor-header')),
        );
        expect(find.text('View profile'), findsOneWidget);
        await _tap(
          tester,
          find.byKey(const ValueKey('sample-introduction-draft-hana-header')),
        );
        expect(find.text('View profile'), findsOneWidget);
        await _tap(tester, find.text('Request a Journey'));
        expect(_samples.sentRows!.single.person.id, 'draft-hana');
        expect(
          find.text('Request sent to Hana. It’s in Journey requests → Sent.'),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await _tap(
          tester,
          find.byKey(const ValueKey('sample-introduction-draft-noor-header')),
        );
        await _tap(tester, find.text('Decline'));
        expect(
          find.text('Declined. Hassan sees “Not taken forward”.'),
          findsOneWidget,
        );
        await _tap(tester, find.text('Past'));
        expect(find.byType(ZyraPastRequestActivityCard), findsNWidgets(2));
        expect(find.text('You declined'), findsOneWidget);
        expect(find.text('Journey requested'), findsOneWidget);
        expect(find.text('Introduced 9 Nov · from Hassan'), findsOneWidget);
        expect(find.text('View profile'), findsNothing);
        expect(find.text('Request a Journey'), findsNothing);
        expect(tester.takeException(), isNull);
      }, offline);
      expect(offline.attempts, 0);
    },
  );

  testWidgets(
    'empty Past uses the locked words and received profile remains read-only',
    (tester) async {
      await tester.runAsync(() => _bind());
      _samples.setIntroductions(1);
      await _mount(
        tester,
        ZyraSampleIntroductionsList(wrapTitle: (title) => title),
      );
      await _tap(tester, find.text('Past'));
      expect(find.text('No past introductions.'), findsOneWidget);
      expect(
        find.text('Introductions you declined or took forward stay here.'),
        findsOneWidget,
      );
      await _tap(tester, find.text('Received'));
      await _tap(
        tester,
        find.byKey(const ValueKey('sample-introduction-draft-noor-header')),
      );
      await _tap(tester, find.text('View profile'));
      expect(find.text('Noor Patel'), findsOneWidget);
      _samples.clear();
      await tester.pumpAndSettle();
      expect(find.text('Noor Patel'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Guardian decline is muted and belongs to the introducing Guardian only',
    (tester) async {
      await tester.runAsync(() => _bind());
      _samples.setIntroductions(1);
      _samples.declineIntroduction(_samples.introductionRows!.single);
      final state = ZyraGuardianTabsState();
      Widget guardian(String guardianId) => ZyraGuardianTabsPresentation(
        state: state,
        page: 'introductions',
        onAction: (_) {},
        photoFor: (_) => null,
        seekerGender: 'male',
        introductionDeclined: _samples.hasDeclinedIntroduction,
        introducingGuardianId: guardianId,
        madeIntroductions: _samples.guardianIntroductions(guardianId),
      );
      await _mount(tester, guardian('draft-guardian-hassan'));
      expect(find.text('Noor Patel'), findsOneWidget);
      expect(find.text('Not taken forward'), findsOneWidget);
      expect(find.text('Suggested to Adam'), findsNothing);
      final noor = tester.widget<ZyraRequestActivityIdentity>(
        find.byKey(const ValueKey('guardian_introduction_adam:noor')),
      );
      expect(noor.mutedSubtitle, isTrue);
      state.seeker = 1;
      await _mount(tester, guardian('draft-guardian-hassan'));
      expect(find.text('Not taken forward'), findsNothing);
      expect(find.text('Noor Patel'), findsNothing);
      state.seeker = 0;
      await _mount(tester, guardian('draft-guardian-khadija'));
      expect(find.text('Not taken forward'), findsNothing);
      expect(find.text('Suggested to Adam'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
