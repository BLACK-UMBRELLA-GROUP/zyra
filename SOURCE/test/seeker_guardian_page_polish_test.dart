// Presentation-only polish. Server permission producers, link mutations and
// native accessibility acceptance remain independently owned.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';

const _font = 'PoppinsGuardianPagePolish';
const _captures = String.fromEnvironment(
  'ZYRA_GUARDIAN_POLISH_CAPTURE_DIRECTORY',
);
const _captureRoot = ValueKey('guardian-polish-capture');
final _main = WaliLinkedPerson(
  id: 'hassan-main',
  firstName: 'Hassan',
  isMain: true,
  relationship: 'father',
  linkedAt: DateTime.utc(2026, 9, 20),
);
final _additional = WaliLinkedPerson(
  id: 'yusuf-additional',
  firstName: 'Yusuf',
  relationship: 'uncle',
  linkedAt: DateTime.utc(2026, 9, 23),
);
const _unrecorded = WaliLinkedPerson(id: 'unrecorded', firstName: 'Amina');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Guardian polish fixtures must stay offline.');
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));
Finder _currentPage(String id) => _key('guardian-page-static-$id');

Future<ZyraSourceResult<GuardianHistoryConsentState>> _history({
  required String guardianId,
  required bool guardianIsMain,
  bool? enabled,
}) async => ZyraSourceResult.available(
  GuardianHistoryConsentState(
    enabled: enabled ?? false,
    activeGuardianLinkId: 'fixture-link-$guardianId',
    guardianId: guardianId,
    guardianIsMain: guardianIsMain,
  ),
);

