// Swipe-only and accessible return for the three manual-dismiss owners.
// Invented photos, paint-only rendering and the existing local D14 Network
// fixture only: no member/provider writes, transport, storage or network reads.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/profile/seeker_profile_screen.dart';
import 'package:zyra/screens/wali/wali_gn_shared.dart';
import 'package:zyra/screens/wali/wali_network_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';

const _font = 'PoppinsManualBackTest';
const _parentKey = ValueKey('manual_back_parent');
const _openKey = ValueKey('manual_back_open');
const _backKey = ValueKey('zyra_visible_back_button');
const _edgeKey = ValueKey('zyra_back_swipe_edge');
const _translationKey = ValueKey('zyra_back_swipe_translation');
const _photoA = 'data:image/manual-back-a';
const _photoB = 'data:image/manual-back-b';
const _profile = SeekerProfile(
  id: 'manual-back-sara',
  firstName: 'Sara',
  surnameLine: 'Ahmed',
  age: 27,
  city: 'Birmingham',
  gender: 'female',
  photos: [_photoA, _photoB],
);
const _pullStart = Offset(100, 240);

enum _Host { browsePhoto, ordinaryProfile, guardianRequest }

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Manual Back checks must remain offline.');
  }
}

class _Fixture {
  _Fixture(this.host, {this.withPreview = true, this.dismissible = true})
    : choice = ValueNotifier(0);

  final _Host host;
  final bool withPreview;
  final bool dismissible;
  final ValueNotifier<int> choice;
  final navigator = GlobalKey<NavigatorState>();
  int browseReturns = 0;

  // Stable for the lifetime of the supplied photo route, like the real caller.
  // ignore: prefer_function_declarations_over_variables
  late final VoidCallback _returnPhoto = () {
    browseReturns++;
    navigator.currentState!.pop();
  };

  void checkpoint() => choice.value++;

  Widget _photoRoute() => Scaffold(
    body: host == _Host.browsePhoto
        ? ZyraOneJourneyBrowsePresentation(
            key: const ValueKey('manual_back_browse'),
            profile: _profile,
            onMenu: () {},
            showMenu: false,
            showActions: false,
            onDismiss: dismissible ? _returnPhoto : null,
            imageBuilder: (_, photo) => ColoredBox(
              key: ValueKey('manual_paint_$photo'),
              color: photo == _photoB ? Colors.teal : Colors.blueGrey,
            ),
          )
        : SeekerProfileScreen(
            key: const ValueKey('manual_back_profile'),
            profile: _profile,
            swipeDownToDismiss: dismissible,
          ),
  );

  Widget app() {
    final app = MaterialApp(
      navigatorKey: navigator,
      theme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: _font),
      ),
      home: host == _Host.guardianRequest
          ? const Scaffold(body: WaliNetworkScreen())
          : Scaffold(
              key: _parentKey,
              body: Center(
                child: ElevatedButton(
                  key: _openKey,
                  onPressed: () {
                    navigator.currentState!.push<void>(
                      MaterialPageRoute<void>(builder: (_) => _photoRoute()),
                    );
                  },
                  child: const Text('Open local profile'),
                ),
              ),
            ),
    );
    if (!withPreview) return app;
    // The provider must be above Navigator, not just below the home route:
    // ordinary pushed manual pages need the same session-local comparison.
    return ValueListenableBuilder<int>(
      valueListenable: choice,
      child: app,
      builder: (_, value, child) =>
          ZyraBackNavigationPreview(revision: value, child: child!),
    );
  }

  Finder get surface => switch (host) {
    _Host.browsePhoto => find.byKey(
      const ValueKey('concept_browse_photo_dismiss_surface'),
    ),
    _Host.ordinaryProfile => find.byKey(
      const ValueKey('connections-profile-swipe-surface'),
    ),
    _Host.guardianRequest => find.byKey(
      const Key('gn-request-page-swipe-surface'),
    ),
  };

  void expectOpen() {
    expect(surface, findsOneWidget);
    expect(navigator.currentState!.canPop(), isTrue);
  }

  void expectReturned() {
    expect(surface, findsNothing);
    expect(navigator.currentState!.canPop(), isFalse);
    expect(
      host == _Host.guardianRequest
          ? find.byKey(const Key('guardian-network-preview'))
          : find.byKey(_parentKey),
      findsOneWidget,
    );
    expect(browseReturns, host == _Host.browsePhoto ? 1 : 0);
  }

  void expectNoRequest() {
    expect(
      GNContext.instance.analytics.where(
        (entry) => entry.startsWith('request_sent'),
      ),
      isEmpty,
    );
    if (host != _Host.guardianRequest) return;
    final wards = ZyraDevScenario.composeWaliWards();
    final ward = wards.single;
    final family = GNContext.instance.familiesFor(wards, ward).first;
    expect(GNContext.instance.stageOf(ward, family), GNStage.none);
  }

  double offset(WidgetTester tester) => tester
      .widget<Transform>(find.byKey(_translationKey).first)
      .transform
      .storage[13];

  void expectSecondPhoto(WidgetTester tester) {
    if (host == _Host.browsePhoto) {
      expect(
        find.byKey(const ValueKey('manual_paint_$_photoB')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('manual_paint_$_photoA')), findsNothing);
    } else if (host == _Host.ordinaryProfile) {
      expect(
        tester.widget<ZyraProfileImage>(find.byType(ZyraProfileImage)).photo,
        _photoB,
      );
    }
  }
}

