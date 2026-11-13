import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/models/journey_match.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/connections/zyra_sample_activity.dart';
import 'package:zyra/screens/profile/past_journeys_screen.dart';
import 'package:zyra/screens/home/seeker_dashboard_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/state/zyra_developer_samples.dart';
import 'package:zyra/theme/zyra_text.dart';

const _captureDir = String.fromEnvironment('ZYRA_LINE96_SAMPLE_CAPTURE_DIR');
const _captureKey = ValueKey('line96-sample-capture');
const _captureFont = 'Line96SamplePoppins';
const _user = 'sample-owner';
const _realProfile = SeekerProfile(
  id: 'real-test-profile',
  firstName: 'Test account',
  age: 30,
  city: 'London',
  photos: [],
  gender: 'female',
);
final _samples = ZyraDeveloperSamples.instance;

Future<void> _bind({int capacity = 1}) async {
  await ZyraAccountState.synchronize(_user);
  _samples.bind(authorized: () => true, capacity: () => capacity);
}

class _Offline extends HttpOverrides {
  var attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Sample activity cannot reach the network.');
  }
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _mount(WidgetTester tester, Widget child) async {
  if (_captureDir.isNotEmpty) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      builder: (context, child) =>
          RepaintBoundary(key: _captureKey, child: child!),
      home: child,
    ),
  );
  if (_captureDir.isNotEmpty) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
  }
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String state) async {
  if (_captureDir.isEmpty) return;
  await tester.runAsync(() async {
    final images = tester.widgetList<Image>(find.byType(Image));
    await Future.wait(
      images.map(
        (image) =>
            precacheImage(image.image, tester.element(find.byKey(_captureKey))),
      ),
    );
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureKey),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final png = File('$_captureDir/$state.png');
    await png.parent.create(recursive: true);
    await png.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (_captureDir.isEmpty) return;
    final font = FontLoader(_captureFont);
    for (final weight in ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
    ZyraText.testReadingFontFamily = _captureFont;
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

  test(
    'independent controls preserve explicit zero and signed-in real data',
    () async {
      await _bind();
      final real = const JourneyMatch(
        matchId: 'real',
        profile: _realProfile,
        status: 'active',
      );
      AppState.instance.setJourneyMatches(potential: [], active: [real]);
      _samples.recordRealCounts(
        _user,
        ZyraAccountState.generation,
        ended: 4,
        introductions: 2,
      );
      expect(_samples.active, isNull);
      expect(_samples.placesUsed, 1);
      _samples.setActive(3);
      _samples.setActive(2);
      expect(_samples.active, isNull);
      _samples.setActive(0);
      _samples.setEnded(3);
      _samples.setReceived(3);
      _samples.setSent(2);
      _samples.setIntroductions(3);
      _samples.setPast(ZyraDeveloperPast.samePerson);
      expect(
        (
          _samples.active,
          _samples.ended,
          _samples.received,
          _samples.sent,
          _samples.introductions,
        ),
        (0, 3, 3, 2, 3),
      );
      expect(
        _samples.history!.where(
          (row) => row.request.person.firstName == 'Sara',
        ),
        hasLength(20),
      );
      _samples.setReceived(0);
      expect(_samples.history, hasLength(22));
      expect(_samples.introductions, 3);
      _samples.clear();
      expect(_samples.hasSamples, isFalse);
      expect(
        (_samples.placesUsed, _samples.realEnded, _samples.realIntroductions),
        (1, 4, 2),
      );
      expect(AppState.instance.activeJourneys.single, same(real));
    },
  );

  test(
    'signed out, stale or unverified plan cannot accept a sample request',
    () async {
      await _bind(capacity: 0);
      _samples.setReceived(1);
      final request = _samples.receivedRows!.single;
      expect(_samples.accept(request), isNull);
      expect(_samples.capacityChoices(request), isEmpty);
      await ZyraAccountState.beginSignOut();
      expect(_samples.isAuthorized, isFalse);
      expect(_samples.receivedRows, isNull);
      expect(_samples.declineOrCancel(request), isFalse);
      ZyraAccountState.endSignOutAttempt();
      await _bind();
      expect(_samples.receivedRows, isNull);
    },
  );

  test(
    'full capacity needs explicit choice and acceptance reserves one place',
    () async {
      await _bind();
      _samples.setActive(1);
      _samples.setReceived(1);
      final old = _samples.activeRows!.single;
      final request = _samples.receivedRows!.single;
      expect(_samples.accept(request), isNull);
      final preparing = _samples.accept(request, replace: old)!;
      expect(preparing.preparing, isTrue);
      expect(_samples.placesUsed, 1);
      expect(_samples.endedRows!.single.person, old.person);
      expect(_samples.begin(preparing), isFalse);
      _samples.markReady(preparing, peer: false);
      expect(_samples.begin(preparing), isFalse);
      _samples.markReady(preparing, peer: true);
      expect(_samples.begin(preparing), isTrue);
      expect(_samples.activeRows!.single.preparing, isFalse);
    },
  );

  testWidgets(
    'requests perform Accept, Decline, Cancel and grouped Past offline',
    (tester) async {
      final network = _Offline();
      await HttpOverrides.runWithHttpOverrides(() async {
        await tester.runAsync(() async => _bind());
        _samples.setReceived(2);
        _samples.setSent(1);
        _samples.setPast(ZyraDeveloperPast.samePerson);
        await _mount(tester, const ZyraDeveloperJourneyRequestsScreen());
        await _capture(tester, 'journey_requests');
        await _tap(
          tester,
          find.byKey(const ValueKey('sample-request-true-draft-amira-header')),
        );
        await _tap(tester, find.text('Accept request'));
        expect(find.text('Choose to begin, together.'), findsOneWidget);
        expect(_samples.activeRows!.single.preparing, isTrue);
        await _tap(tester, find.byTooltip('Back'));
        await _tap(
          tester,
          find.byKey(const ValueKey('sample-request-true-draft-hana-header')),
        );
        await _tap(tester, find.text('Decline'));
        await _tap(tester, find.text('Decline').hitTestable());
        expect(_samples.received, 0);
        await _tap(tester, find.text('Sent'));
        await _tap(
          tester,
          find.byKey(
            const ValueKey('sample-request-false-draft-safiya-header'),
          ),
        );
        await _tap(tester, find.text('Cancel request'));
        await _tap(tester, find.text('Cancel request').hitTestable());
        expect(_samples.sent, 0);
        await _tap(tester, find.text('Past'));
        final group = find.text('Last sent 9 Nov · 20 requests');
        await tester.scrollUntilVisible(
          group,
          120,
          scrollable: find.byType(Scrollable).last,
        );
        await _tap(tester, group);
        expect(find.text('You can ask Sara again from 9 Dec.'), findsOneWidget);
        await _capture(tester, 'past_grouped_requests');
        await _tap(tester, find.text('Show all 20'));
        expect(find.text('Show all 20'), findsNothing);
        expect(find.text('Not taken up'), findsWidgets);
        _samples.clear();
        await tester.pumpAndSettle();
        expect(find.text('No past requests.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    },
  );

  testWidgets('Ended actions stay local and Clear reveals the real archive', (
    tester,
  ) async {
    final network = _Offline();
    await HttpOverrides.runWithHttpOverrides(() async {
      await tester.runAsync(() async => _bind());
      _samples.setEnded(2);
      final baseline = JourneyMatch(
        matchId: 'real-ended',
        profile: _realProfile,
        status: 'ended',
        endedAt: DateTime(2026, 11, 1),
      );
      await _mount(
        tester,
        PastJourneysScreen(openEnded: true, previewEnded: [baseline]),
      );
      await _capture(tester, 'ended_journeys');
      expect(find.text('Ended Journeys'), findsOneWidget);
      await _tap(tester, find.byTooltip('Journey options').first);
      await _capture(tester, 'ended_journey_options');
      await _tap(tester, find.text('Request a new Journey'));
      await _tap(tester, find.text('Send request'));
      expect(_samples.sentRows!.single.person.firstName, 'Zainab');
      await _tap(tester, find.byTooltip('Journey options').last);
      await _tap(tester, find.text('Remove from my Journeys'));
      await _tap(tester, find.text('Remove Journey'));
      expect(_samples.ended, 1);
      _samples.clear();
      await tester.pumpAndSettle();
      expect(find.text('Test account, 30'), findsOneWidget);
      expect(find.text('Zainab Malik'), findsNothing);
      expect(tester.takeException(), isNull);
    }, network);
    expect(network.attempts, 0);
  });

  testWidgets('sample Introductions open a read-only profile offline', (
    tester,
  ) async {
    final network = _Offline();
    await HttpOverrides.runWithHttpOverrides(() async {
      await tester.runAsync(() async => _bind());
      _samples.setIntroductions(2);
      await _mount(
        tester,
        Scaffold(
          body: ListenableBuilder(
            listenable: _samples,
            builder: (context, _) =>
                ZyraSampleIntroductionsList(wrapTitle: (title) => title),
          ),
        ),
      );
      await _capture(tester, 'introductions');
      expect(find.text('Put forward by Hassan · Father'), findsOneWidget);
      expect(find.text('Put forward by Khadija · Mother'), findsOneWidget);
      expect(find.text('New introduction'), findsOneWidget);
      expect(find.text('Introduced 8 Nov'), findsOneWidget);
      await _tap(tester, find.text('Noor Patel'));
      expect(find.text('Noor'), findsOneWidget);
      _samples.clear();
      await tester.pumpAndSettle();
      expect(find.text('Noor'), findsNothing);
      expect(tester.takeException(), isNull);
    }, network);
    expect(network.attempts, 0);
  });

  testWidgets('ordinary My ZYRA projects sample counts and Needs you', (
    tester,
  ) async {
    await tester.runAsync(() async => _bind(capacity: 3));
    _samples.setActive(3);
    _samples.setEnded(2);
    _samples.setReceived(2);
    _samples.setSent(1);
    _samples.setIntroductions(3);
    await _mount(
      tester,
      Scaffold(
        body: SeekerDashboardScreen(
          unreadCount: 0,
          onOpenConnections: () {},
          onOpenGuardian: () {},
          loadDashboard: () async => const DashboardSnapshot(
            role: DashboardRole.seeker,
            onboarding: DashboardSource.available([]),
            journeys: DashboardSource.available(
              DashboardJourneyState(
                summary: DashboardJourneySummary(
                  id: 'real-baseline',
                  kind: DashboardJourneyKind.searching,
                  title: 'Searching',
                ),
              ),
            ),
            updates: DashboardSource.available([]),
            guardianInvitations: DashboardSource.available([]),
            insights: DashboardSource.available([]),
            stableState: DashboardStableState(
              family: DashboardSource.available(
                DashboardFamilyStatus(
                  kind: DashboardFamilyKind.connected,
                  title: 'Guardian connected',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('2 Journey requests'), findsOneWidget);
    expect(
      find.text('Amira and Hana would like to begin a Journey with you.'),
      findsOneWidget,
    );
    expect(find.text('View requests'), findsOneWidget);
    expect(find.text('2 received · 1 sent'), findsOneWidget);
    expect(find.text('3 introductions'), findsOneWidget);
    expect(find.text('2 ended'), findsOneWidget);
    await _capture(tester, 'my_zyra');
    await tester.scrollUntilVisible(
      find.text('3 of 3 places in use'),
      140,
      scrollable:
          find
              .byKey(const ValueKey('my-zyra-quiet-scroll-0'))
              .hitTestable()
              .evaluate()
              .isNotEmpty
          ? find
                .descendant(
                  of: find.byKey(const ValueKey('my-zyra-quiet-scroll-0')),
                  matching: find.byType(Scrollable),
                )
                .first
          : find.byType(Scrollable).last,
    );
    expect(find.text('3 of 3 places in use'), findsOneWidget);
    final viewRequests = find.text('View requests');
    await tester.scrollUntilVisible(
      viewRequests,
      -180,
      scrollable: find.byType(Scrollable).last,
    );
    await _tap(tester, viewRequests);
    expect(find.text('Journey requests'), findsOneWidget);
    await _tap(tester, find.byTooltip('Back'));
    _samples.clear();
    await tester.pumpAndSettle();
    expect(find.text('2 Journey requests'), findsNothing);
    expect(find.text('3 of 3 places in use'), findsNothing);
  });
}