Widget _page({
  List<WaliLinkedPerson>? people,
  bool preview = true,
  bool linksAvailable = true,
  GuardianPageJourneyAccessLoader? accessLoader,
  VoidCallback? onRetry,
  int activeJourneyCount = 3,
}) => SeekerGuardianPage(
  people: people ?? [_main, _additional],
  activity: const {},
  linksAvailable: linksAvailable,
  activityAvailable: true,
  onRetry: onRetry ?? () {},
  onAdd: () {},
  historyConsentPreview: preview,
  previewActiveJourneyCount: activeJourneyCount,
  historyConsentLoader: _history,
  journeyAccessLoader: accessLoader,
  pendingInvitesLoader: () async =>
      const ZyraSourceResult.available(<PendingInvite>[]),
  titleSize: 26,
);

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(393, 852),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _captureRoot, child: child!),
      ),
      home: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(bottom: false, child: child),
              FloatingNavBar(
                items: const [
                  FloatingNavItem(icon: Icons.search, label: 'Browse'),
                  FloatingNavItem(icon: Icons.route_outlined, label: 'Journey'),
                  FloatingNavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'My ZYRA',
                  ),
                  FloatingNavItem(
                    icon: Icons.gpp_good_outlined,
                    label: 'Guardian',
                  ),
                  FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
                ],
                currentIndex: 3,
                onTap: (_) {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nextGuardian(WidgetTester tester) async {
  await tester.drag(_key('guardian-page-view'), const Offset(-330, 0));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captures.isEmpty) return;
  expect(_captures.startsWith('/'), isTrue);
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureRoot),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_captures/$name.png');
      await file.create(exclusive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void _expectNoSteadyInstructions() {
  expect(
    find.text('View access is required for every active Journey.'),
    findsNothing,
  );
  expect(find.text('Choose access separately for each Journey.'), findsNothing);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('main empty marks and linked-summary copy actual frames', (
    tester,
  ) async {
    await _mount(tester, _page(activeJourneyCount: 0));
    await _capture(tester, 'main_empty_locked_ticks');
    await _nextGuardian(tester);
    await _capture(tester, 'additional_empty_unset');
    await tester.tap(_key('guardian-history-consent-details-toggle'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Right now Yusuf only sees Journeys from the day he was linked onwards. Turn this on to also show him the ones before that.',
      ),
      findsOneWidget,
    );
    await _capture(tester, 'past_summary_yusuf_copy');
  });
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;

  setUpAll(() async {
    final reading = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });

  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevScenario.instance.reset();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraColors.restoreAppSurfaceStyle(null);
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    HttpOverrides.global = previousNetwork;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDevScenario.instance.reset();
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    expect(network.attempts, 0);
  });

  for (final sample
      in <
        ({
          String name,
          String? relationship,
          String subject,
          String object,
          bool plural,
        })
      >[
        (
          name: 'Amina',
          relationship: 'uncle',
          subject: 'he',
          object: 'him',
          plural: false,
        ),
        (
          name: 'Ibrahim',
          relationship: 'mother',
          subject: 'she',
          object: 'her',
          plural: false,
        ),
        (
          name: 'Yusuf',
          relationship: null,
          subject: 'they',
          object: 'them',
          plural: true,
        ),
        (
          name: 'Maryam',
          relationship: 'cousin',
          subject: 'they',
          object: 'them',
          plural: true,
        ),
        (
          name: 'Ali',
          relationship: 'uncle-like',
          subject: 'they',
          object: 'them',
          plural: true,
        ),
      ]) {
    testWidgets(
      'Past summaries copy uses ${sample.relationship} record, never ${sample.name} inference',
      (tester) async {
        final person = WaliLinkedPerson(
          id: 'summary-copy-${sample.name}',
          firstName: sample.name,
          relationship: sample.relationship,
        );
        await _mount(tester, _page(people: [person]));
        final toggle = _key('guardian-history-consent-toggle');
        expect(tester.widget<Switch>(toggle).value, isFalse);
        final info = _key('guardian-history-consent-details-toggle');
        await tester.ensureVisible(info);
        await tester.tap(info);
        await tester.pumpAndSettle();
        expect(find.text('Past Journey summaries'), findsOneWidget);
        expect(
          find.text(
            'Right now ${sample.name} only sees Journeys from the day '
            '${sample.subject} ${sample.plural ? 'were' : 'was'} linked onwards. '
            'Turn this on to also show ${sample.object} the ones before that.',
          ),
          findsOneWidget,
        );
        final subject =
            '${sample.subject[0].toUpperCase()}${sample.subject.substring(1)}';
        expect(
          find.text(
            '$subject ${sample.plural ? 'see' : 'sees'} start date, end date and '
            'status — nothing else. Never names, messages, answers, reasons, '
            'notes or safety information.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('already sees your current'), findsNothing);
        expect(tester.widget<Switch>(toggle).value, isFalse);
        expect(
          _key('guardian-history-consent-explanation-scroll'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'recorded role relationship and continuous link dates stay truthful',
    (tester) async {
      await _mount(tester, _page());
      expect(find.text('Father · Main Guardian'), findsOneWidget);
      expect(
        find.descendant(
          of: _currentPage(_main.id),
          matching: find.text('20 Sep 2026'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _currentPage(_main.id),
          matching: find.text('Linked'),
        ),
        findsOneWidget,
      );
      expect(find.text('Relationship not recorded'), findsNothing);
      _expectNoSteadyInstructions();
      await _nextGuardian(tester);
      expect(find.text('Paternal Uncle · Additional Guardian'), findsOneWidget);
      expect(
        find.descendant(
          of: _currentPage(_additional.id),
          matching: find.text('23 Sep 2026'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _currentPage(_additional.id),
          matching: find.text('Linked'),
        ),
        findsOneWidget,
      );
      _expectNoSteadyInstructions();
    },
  );

  for (final main in [true, false]) {
    final role = main ? 'Main Guardian' : 'Additional Guardian';
    final person = WaliLinkedPerson(
      id: 'unknown-$main',
      firstName: 'Amina',
      isMain: main,
    );
    testWidgets(
      '$role with missing metadata shows role only and Not recorded date',
      (tester) async {
        await _mount(tester, _page(people: [person]));
        expect(find.text(role), findsOneWidget);
        expect(find.text('Relationship not recorded'), findsNothing);
        expect(find.textContaining('Father'), findsNothing);
        expect(find.textContaining('Paternal Uncle'), findsNothing);
        expect(find.text('Not recorded'), findsOneWidget);
        expect(find.text('20 Sep 2026'), findsNothing);
        expect(find.text('23 Sep 2026'), findsNothing);
        expect(find.byKey(const ValueKey('guardian-page-dot-0')), findsNothing);
        _expectNoSteadyInstructions();
      },
    );

    testWidgets(
      'manager $role omits unknown relationship without inventing a date',
      (tester) async {
        await _mount(
          tester,
          GuardianshipManagerView(
            people: [person],
            linksAvailable: true,
            onRetryLinks: () {},
            onOpenGuardian: (_) {},
            onAdd: () {},
            pendingInvitesLoader: () async =>
                const ZyraSourceResult.available(<PendingInvite>[]),
          ),
        );
        final card = _key('guardian-manager-card-${person.id}');
        expect(
          find.descendant(of: card, matching: find.text(role)),
          findsOneWidget,
        );
        expect(find.text('Relationship not recorded'), findsNothing);
        expect(find.textContaining('Father'), findsNothing);
        expect(find.text('Linked date not recorded'), findsOneWidget);
        expect(find.text('20 Sep 2026'), findsNothing);
        expect(find.text('23 Sep 2026'), findsNothing);
      },
    );
  }

  for (final count in [1, 2, 3]) {
    testWidgets(
      '$count Guardian pages stay clear of the resting and touched nav',
      (tester) async {
        await _mount(
          tester,
          _page(people: [_main, _additional, _unrecorded].take(count).toList()),
        );
        expect(find.byType(SingleChildScrollView), findsNothing);
        // LOCK14 expands the painting viewport; locked content geometry stays fixed.
        final page = tester.getRect(_currentPage(_main.id));
        final remove = tester.getRect(_key('guardian-remove'));
        expect(remove.bottom, lessThanOrEqualTo(page.bottom + .01));
        final nav = _key('floating-nav-quiet-true');
        final navTop = tester.getRect(nav).top;
        if (count == 1) {
          expect(
            find.byKey(const ValueKey('guardian-page-dot-0')),
            findsNothing,
          );
          expect(navTop - page.bottom, greaterThanOrEqualTo(20));
        } else {
          final dots = tester.getRect(_key('guardian-page-dot-0'));
          expect(dots.top - page.bottom, closeTo(12, .01));
          expect(navTop - dots.bottom, closeTo(28.12, .01));
          for (var index = 0; index < count; index++) {
            expect(_key('guardian-page-dot-$index'), findsOneWidget);
          }
          final touch = await tester.startGesture(
            tester.getCenter(_key('floating-nav-item-3')),
          );
          await tester.pump(const Duration(milliseconds: 110));
          expect(
            tester.getRect(nav).top - dots.bottom,
            greaterThanOrEqualTo(20 - .01),
          );
          await touch.cancel();
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'loading unavailable and retry copy survive the removal of steady copy',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      final read =
          Completer<ZyraSourceResult<List<GuardianJourneyAccessState>>>();
      var reads = 0;
      Future<ZyraSourceResult<List<GuardianJourneyAccessState>>> access({
        required String guardianId,
        String? attemptId,
        bool? enabled,
        bool? chatEnabled,
      }) {
        reads++;
        expect(guardianId, _main.id);
        expect(attemptId, isNull);
        expect(enabled, isNull);
        expect(chatEnabled, isNull);
        return read.future;
      }

      await _mount(
        tester,
        _page(people: [_main], preview: false, accessLoader: access),
      );
      expect(reads, 1);
      expect(find.text('LOADING JOURNEY ACCESS'), findsOneWidget);
      expect(
        find.text('Checking your current Journey access…'),
        findsOneWidget,
      );
      _expectNoSteadyInstructions();
      read.complete(
        const ZyraSourceResult.unavailable(ZyraSourceFailure.requestFailed),
      );
      await tester.pumpAndSettle();
      expect(find.text('JOURNEY ACCESS UNAVAILABLE'), findsOneWidget);
      expect(
        find.text('Journey access could not be refreshed.'),
        findsOneWidget,
      );
      expect(find.text('Journey unavailable'), findsNWidgets(3));
      expect(find.text('Try again'), findsOneWidget);
      final disabled = tester.widgetList<Semantics>(
        find.descendant(
          of: _key('guardian-journey-access-summary'),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.toggled != null,
          ),
        ),
      );
      expect(disabled, hasLength(6));
      expect(
        disabled.every(
          (toggle) =>
              toggle.properties.onTap == null &&
              toggle.properties.enabled == false &&
              toggle.properties.toggled == false,
        ),
        isTrue,
      );
      _expectNoSteadyInstructions();
    },
  );

  testWidgets(
    'Main View locks and unavailable Chat remain enforced and explained',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        Future<ZyraSourceResult<List<GuardianJourneyAccessState>>> access({
          required String guardianId,
          String? attemptId,
          bool? enabled,
          bool? chatEnabled,
        }) async => const ZyraSourceResult.available([
          GuardianJourneyAccessState(
            attemptId: 'confirmed-attempt',
            matchId: 'confirmed-match',
            counterpartFirstName: 'Sara',
            included: true,
            canChange: false,
            guardianIsMain: true,
            chatAvailable: false,
          ),
        ]);
        await _mount(
          tester,
          _page(people: [_main], preview: false, accessLoader: access),
        );
        expect(
          _key('guardian-journey-view-required-confirmed-attempt'),
          findsOneWidget,
        );
        final chatKey = _key('guardian-journey-chat-toggle-confirmed-attempt');
        final chat = tester.widget<Semantics>(chatKey).properties;
        expect(chat.toggled, isFalse);
        expect(chat.enabled, isFalse);
        expect(chat.onTap, isNull);
        expect(
          tester
              .widget<InkWell>(
                find.descendant(of: chatKey, matching: find.byType(InkWell)),
              )
              .onTap,
          isNull,
        );
        expect(
          find.text('Chat is unavailable for this Journey.'),
          findsOneWidget,
        );
        final summary = tester
            .getSemantics(_key('guardian-journey-access-summary'))
            .getSemanticsData();
        expect(
          summary.label,
          contains('View is required for each active Journey.'),
        );
        _expectNoSteadyInstructions();
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'unavailable links remain a failure with a working retry, not an empty state',
    (tester) async {
      var retries = 0;
      await _mount(
        tester,
        _page(linksAvailable: false, onRetry: () => retries++),
      );
      expect(_key('guardian-links-unavailable'), findsOneWidget);
      expect(find.text('Guardians could not be refreshed'), findsOneWidget);
      expect(_key('guardianship-manager-empty'), findsNothing);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(retries, 1);
    },
  );

  testWidgets(
    '200 percent short-page controls remain reachable without new UI policy',
    (tester) async {
      await _mount(tester, _page(), size: const Size(320, 568), scale: 2);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.widget<Text>(find.text('Hassan')).style!.fontSize, 27);
      await tester.tap(_key('guardian-remove'));
      await tester.pumpAndSettle();
      expect(_key('guardian-remove-confirmation'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: _key('guardian-remove-confirmation'),
          matching: find.text('Cancel'),
        ),
      );
      await tester.pumpAndSettle();
      expect(_key('guardian-remove'), findsOneWidget);
      await _nextGuardian(tester);
      expect(find.text('Yusuf'), findsOneWidget);
      await tester.tap(_key('guardian-make-main'));
      await tester.pumpAndSettle();
      expect(_key('guardian-make-main-confirmation'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: _key('guardian-make-main-confirmation'),
          matching: find.text('Cancel'),
        ),
      );
      await tester.pumpAndSettle();
      expect(_key('guardian-make-main'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'retained Additional preview control denies changes after revocation',
    (tester) async {
      await _mount(tester, _page(people: [_additional]));
      final toggleKey = _key(
        'guardian-journey-access-toggle-dev-active-journey',
      );
      final toggle = tester.widget<Semantics>(toggleKey).properties;
      expect(toggle.enabled, isTrue);
      expect(toggle.onTap, isNotNull);
      final retained = tester
          .widget<InkWell>(
            find.descendant(of: toggleKey, matching: find.byType(InkWell)),
          )
          .onTap!;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      retained();
      await tester.pumpAndSettle();
      expect(find.text('JOURNEY ACCESS UNAVAILABLE'), findsOneWidget);
      expect(
        _key('guardian-journey-access-toggle-dev-active-journey'),
        findsNothing,
      );
      expect(find.text('Journey with Maryam'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