Future<void> _mount(WidgetTester tester, _Fixture fixture) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(fixture.choice.dispose);
  await tester.pumpWidget(fixture.app());
  await tester.pumpAndSettle();
  if (fixture.host == _Host.guardianRequest) {
    final speak = find.byKey(const Key('gn-speak-action'));
    await tester.ensureVisible(speak);
    await tester.tap(speak);
  } else {
    await tester.tap(find.byKey(_openKey));
  }
  await tester.pumpAndSettle();
  if (fixture.dismissible) {
    fixture.expectOpen();
  } else {
    expect(fixture.navigator.currentState!.canPop(), isTrue);
    expect(
      find.byType(
        fixture.host == _Host.browsePhoto
            ? ZyraOneJourneyBrowsePresentation
            : SeekerProfileScreen,
      ),
      findsOneWidget,
    );
  }
  fixture.expectNoRequest();
  expect(tester.takeException(), isNull);
}

Future<void> _pull(WidgetTester tester) => tester.timedDragFrom(
  _pullStart,
  const Offset(0, 260),
  const Duration(milliseconds: 650),
);

Future<TestGesture> _startBackSwipe(WidgetTester tester) async {
  final finger = await tester.startGesture(const Offset(8, 240));
  for (var step = 0; step < 6; step++) {
    await finger.moveBy(const Offset(36, 0));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 200));
  return finger;
}

VoidCallback _accessibleBack(WidgetTester tester) => tester
    .widgetList<Semantics>(
      find.byKey(const ValueKey('zyra_pull_down_back_semantics')),
    )
    .last
    .properties
    .onDismiss!;

Future<void> _back(WidgetTester tester) async {
  final finger = await _startBackSwipe(tester);
  await finger.up();
  await tester.pumpAndSettle();
}

