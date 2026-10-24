// Reuse of the existing code-entry UI with caller-owned fictional lookup only.
// Camera callbacks are injected; no platform camera, member transport, Consider
// action, invitation, telemetry or private account state is needed by this host.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_code_entry.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_known_person_code_content.dart';

const _font = 'PoppinsDraftCodeReuse';
const _fieldKey = 'known-person-code-field';
const _checkKey = 'known-person-check-code';
const _viewKey = 'draft_known_person_view';
const _differentKey = 'known-person-different-code';

Finder _key(String value) => find.byKey(ValueKey(value));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    ++attempts;
    throw StateError('The caller-owned draft code entry must remain offline.');
  }
}

class _CaptureSession {
  const _CaptureSession({
    required this.canCapture,
    required this.onCode,
    required this.onManual,
    required this.route,
  });

  final bool Function() canCapture;
  final ValueChanged<String> onCode;
  final VoidCallback onManual;
  final ModalRoute<dynamic>? route;
}

class _Camera {
  final sessions = <_CaptureSession>[];

  _CaptureSession get latest => sessions.last;

  Widget build(
    BuildContext context,
    bool Function() canCapture,
    ValueChanged<String> onCode,
    VoidCallback onManual,
  ) {
    sessions.add(
      _CaptureSession(
        canCapture: canCapture,
        onCode: onCode,
        onManual: onManual,
        route: ModalRoute.of(context),
      ),
    );
    return Center(
      key: const ValueKey('fake-code-camera'),
      child: TextButton(
        key: const ValueKey('fake-camera-manual'),
        onPressed: onManual,
        child: const Text('Enter code instead'),
      ),
    );
  }
}

Widget _app(
  Widget child, {
  GlobalKey<NavigatorState>? navigatorKey,
  double scale = 1,
}) => MaterialApp(
  navigatorKey: navigatorKey,
  theme: ThemeData.dark(),
  builder: (context, content) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      textScaler: TextScaler.linear(scale),
    ),
    child: content!,
  ),
  home: Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
      child: child,
    ),
  ),
);

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  GlobalKey<NavigatorState>? navigatorKey,
  Size size = const Size(393, 852),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _app(child, navigatorKey: navigatorKey, scale: scale),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _press(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pump();
  expect(tester.takeException(), isNull);
}

Future<void> _check(WidgetTester tester, String code) async {
  await tester.enterText(_key(_fieldKey), code);
  await _press(tester, _key(_checkKey));
}

Future<void> _scan(WidgetTester tester) =>
    _press(tester, find.text('Scan code'));

void _expectNoLegacyConsent() {
  expect(find.text('Consider'), findsNothing);
  expect(find.textContaining('normal matching process'), findsNothing);
  expect(find.textContaining('only become a Match'), findsNothing);
  expect(find.text('Interest sent'), findsNothing);
  expect(find.textContaining('Potential Journeys'), findsNothing);
}