double _slide(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(_translationKey).first)
    .transform
    .storage[12];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  late bool previousFontStubs;
  late String? previousReadingFont;

  setUpAll(() async {
    final reading = FontLoader(_font);
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });

  setUp(() {
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    previousFontStubs = ZyraText.useTestFontStubs;
    previousReadingFont = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevScenario.instance.reset();
    GNContext.instance.reset();
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    GNContext.instance.reset();
    ZyraDevScenario.instance.reset();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = previousFontStubs;
    ZyraText.testReadingFontFamily = previousReadingFont;
  });

  for (final host in _Host.values) {
    testWidgets(
      '${host.name} has edge without Back or provider; downward drag stays put',
      (tester) async {
        final fixture = _Fixture(host, withPreview: false);
        await _mount(tester, fixture);
        expect(find.byKey(_backKey), findsNothing);
        expect(find.byKey(_edgeKey), findsOneWidget);
        await _pull(tester);
        await tester.pumpAndSettle();
        fixture.expectOpen();
        await _back(tester);
        await tester.pumpAndSettle();
        fixture.expectReturned();
        fixture.expectNoRequest();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${host.name} edge swipe returns only to its own parent without Back chrome',
      (tester) async {
        final fixture = _Fixture(host);
        await _mount(tester, fixture);
        expect(find.byKey(_backKey), findsNothing);
        expect(
          find.byKey(const ValueKey('zyra_pull_down_bottom_cue')),
          findsNothing,
        );
        await _back(tester);
        await tester.pumpAndSettle();
        fixture.expectReturned();
        fixture.expectNoRequest();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${host.name} swipe-only return ignores physical downward pulls',
      (tester) async {
        final fixture = _Fixture(host);
        await _mount(tester, fixture);
        await _pull(tester);
        await tester.pumpAndSettle();
        fixture.expectOpen();
        expect(fixture.offset(tester), 0);
        expect(fixture.browseReturns, 0);
        expect(find.byKey(_backKey), findsNothing);
        fixture.expectNoRequest();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${host.name} Back edge tracks and finishes visibly before its owned return without a request',
      (tester) async {
        final fixture = _Fixture(host);
        await _mount(tester, fixture);
        expect(find.byKey(_edgeKey), findsOneWidget);
        final surfaceAtRest = tester.getRect(fixture.surface);
        final finger = await _startBackSwipe(tester);
        fixture.expectOpen();
        fixture.expectNoRequest();
        final held = _slide(tester);
        expect(held, closeTo(216, .01));
        expect(
          tester.getRect(fixture.surface).left - surfaceAtRest.left,
          closeTo(held, .01),
        );
        expect(tester.getRect(find.byKey(_edgeKey)).left, 0);
        expect(tester.getSize(find.byKey(_edgeKey)).width, 44);
        await finger.up();
        fixture.expectOpen();
        expect(fixture.browseReturns, 0);
        await tester.pump();
        expect(_slide(tester), closeTo(held, .01));
        await tester.pump(const Duration(milliseconds: 120));
        fixture.expectOpen();
        fixture.expectNoRequest();
        expect(fixture.browseReturns, 0);
        expect(_slide(tester), greaterThan(held));
        expect(_slide(tester), lessThan(430));
        await tester.pumpAndSettle();
        fixture.expectReturned();
        fixture.expectNoRequest();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${host.name} cancelled edge restores the same page and selected photo',
      (tester) async {
        final fixture = _Fixture(host);
        await _mount(tester, fixture);
        if (host != _Host.guardianRequest) {
          await tester.tapAt(const Offset(350, 240));
          await tester.pumpAndSettle();
          fixture.expectSecondPhoto(tester);
        }
        final owner = tester.state(
          find
              .ancestor(
                of: find.byKey(_edgeKey),
                matching: find.byType(ZyraPullDownCloseCue),
              )
              .first,
        );
        final finger = await _startBackSwipe(tester);
        final held = _slide(tester);
        await finger.cancel();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(_slide(tester), inExclusiveRange(0, held));
        fixture.expectOpen();
        fixture.expectNoRequest();
        await tester.pumpAndSettle();
        expect(_slide(tester), 0);
        expect(
          tester.state(
            find
                .ancestor(
                  of: find.byKey(_edgeKey),
                  matching: find.byType(ZyraPullDownCloseCue),
                )
                .first,
          ),
          same(owner),
        );
        fixture.expectSecondPhoto(tester);
        expect(fixture.browseReturns, 0);
        await _back(tester);
        await tester.pumpAndSettle();
        fixture.expectReturned();
        fixture.expectNoRequest();
      },
    );

    testWidgets(
      '${host.name} checkpoint sequence during edge finishing revokes only the pending return',
      (tester) async {
        final fixture = _Fixture(host);
        await _mount(tester, fixture);
        final finger = await _startBackSwipe(tester);
        await finger.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(_slide(tester), greaterThan(216));
        fixture.expectOpen();
        fixture.checkpoint();
        await tester.pump();
        fixture.checkpoint();
        await tester.pumpAndSettle();
        fixture.expectOpen();
        fixture.expectNoRequest();
        expect(fixture.browseReturns, 0);
        expect(_slide(tester), 0);
        await _back(tester);
        await tester.pumpAndSettle();
        fixture.expectReturned();
        fixture.expectNoRequest();
      },
    );

    testWidgets('${host.name} center swiping keeps the manual page and photo', (
      tester,
    ) async {
      final fixture = _Fixture(host);
      await _mount(tester, fixture);
      if (host != _Host.guardianRequest) {
        await tester.tapAt(const Offset(350, 240));
        await tester.pumpAndSettle();
        fixture.expectSecondPhoto(tester);
      }
      await tester.timedDragFrom(
        const Offset(160, 240),
        const Offset(180, 0),
        const Duration(milliseconds: 650),
      );
      await tester.pumpAndSettle();
      fixture.expectOpen();
      fixture.expectSecondPhoto(tester);
      fixture.expectNoRequest();
      expect(fixture.browseReturns, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '${host.name} checkpoint sequence revokes a started horizontal Back swipe',
      (tester) async {
        final fixture = _Fixture(host);
        await _mount(tester, fixture);
        final finger = await _startBackSwipe(tester);
        fixture.checkpoint();
        await tester.pump();
        fixture.checkpoint();
        await tester.pump();
        await finger.up();
        await tester.pumpAndSettle();
        fixture.expectOpen();
        fixture.expectNoRequest();
        expect(fixture.browseReturns, 0);
        await _back(tester);
        await tester.pumpAndSettle();
        fixture.expectReturned();
        fixture.expectNoRequest();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${host.name} rejects a retained Back after provider revisions',
      (tester) async {
        final fixture = _Fixture(host);
        await _mount(tester, fixture);
        final oldBack = _accessibleBack(tester);
        fixture.checkpoint();
        await tester.pumpAndSettle();
        expect(find.byKey(_backKey), findsNothing);
        fixture.checkpoint();
        await tester.pumpAndSettle();
        oldBack();
        await tester.pumpAndSettle();
        fixture.expectOpen();
        expect(fixture.browseReturns, 0);
        fixture.expectNoRequest();
        await _back(tester);
        await tester.pumpAndSettle();
        fixture.expectReturned();
        fixture.expectNoRequest();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${host.name} checkpoint during downward contact preserves page and photo',
      (tester) async {
        final fixture = _Fixture(host);
        await _mount(tester, fixture);
        if (host != _Host.guardianRequest) {
          await tester.tapAt(const Offset(350, 240));
          await tester.pumpAndSettle();
          fixture.expectSecondPhoto(tester);
        }
        final gesture = await tester.startGesture(_pullStart);
        await gesture.moveBy(const Offset(0, 60));
        await tester.pump();
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump();
        expect(fixture.offset(tester), 0);
        fixture.checkpoint();
        await tester.pump();
        expect(fixture.offset(tester), 0);
        await gesture.up();
        await tester.pumpAndSettle();
        fixture.expectOpen();
        fixture.expectSecondPhoto(tester);
        expect(fixture.browseReturns, 0);
        fixture.expectNoRequest();
        expect(find.byKey(_backKey), findsNothing);
        await _back(tester);
        await tester.pumpAndSettle();
        fixture.expectReturned();
        fixture.expectNoRequest();
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final host in _Host.values) {
    for (final method in ['VoiceOver Back', 'Escape']) {
      testWidgets('${host.name} $method returns without visible Back', (
        tester,
      ) async {
        final fixture = _Fixture(host);
        await _mount(tester, fixture);
        expect(find.byKey(_backKey), findsNothing);
        expect(
          find.byKey(const ValueKey('zyra_back_header_space')),
          findsNothing,
        );
        final retained = _accessibleBack(tester);
        if (method == 'Escape') {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        } else {
          final properties = tester
              .widgetList<Semantics>(
                find.byKey(const ValueKey('zyra_pull_down_back_semantics')),
              )
              .last
              .properties;
          properties.customSemanticsActions!.entries
              .singleWhere((entry) => entry.key.label == 'Back')
              .value();
        }
        retained();
        await tester.pumpAndSettle();
        fixture.expectReturned();
        fixture.expectNoRequest();
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final host in [_Host.browsePhoto, _Host.ordinaryProfile]) {
    testWidgets(
      '${host.name} without an eligible temporary return gets no Back',
      (tester) async {
        final fixture = _Fixture(host, dismissible: false);
        await _mount(tester, fixture);
        expect(find.byKey(_backKey), findsNothing);
        await _pull(tester);
        await tester.pumpAndSettle();
        expect(fixture.navigator.currentState!.canPop(), isTrue);
        expect(fixture.browseReturns, 0);
        expect(find.byKey(_backKey), findsNothing);
        if (host == _Host.ordinaryProfile) {
          expect(
            find.byKey(const ValueKey('seeker-profile-close')),
            findsOneWidget,
          );
        }
        fixture.expectNoRequest();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