void _expectEntry(WidgetTester tester, {String? text}) {
  expect(find.byType(ZyraKnownPersonCodeContent), findsOneWidget);
  expect(_key(_fieldKey), findsOneWidget);
  expect(_key(_viewKey), findsNothing);
  if (text != null) {
    expect(tester.widget<TextField>(_key(_fieldKey)).controller!.text, text);
  }
  _expectNoLegacyConsent();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final priorHttp = HttpOverrides.current;
  final priorFatal = WidgetController.hitTestWarningShouldBeFatal;
  final priorReadingFont = ZyraText.testReadingFontFamily;
  final priorFontStubs = ZyraText.useTestFontStubs;
  late _NoNetwork network;

  setUpAll(() async {
    final font = FontLoader(_font);
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      font.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    network = _NoNetwork();
    HttpOverrides.global = network;
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = priorHttp;
    ZyraText.useTestFontStubs = priorFontStubs;
    ZyraText.testReadingFontFamily = priorReadingFont;
    WidgetController.hitTestWarningShouldBeFatal = priorFatal;
  });

  test(
    'draft code resolution returns only the explicit canonical fixtures',
    () {
      final codes = <String>{};
      for (final person in draftProfiles) {
        final code = ZyraDraftKnownPersonCodes.codeFor(person);
        expect(code, startsWith('ZYRA-DRAFT-'));
        expect(codes.add(code), isTrue);
        expect(ZyraDraftKnownPersonCodes.resolve(code), same(person));
        expect(
          ZyraDraftKnownPersonCodes.resolve('  ${code.toLowerCase()}  '),
          same(person),
        );
      }
      expect(
        ZyraDraftKnownPersonCodes.codeFor(draftProfiles[1]),
        'ZYRA-DRAFT-SARA',
      );
      for (final nonCanonical in [
        const DraftProfile(
          id: 'real-member-id',
          firstName: 'Sara',
          age: 27,
          city: 'Birmingham',
        ),
        DraftProfile(
          id: draftProfiles[1].id,
          firstName: draftProfiles[1].firstName,
          age: draftProfiles[1].age,
          city: draftProfiles[1].city,
        ),
      ]) {
        expect(
          () => ZyraDraftKnownPersonCodes.codeFor(nonCanonical),
          throwsArgumentError,
        );
      }
      for (final rejected in [
        '',
        'Sara',
        'draft-sara',
        'ZYRA-SARA',
        'ZYRA-DRAFT-',
        'ZYRA-DRAFT-SARA-EXTRA',
        'ZYRA-DRAFT-NOT-A-FIXTURE',
        'ZYRA-AAAA-BBBB-CCCC-DDDD-EEEE',
        '43fdce1f-294d-4c0f-bef3-8f31b5e71ffb',
        'https://zyra.example/code/ZYRA-DRAFT-SARA',
      ]) {
        expect(ZyraDraftKnownPersonCodes.resolve(rejected), isNull);
      }
    },
  );

  for (final size in const [Size(390, 844), Size(393, 852), Size(430, 932)]) {
    testWidgets('shared code entry and confirmation fit $size', (tester) async {
      final person = draftProfiles[1];
      await _mount(
        tester,
        ZyraDraftCodeEntry(
          canAct: () => true,
          lookupCode: (code) async => ZyraDraftKnownPersonCodes.resolve(code),
          onViewProfile: (_) {},
          captureBuilder: _Camera().build,
        ),
        size: size,
      );
      expect(find.byType(ZyraKnownPersonCodeContent), findsOneWidget);
      final title = tester.widget<Text>(_key('draft_scan_title'));
      expect(title.data, 'Scan');
      expect(
        find.text('Scan or enter their ZYRA Code to find their profile.'),
        findsOneWidget,
      );
      expect(find.textContaining('permanent ZYRA Code'), findsNothing);
      expect(title.style!.fontFamily, ZyraText.heading(size: 28).fontFamily);
      final rect = tester.getRect(_key('draft_scan_title'));
      expect(rect.left, closeTo(20, .01));
      expect(rect.top, closeTo(75, .01));
      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: _key('draft_scan_entry_scroll'),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scroll.position.maxScrollExtent, closeTo(0, .5));
      for (final action in [find.text('Scan code'), _key(_checkKey)]) {
        expect(action.hitTestable(), findsOneWidget);
      }
      expect(tester.getRect(_key(_checkKey)).height, greaterThanOrEqualTo(44));
      await _check(tester, ZyraDraftKnownPersonCodes.codeFor(person));
      await tester.pumpAndSettle();
      expect(find.text(person.firstName), findsOneWidget);
      expect(_key(_viewKey).hitTestable(), findsOneWidget);
      expect(tester.getRect(_key(_viewKey)).height, greaterThanOrEqualTo(44));
      expect(scroll.position.maxScrollExtent, closeTo(0, .5));
      _expectNoLegacyConsent();
    });
  }

  testWidgets(
    'a manual lookup returns the exact canonical profile only on View',
    (tester) async {
      final checks = <String>[];
      final viewed = <DraftProfile>[];
      final person = draftProfiles[1];
      await _mount(
        tester,
        ZyraDraftCodeEntry(
          canAct: () => true,
          lookupCode: (code) async {
            checks.add(code);
            return ZyraDraftKnownPersonCodes.resolve(code);
          },
          onViewProfile: viewed.add,
          captureBuilder: _Camera().build,
        ),
      );
      await _check(tester, '  zyra-draft-sara  ');
      await tester.pumpAndSettle();
      expect(checks, ['zyra-draft-sara']);
      expect(viewed, isEmpty);
      expect(find.text('27 · Birmingham'), findsOneWidget);
      _expectNoLegacyConsent();
      await _press(tester, _key(_viewKey));
      expect(viewed, [same(person)]);
      expect(viewed.single.id, person.id);
      expect(viewed.single.nationalityCode, person.nationalityCode);
      expect(viewed.single.ethnicityCode, person.ethnicityCode);
      expect(viewed.single.sampleLatitude, person.sampleLatitude);
      expect(viewed.single.sampleLongitude, person.sampleLongitude);
      expect(checks, hasLength(1));
    },
  );

  testWidgets('rapid check and keyboard submissions share one pending lookup', (
    tester,
  ) async {
    final pending = Completer<DraftProfile?>();
    final checks = <String>[];
    final viewed = <DraftProfile>[];
    await _mount(
      tester,
      ZyraDraftCodeEntry(
        canAct: () => true,
        lookupCode: (code) {
          checks.add(code);
          return pending.future;
        },
        onViewProfile: viewed.add,
        captureBuilder: _Camera().build,
      ),
    );
    await tester.enterText(_key(_fieldKey), 'ZYRA-DRAFT-SARA');
    final submitted = tester.widget<TextField>(_key(_fieldKey)).onSubmitted!;
    await _press(tester, _key(_checkKey));
    await tester.tap(_key(_checkKey));
    submitted('ZYRA-DRAFT-SARA');
    submitted('ZYRA-DRAFT-SARA');
    await tester.pump();
    expect(checks, ['ZYRA-DRAFT-SARA']);
    expect(find.text('Checking…'), findsOneWidget);
    expect(viewed, isEmpty);
    pending.complete(draftProfiles[1]);
    await tester.pumpAndSettle();
    expect(_key(_viewKey), findsOneWidget);
    expect(checks, hasLength(1));
  });

  testWidgets('View returns one exact profile to the existing Browse parent', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    final viewed = <DraftProfile>[];
    await _mount(
      tester,
      const Center(child: Text('Existing Browse parent')),
      navigatorKey: navigator,
    );
    final result = navigator.currentState!.push<DraftProfile>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: ZyraDraftCodeEntry(
            canAct: () => true,
            lookupCode: (code) async => ZyraDraftKnownPersonCodes.resolve(code),
            onViewProfile: (person) {
              viewed.add(person);
              navigator.currentState!.pop(person);
            },
            captureBuilder: _Camera().build,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _check(tester, 'ZYRA-DRAFT-SARA');
    await tester.pumpAndSettle();
    final content = tester.widget<ZyraKnownPersonCodeContent>(
      find.byType(ZyraKnownPersonCodeContent),
    );
    await _press(tester, _key(_viewKey));
    content.resultAction!();
    await tester.pumpAndSettle();
    expect(await result, same(draftProfiles[1]));
    expect(viewed, [same(draftProfiles[1])]);
    expect(find.text('Existing Browse parent'), findsOneWidget);
    expect(find.byType(ZyraDraftCodeEntry), findsNothing);
    content.resultAction!();
    expect(viewed, hasLength(1));
    expect(navigator.currentState!.canPop(), isFalse);
  });

  testWidgets('editing during lookup cannot publish the old person', (
    tester,
  ) async {
    final first = Completer<DraftProfile?>();
    final checks = <String>[];
    await _mount(
      tester,
      ZyraDraftCodeEntry(
        canAct: () => true,
        lookupCode: (code) {
          checks.add(code);
          return checks.length == 1
              ? first.future
              : Future.value(ZyraDraftKnownPersonCodes.resolve(code));
        },
        onViewProfile: (_) => fail('No profile was chosen.'),
        captureBuilder: _Camera().build,
      ),
    );
    await _check(tester, 'ZYRA-DRAFT-SARA');
    await tester.enterText(_key(_fieldKey), 'ZYRA-DRAFT-AMIRA');
    first.complete(draftProfiles[1]);
    await tester.pumpAndSettle();
    _expectEntry(tester, text: 'ZYRA-DRAFT-AMIRA');
    expect(find.text('Sara'), findsNothing);
    await _press(tester, _key(_checkKey));
    await tester.pumpAndSettle();
    expect(find.text('Amira'), findsOneWidget);
    expect(checks, ['ZYRA-DRAFT-SARA', 'ZYRA-DRAFT-AMIRA']);
  });

  testWidgets(
    'lookup failures are truthful and retry does not act implicitly',
    (tester) async {
      var calls = 0;
      await _mount(
        tester,
        ZyraDraftCodeEntry(
          canAct: () => true,
          lookupCode: (code) async {
            if (++calls == 1) throw StateError('injected offline failure');
            return ZyraDraftKnownPersonCodes.resolve(code);
          },
          onViewProfile: (_) => fail('Retry only locates a profile.'),
          captureBuilder: _Camera().build,
        ),
      );
      await _check(tester, 'ZYRA-DRAFT-SARA');
      await tester.pumpAndSettle();
      expect(
        find.text("The code couldn't be checked. Please try again."),
        findsOneWidget,
      );
      _expectEntry(tester, text: 'ZYRA-DRAFT-SARA');
      await _press(tester, _key(_checkKey));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(_key(_viewKey), findsOneWidget);
      expect(find.textContaining("couldn't be checked"), findsNothing);
    },
  );

  testWidgets(
    'malformed and real unknown codes cannot resolve fixture members',
    (tester) async {
      final checks = <String>[];
      await _mount(
        tester,
        ZyraDraftCodeEntry(
          canAct: () => true,
          lookupCode: (code) async {
            checks.add(code);
            return ZyraDraftKnownPersonCodes.resolve(code);
          },
          onViewProfile: (_) =>
              fail('Unknown codes must never return a person.'),
          captureBuilder: _Camera().build,
        ),
      );
      for (final code in [
        'Sara',
        'https://zyra.example/ZYRA-DRAFT-SARA',
        'ZYRA-${'A' * 201}',
        'ZYRA-AAAA-BBBB-CCCC-DDDD-EEEE',
        'ZYRA-DRAFT-NOT-A-FIXTURE',
      ]) {
        await _check(tester, code);
        await tester.pumpAndSettle();
        expect(find.text('That code is not available.'), findsOneWidget);
        _expectEntry(tester, text: code);
      }
      expect(checks, [
        'ZYRA-AAAA-BBBB-CCCC-DDDD-EEEE',
        'ZYRA-DRAFT-NOT-A-FIXTURE',
      ]);
    },
  );

  testWidgets('Different code resets identity without looking up or acting', (
    tester,
  ) async {
    var checks = 0;
    await _mount(
      tester,
      ZyraDraftCodeEntry(
        canAct: () => true,
        lookupCode: (code) async {
          ++checks;
          return ZyraDraftKnownPersonCodes.resolve(code);
        },
        onViewProfile: (_) => fail('Reset is not View profile.'),
        captureBuilder: _Camera().build,
      ),
    );
    await _check(tester, 'ZYRA-DRAFT-SARA');
    await tester.pumpAndSettle();
    await _press(tester, _key(_differentKey));
    await tester.pumpAndSettle();
    _expectEntry(tester, text: '');
    expect(checks, 1);
    expect(find.text('Sara'), findsNothing);
    expect(find.textContaining('not available'), findsNothing);
  });

  testWidgets(
    'camera capture stays on its parent route and Manual keeps input',
    (tester) async {
      final camera = _Camera();
      var checks = 0;
      await _mount(
        tester,
        ZyraDraftCodeEntry(
          canAct: () => true,
          lookupCode: (_) async {
            ++checks;
            return null;
          },
          onViewProfile: (_) =>
              fail('Opening camera does not select a member.'),
          captureBuilder: camera.build,
        ),
      );
      await tester.enterText(_key(_fieldKey), 'ZYRA-DRAFT-SARA');
      final route = ModalRoute.of(tester.element(_key(_fieldKey)));
      await _scan(tester);
      expect(_key('fake-code-camera'), findsOneWidget);
      expect(camera.latest.route, same(route));
      expect(camera.latest.canCapture(), isTrue);
      final firstSession = camera.latest;
      await _press(tester, _key('fake-camera-manual'));
      await tester.pumpAndSettle();
      _expectEntry(tester, text: 'ZYRA-DRAFT-SARA');
      expect(firstSession.canCapture(), isFalse);
      firstSession.onCode('ZYRA-DRAFT-AMIRA');
      firstSession.onManual();
      await tester.pumpAndSettle();
      _expectEntry(tester, text: 'ZYRA-DRAFT-SARA');
      expect(checks, 0);
      await _scan(tester);
      expect(camera.latest.canCapture(), isTrue);
      firstSession.onCode('ZYRA-DRAFT-AMIRA');
      await tester.pump();
      expect(checks, 0);
      expect(_key('fake-code-camera'), findsOneWidget);
    },
  );

  testWidgets('one camera result performs one lookup and needs explicit View', (
    tester,
  ) async {
    final camera = _Camera();
    final checks = <String>[];
    final viewed = <DraftProfile>[];
    await _mount(
      tester,
      ZyraDraftCodeEntry(
        canAct: () => true,
        lookupCode: (code) async {
          checks.add(code);
          return ZyraDraftKnownPersonCodes.resolve(code);
        },
        onViewProfile: viewed.add,
        captureBuilder: camera.build,
      ),
    );
    await _scan(tester);
    final capture = camera.latest;
    capture.onCode('ZYRA-DRAFT-SARA');
    capture.onCode('ZYRA-DRAFT-AMIRA');
    capture.onManual();
    await tester.pumpAndSettle();
    expect(checks, ['ZYRA-DRAFT-SARA']);
    expect(viewed, isEmpty);
    expect(find.text('Sara'), findsOneWidget);
    expect(capture.canCapture(), isFalse);
    await _press(tester, _key(_viewKey));
    expect(viewed, [same(draftProfiles[1])]);
  });

  testWidgets(
    'camera null lookup returns to manual entry with truthful status',
    (tester) async {
      final camera = _Camera();
      await _mount(
        tester,
        ZyraDraftCodeEntry(
          canAct: () => true,
          lookupCode: (code) async => ZyraDraftKnownPersonCodes.resolve(code),
          onViewProfile: (_) => fail('Unknown code is not a profile.'),
          captureBuilder: camera.build,
        ),
      );
      await _scan(tester);
      camera.latest.onCode('ZYRA-DRAFT-NOT-A-FIXTURE');
      await tester.pumpAndSettle();
      _expectEntry(tester, text: 'ZYRA-DRAFT-NOT-A-FIXTURE');
      expect(_key('fake-code-camera'), findsNothing);
      expect(find.text('That code is not available.'), findsOneWidget);
    },
  );

  testWidgets('lookup completed under a cover stays invalid after uncovering', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    final pending = Completer<DraftProfile?>();
    await _mount(
      tester,
      ZyraDraftCodeEntry(
        canAct: () => true,
        lookupCode: (_) => pending.future,
        onViewProfile: (_) => fail('A covered lookup is stale.'),
        captureBuilder: _Camera().build,
      ),
      navigatorKey: navigator,
    );
    await _check(tester, 'ZYRA-DRAFT-SARA');
    navigator.currentState!.push<void>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Covering route')),
      ),
    );
    await tester.pumpAndSettle();
    pending.complete(draftProfiles[1]);
    await tester.pumpAndSettle();
    expect(find.text('Covering route'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    _expectEntry(tester, text: 'ZYRA-DRAFT-SARA');
    expect(find.text('Sara'), findsNothing);
  });

  testWidgets('camera callbacks are stale after cover and a new scan epoch', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    final camera = _Camera();
    var checks = 0;
    await _mount(
      tester,
      ZyraDraftCodeEntry(
        canAct: () => true,
        lookupCode: (_) async {
          ++checks;
          return draftProfiles[1];
        },
        onViewProfile: (_) => fail('A covered capture is stale.'),
        captureBuilder: camera.build,
      ),
      navigatorKey: navigator,
    );
    await _scan(tester);
    final first = camera.latest;
    navigator.currentState!.push<void>(
      MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Cover'))),
    );
    await tester.pumpAndSettle();
    expect(first.canCapture(), isFalse);
    first.onCode('ZYRA-DRAFT-SARA');
    first.onManual();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    _expectEntry(tester);
    await _scan(tester);
    expect(camera.latest.canCapture(), isTrue);
    first.onCode('ZYRA-DRAFT-SARA');
    await tester.pump();
    expect(checks, 0);
    expect(_key('fake-code-camera'), findsOneWidget);
  });

  testWidgets('an older covered lookup cannot disturb the newer check', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    final earlier = Completer<DraftProfile?>();
    final latest = Completer<DraftProfile?>();
    final checks = <String>[];
    await _mount(
      tester,
      ZyraDraftCodeEntry(
        canAct: () => true,
        lookupCode: (code) {
          checks.add(code);
          return checks.length == 1 ? earlier.future : latest.future;
        },
        onViewProfile: (_) => fail('Checking alone cannot choose a profile.'),
        captureBuilder: _Camera().build,
      ),
      navigatorKey: navigator,
    );
    await _check(tester, 'ZYRA-DRAFT-SARA');
    navigator.currentState!.push<void>(
      MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Cover'))),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await _check(tester, 'ZYRA-DRAFT-AMIRA');
    expect(checks, ['ZYRA-DRAFT-SARA', 'ZYRA-DRAFT-AMIRA']);
    earlier.complete(draftProfiles[1]);
    await tester.pumpAndSettle();
    expect(find.text('Checking…'), findsOneWidget);
    expect(_key(_viewKey), findsNothing);
    latest.complete(draftProfiles.first);
    await tester.pumpAndSettle();
    expect(find.text('Amira'), findsOneWidget);
    expect(find.text('Sara'), findsNothing);
    expect(_key(_viewKey), findsOneWidget);
  });

  testWidgets('a pending lookup cannot survive revocation and later true', (
    tester,
  ) async {
    var admitted = true;
    final pending = Completer<DraftProfile?>();
    final viewed = <DraftProfile>[];
    final entry = ZyraDraftCodeEntry(
      canAct: () => admitted,
      lookupCode: (_) => pending.future,
      onViewProfile: viewed.add,
      captureBuilder: _Camera().build,
    );
    await _mount(tester, entry);
    await _check(tester, 'ZYRA-DRAFT-SARA');
    admitted = false;
    pending.complete(draftProfiles[1]);
    await tester.pumpAndSettle();
    admitted = true;
    await tester.pumpWidget(_app(entry));
    await tester.pumpAndSettle();
    expect(_key('draft_scan_presentation'), findsNothing);
    expect(viewed, isEmpty);
  });

  testWidgets(
    'camera false ownership observation permanently revokes capture',
    (tester) async {
      var admitted = true;
      final camera = _Camera();
      var checks = 0;
      await _mount(
        tester,
        ZyraDraftCodeEntry(
          canAct: () => admitted,
          lookupCode: (_) async {
            ++checks;
            return draftProfiles[1];
          },
          onViewProfile: (_) => fail('A revoked camera cannot act.'),
          captureBuilder: camera.build,
        ),
      );
      await _scan(tester);
      final capture = camera.latest;
      admitted = false;
      expect(capture.canCapture(), isFalse);
      capture.onCode('ZYRA-DRAFT-SARA');
      admitted = true;
      expect(capture.canCapture(), isFalse);
      capture.onCode('ZYRA-DRAFT-SARA');
      capture.onManual();
      await tester.pumpAndSettle();
      expect(checks, 0);
      expect(_key(_viewKey), findsNothing);
    },
  );

  testWidgets('retained View and Reset callbacks cannot act after revocation', (
    tester,
  ) async {
    var admitted = true;
    final viewed = <DraftProfile>[];
    await _mount(
      tester,
      ZyraDraftCodeEntry(
        canAct: () => admitted,
        lookupCode: (code) async => ZyraDraftKnownPersonCodes.resolve(code),
        onViewProfile: viewed.add,
        captureBuilder: _Camera().build,
      ),
    );
    await _check(tester, 'ZYRA-DRAFT-SARA');
    await tester.pumpAndSettle();
    final content = tester.widget<ZyraKnownPersonCodeContent>(
      find.byType(ZyraKnownPersonCodeContent),
    );
    admitted = false;
    content.resultAction!();
    content.onReset();
    admitted = true;
    content.resultAction!();
    await tester.pumpAndSettle();
    expect(viewed, isEmpty);
  });

  testWidgets(
    'a prior confirmation callback cannot act after reset and recheck',
    (tester) async {
      final viewed = <DraftProfile>[];
      await _mount(
        tester,
        ZyraDraftCodeEntry(
          canAct: () => true,
          lookupCode: (code) async => ZyraDraftKnownPersonCodes.resolve(code),
          onViewProfile: viewed.add,
          captureBuilder: _Camera().build,
        ),
      );
      await _check(tester, 'ZYRA-DRAFT-SARA');
      await tester.pumpAndSettle();
      final earlier = tester.widget<ZyraKnownPersonCodeContent>(
        find.byType(ZyraKnownPersonCodeContent),
      );
      await _press(tester, _key(_differentKey));
      await tester.pumpAndSettle();
      earlier.resultAction!();
      expect(viewed, isEmpty);
      await _check(tester, 'ZYRA-DRAFT-SARA');
      await tester.pumpAndSettle();
      earlier.resultAction!();
      expect(viewed, isEmpty);
      await _press(tester, _key(_viewKey));
      expect(viewed, [same(draftProfiles[1])]);
    },
  );

  testWidgets('lookup callback rebinding invalidates its former completion', (
    tester,
  ) async {
    final revision = ValueNotifier<int>(0);
    addTearDown(revision.dispose);
    final pending = Completer<DraftProfile?>();
    final viewed = <DraftProfile>[];
    bool canAct() => true;
    Future<DraftProfile?> firstLookup(String _) => pending.future;
    Future<DraftProfile?> replacementLookup(String code) async =>
        ZyraDraftKnownPersonCodes.resolve(code);
    final ValueChanged<DraftProfile> onView = viewed.add;
    final camera = _Camera();
    final child = ValueListenableBuilder<int>(
      valueListenable: revision,
      builder: (_, value, _) => ZyraDraftCodeEntry(
        key: const ValueKey('stable-code-entry'),
        canAct: canAct,
        lookupCode: value == 0 ? firstLookup : replacementLookup,
        onViewProfile: onView,
        captureBuilder: camera.build,
      ),
    );
    await _mount(tester, child);
    await _check(tester, 'ZYRA-DRAFT-SARA');
    revision.value = 1;
    await tester.pump();
    pending.complete(draftProfiles[1]);
    await tester.pumpAndSettle();
    // A genuinely replaced lookup owns a fresh input/result lifetime.
    _expectEntry(tester);
    expect(viewed, isEmpty);
    await _check(tester, 'ZYRA-DRAFT-AMIRA');
    await tester.pumpAndSettle();
    expect(find.text('Amira'), findsOneWidget);
    expect(find.text('Sara'), findsNothing);
  });

  testWidgets('ordinary stable owner rebuild does not discard a valid check', (
    tester,
  ) async {
    final revision = ValueNotifier<int>(0);
    addTearDown(revision.dispose);
    final pending = Completer<DraftProfile?>();
    bool canAct() => true;
    Future<DraftProfile?> lookup(String _) => pending.future;
    void onView(DraftProfile _) {}
    final camera = _Camera();
    final ZyraDraftCodeCaptureBuilder capture = camera.build;
    await _mount(
      tester,
      ValueListenableBuilder<int>(
        valueListenable: revision,
        builder: (_, _, _) => ZyraDraftCodeEntry(
          canAct: canAct,
          lookupCode: lookup,
          onViewProfile: onView,
          captureBuilder: capture,
        ),
      ),
    );
    await _check(tester, 'ZYRA-DRAFT-SARA');
    revision.value = 1;
    await tester.pump();
    pending.complete(draftProfiles[1]);
    await tester.pumpAndSettle();
    expect(find.text('Sara'), findsOneWidget);
    expect(_key(_viewKey), findsOneWidget);
  });

  testWidgets('backgrounded pending lookup remains stale after resume', (
    tester,
  ) async {
    final pending = Completer<DraftProfile?>();
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await _mount(
      tester,
      ZyraDraftCodeEntry(
        canAct: () => true,
        lookupCode: (_) => pending.future,
        onViewProfile: (_) => fail('A backgrounded lookup is stale.'),
        captureBuilder: _Camera().build,
      ),
    );
    await _check(tester, 'ZYRA-DRAFT-SARA');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    pending.complete(draftProfiles[1]);
    await tester.pumpAndSettle();
    _expectEntry(tester, text: 'ZYRA-DRAFT-SARA');
    expect(find.text('Sara'), findsNothing);
  });

  testWidgets('backgrounded capture closures cannot revive after resume', (
    tester,
  ) async {
    final camera = _Camera();
    var checks = 0;
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await _mount(
      tester,
      ZyraDraftCodeEntry(
        canAct: () => true,
        lookupCode: (_) async {
          ++checks;
          return draftProfiles[1];
        },
        onViewProfile: (_) => fail('A backgrounded camera is stale.'),
        captureBuilder: camera.build,
      ),
    );
    await _scan(tester);
    final capture = camera.latest;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(capture.canCapture(), isFalse);
    capture.onCode('ZYRA-DRAFT-SARA');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(capture.canCapture(), isFalse);
    capture.onCode('ZYRA-DRAFT-SARA');
    capture.onManual();
    await tester.pumpAndSettle();
    _expectEntry(tester);
    expect(checks, 0);
    await _scan(tester);
    expect(camera.latest.canCapture(), isTrue);
  });

  testWidgets(
    'permission-prompt inactive rejects capture without losing scan',
    (tester) async {
      final camera = _Camera();
      final checks = <String>[];
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await _mount(
        tester,
        ZyraDraftCodeEntry(
          canAct: () => true,
          lookupCode: (code) async {
            checks.add(code);
            return ZyraDraftKnownPersonCodes.resolve(code);
          },
          onViewProfile: (_) {},
          captureBuilder: camera.build,
        ),
      );
      await _scan(tester);
      final capture = camera.latest;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(capture.canCapture(), isFalse);
      capture.onCode('ZYRA-DRAFT-SARA');
      capture.onManual();
      await tester.pump();
      expect(checks, isEmpty);
      expect(_key('fake-code-camera'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(capture.canCapture(), isTrue);
      capture.onCode('ZYRA-DRAFT-SARA');
      await tester.pumpAndSettle();
      expect(checks, ['ZYRA-DRAFT-SARA']);
      expect(_key(_viewKey), findsOneWidget);
    },
  );

  testWidgets('disposed pending lookup cannot publish or throw', (
    tester,
  ) async {
    final pending = Completer<DraftProfile?>();
    final viewed = <DraftProfile>[];
    await _mount(
      tester,
      ZyraDraftCodeEntry(
        canAct: () => true,
        lookupCode: (_) => pending.future,
        onViewProfile: viewed.add,
        captureBuilder: _Camera().build,
      ),
    );
    await _check(tester, 'ZYRA-DRAFT-SARA');
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(draftProfiles[1]);
    await tester.pumpAndSettle();
    expect(viewed, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'disposed camera closures cannot read a disposed text controller',
    (tester) async {
      final camera = _Camera();
      var checks = 0;
      await _mount(
        tester,
        ZyraDraftCodeEntry(
          canAct: () => true,
          lookupCode: (_) async {
            ++checks;
            return draftProfiles[1];
          },
          onViewProfile: (_) =>
              fail('A disposed camera cannot choose a person.'),
          captureBuilder: camera.build,
        ),
      );
      await _scan(tester);
      final capture = camera.latest;
      await tester.pumpWidget(const SizedBox.shrink());
      expect(capture.canCapture(), isFalse);
      capture.onCode('ZYRA-DRAFT-SARA');
      capture.onManual();
      await tester.pumpAndSettle();
      expect(checks, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an exceptional build owner guard denies permanently', (
    tester,
  ) async {
    final revision = ValueNotifier<int>(0);
    addTearDown(revision.dispose);
    var throwsNow = true;
    var checks = 0;
    bool guard() {
      if (throwsNow) throw StateError('injected build owner failure');
      return true;
    }

    Future<DraftProfile?> lookup(String _) async {
      ++checks;
      return draftProfiles[1];
    }

    void onView(DraftProfile _) =>
        fail('A failed build owner cannot select a profile.');
    final camera = _Camera();
    final ZyraDraftCodeCaptureBuilder capture = camera.build;
    await _mount(
      tester,
      ValueListenableBuilder<int>(
        valueListenable: revision,
        builder: (_, _, _) => ZyraDraftCodeEntry(
          canAct: guard,
          lookupCode: lookup,
          onViewProfile: onView,
          captureBuilder: capture,
        ),
      ),
    );
    expect(_key('draft_scan_presentation'), findsNothing);
    throwsNow = false;
    revision.value = 1;
    await tester.pumpAndSettle();
    expect(_key('draft_scan_presentation'), findsNothing);
    expect(checks, 0);
    expect(camera.sessions, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an exceptional former owner denies widget rebinding permanently',
    (tester) async {
      final revision = ValueNotifier<int>(0);
      addTearDown(revision.dispose);
      final pending = Completer<DraftProfile?>();
      var throwsFormer = false;
      var checks = 0;
      bool formerGuard() {
        if (throwsFormer) throw StateError('injected former owner failure');
        return true;
      }

      bool replacementGuard() => true;
      Future<DraftProfile?> lookup(String _) {
        ++checks;
        return pending.future;
      }

      void onView(DraftProfile _) =>
          fail('A former exceptional owner cannot transfer a pending result.');
      final camera = _Camera();
      final ZyraDraftCodeCaptureBuilder capture = camera.build;
      await _mount(
        tester,
        ValueListenableBuilder<int>(
          valueListenable: revision,
          builder: (_, value, _) => ZyraDraftCodeEntry(
            canAct: value == 0 ? formerGuard : replacementGuard,
            lookupCode: lookup,
            onViewProfile: onView,
            captureBuilder: capture,
          ),
        ),
      );
      await _check(tester, 'ZYRA-DRAFT-SARA');
      throwsFormer = true;
      revision.value = 1;
      await tester.pumpAndSettle();
      expect(_key('draft_scan_presentation'), findsNothing);
      pending.complete(draftProfiles[1]);
      await tester.pumpAndSettle();
      throwsFormer = false;
      revision.value = 2;
      await tester.pumpAndSettle();
      expect(_key('draft_scan_presentation'), findsNothing);
      expect(_key(_viewKey), findsNothing);
      expect(checks, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'an exceptional captured lookup guard denies completion permanently',
    (tester) async {
      final revision = ValueNotifier<int>(0);
      addTearDown(revision.dispose);
      final pending = Completer<DraftProfile?>();
      var completionPhase = false;
      var completionGuardReads = 0;
      bool guard() {
        if (!completionPhase) return true;
        // The current widget guard permits this completion; the separately
        // captured lookup guard then fails. Both authority checks must be safe.
        if (++completionGuardReads == 1) return true;
        throw StateError('injected captured lookup owner failure');
      }

      Future<DraftProfile?> lookup(String _) => pending.future;
      void onView(DraftProfile _) =>
          fail('An exceptional captured owner cannot publish a profile.');
      final camera = _Camera();
      final ZyraDraftCodeCaptureBuilder capture = camera.build;
      await _mount(
        tester,
        ValueListenableBuilder<int>(
          valueListenable: revision,
          builder: (_, _, _) => ZyraDraftCodeEntry(
            canAct: guard,
            lookupCode: lookup,
            onViewProfile: onView,
            captureBuilder: capture,
          ),
        ),
      );
      await _check(tester, 'ZYRA-DRAFT-SARA');
      completionPhase = true;
      pending.complete(draftProfiles[1]);
      await tester.pumpAndSettle();
      expect(completionGuardReads, greaterThanOrEqualTo(2));
      expect(_key('draft_scan_presentation'), findsNothing);
      expect(_key(_viewKey), findsNothing);
      completionPhase = false;
      revision.value = 1;
      await tester.pumpAndSettle();
      expect(_key('draft_scan_presentation'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'an exceptional retained camera guard denies capture permanently',
    (tester) async {
      final revision = ValueNotifier<int>(0);
      addTearDown(revision.dispose);
      var throwsNow = false;
      var checks = 0;
      bool guard() {
        if (throwsNow) throw StateError('injected camera owner failure');
        return true;
      }

      Future<DraftProfile?> lookup(String _) async {
        ++checks;
        return draftProfiles[1];
      }

      void onView(DraftProfile _) =>
          fail('An exceptional camera owner cannot select a profile.');
      final camera = _Camera();
      final ZyraDraftCodeCaptureBuilder captureBuilder = camera.build;
      await _mount(
        tester,
        ValueListenableBuilder<int>(
          valueListenable: revision,
          builder: (_, _, _) => ZyraDraftCodeEntry(
            canAct: guard,
            lookupCode: lookup,
            onViewProfile: onView,
            captureBuilder: captureBuilder,
          ),
        ),
      );
      await _scan(tester);
      final capture = camera.latest;
      throwsNow = true;
      expect(capture.canCapture(), isFalse);
      capture.onCode('ZYRA-DRAFT-SARA');
      capture.onManual();
      throwsNow = false;
      expect(capture.canCapture(), isFalse);
      capture.onCode('ZYRA-DRAFT-SARA');
      capture.onManual();
      revision.value = 1;
      await tester.pumpAndSettle();
      expect(_key('draft_scan_presentation'), findsNothing);
      expect(checks, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
