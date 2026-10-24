// Redundant visual labels are removed. Shared page actions, truth
// metadata and permission semantics remain independently exercised here.
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

const _font = 'PoppinsGuardianSectionLabels';
const _captures = String.fromEnvironment('ZYRA_GUARDIAN_CAPTION_CAPTURE_DIR');
const _captureKey = ValueKey('guardian-caption-capture');
final _main = WaliLinkedPerson(
  id: 'section-hassan',
  firstName: 'Hassan',
  isMain: true,
  relationship: 'father',
  linkedAt: DateTime.utc(2026, 9, 20),
);
final _additional = WaliLinkedPerson(
  id: 'section-yusuf',
  firstName: 'Yusuf',
  relationship: 'uncle',
  linkedAt: DateTime.utc(2026, 9, 23),
);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Guardian section fixtures must remain offline.');
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));

Future<ZyraSourceResult<GuardianHistoryConsentState>> _history({
  required String guardianId,
  required bool guardianIsMain,
  bool? enabled,
}) async => ZyraSourceResult.available(
  GuardianHistoryConsentState(
    enabled: enabled ?? false,
    activeGuardianLinkId: 'section-link-$guardianId',
    guardianId: guardianId,
    guardianIsMain: guardianIsMain,
  ),
);

Widget _page({
  required List<WaliLinkedPerson> people,
  bool preview = true,
  Map<String, List<GuardianActivity>> activity = const {},
  GuardianPageJourneyAccessLoader? accessLoader,
  GuardianMakeMainAction? makeMain,
  GuardianClearMainAction? clearMain,
  GuardianRemoveAction? remove,
  VoidCallback? onChanged,
  int activeJourneyCount = 3,
}) => SeekerGuardianPage(
  people: people,
  activity: activity,
  linksAvailable: true,
  activityAvailable: true,
  onRetry: () {},
  onAdd: () {},
  titleSize: 26,
  historyConsentPreview: preview,
  previewActiveJourneyCount: activeJourneyCount,
  historyConsentLoader: _history,
  journeyAccessLoader: accessLoader,
  pendingInvitesLoader: () async =>
      const ZyraSourceResult.available(<PendingInvite>[]),
  makeMainGuardian: makeMain,
  clearMainGuardian: clearMain,
  removeGuardian: remove,
  onChanged: onChanged,
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
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: _captureKey,
        child: Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
            child: Stack(
              fit: StackFit.expand,
              children: [
                SafeArea(bottom: false, child: child),
                FloatingNavBar(
                  items: const [
                    FloatingNavItem(icon: Icons.search, label: 'Browse'),
                    FloatingNavItem(
                      icon: Icons.route_outlined,
                      label: 'Journey',
                    ),
                    FloatingNavItem(
                      icon: Icons.dashboard_outlined,
                      label: 'My ZYRA',
                    ),
                    FloatingNavItem(
                      icon: Icons.gpp_good_outlined,
                      label: 'Guardian',
                    ),
                    FloatingNavItem(
                      icon: Icons.person_outline,
                      label: 'Profile',
                    ),
                  ],
                  currentIndex: 3,
                  onTap: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectOnlyRequestedLabelsRemoved() {
  expect(find.text('MANAGE'), findsNothing);
  expect(find.text('JOURNEY ACCESS'), findsNothing);
  expect(find.text('Active Journey access'), findsOneWidget);
  expect(_key('guardian-journey-access-icon'), findsNothing);
  expect(find.text('Share past Journey summaries'), findsOneWidget);
  for (final caption in [
    'NO ACTIVE JOURNEYS',
    '1 ACTIVE JOURNEY',
    '2 ACTIVE JOURNEYS',
    '3 ACTIVE JOURNEYS',
  ]) {
    expect(find.text(caption), findsNothing);
  }
}

void _expectHeaderGeometry(
  WidgetTester tester,
  int count, {
  required bool isMain,
}) {
  Rect globalRect(Finder finder) {
    final box = tester.renderObject<RenderBox>(finder);
    return Rect.fromPoints(
      box.localToGlobal(Offset.zero),
      box.localToGlobal(Offset(box.size.width, box.size.height)),
    );
  }

  final summary = _key('guardian-journey-access-summary');
  final heading = _key('guardian-journey-access-heading');
  final headingLabel = find.descendant(
    of: heading,
    matching: find.text('Active Journey access'),
  );
  expect(headingLabel, findsOneWidget);
  expect(globalRect(headingLabel).left, closeTo(globalRect(summary).left, .01));
  expect(globalRect(headingLabel).left, closeTo(globalRect(heading).left, .01));
  expect(
    find.descendant(of: heading, matching: find.byType(Icon)),
    findsNothing,
  );
  final header = _key('guardian-journey-permission-header');
  final gap = _key('guardian-journey-permission-header-gap');
  final divider = _key('guardian-journey-permission-header-divider');
  expect(header, findsOneWidget);
  expect(
    tester.widget<Padding>(header).padding,
    const EdgeInsets.symmetric(vertical: 4),
  );
  final headerRect = globalRect(header);
  final headerSize = tester.getSize(header);
  final scaleX = headerRect.width / headerSize.width;
  final scaleY = headerRect.height / headerSize.height;
  expect(scaleX, greaterThan(0));
  expect(scaleX, lessThanOrEqualTo(1 + .01));
  expect(scaleX, closeTo(scaleY, .01));
  final rects = <String, Rect>{};
  for (final label in ['Journey', 'View', 'Chat']) {
    final text = find.descendant(of: header, matching: find.text(label));
    expect(text, findsOneWidget);
    expect(tester.widget<Text>(text).style!.fontSize, 12.25);
    final rect = globalRect(text);
    rects[label] = rect;
    expect(rect.top - headerRect.top, closeTo(4 * scaleY, .01));
    expect(headerRect.bottom - rect.bottom, closeTo(4 * scaleY, .01));
    expect(rect.left, greaterThanOrEqualTo(globalRect(summary).left));
    expect(rect.right, lessThanOrEqualTo(globalRect(summary).right));
  }
  expect(rects['Journey']!.right, lessThanOrEqualTo(rects['View']!.left + .01));
  expect(rects['View']!.right, lessThanOrEqualTo(rects['Chat']!.left + .01));
  expect(rects['View']!.width, greaterThanOrEqualTo(56 * scaleX));
  expect(rects['View']!.width, closeTo(rects['Chat']!.width, .01));
  for (final label in ['View', 'Chat']) {
    expect(rects[label]!.height, closeTo(rects['Journey']!.height, .01));
    expect(rects[label]!.center.dy, closeTo(rects['Journey']!.center.dy, .01));
  }
  expect(tester.getSize(gap).height, 8);
  expect(globalRect(gap).top, closeTo(headerRect.bottom, .01));
  expect(globalRect(divider).top - headerRect.bottom, closeTo(8 * scaleY, .01));
  for (var index = 0; index < 3; index++) {
    final pending = index >= count;
    final attempt = index == 0
        ? 'dev-active-journey'
        : 'dev-active-journey-${index + 1}';
    final rowLabel = pending
        ? find.descendant(
            of: _key('guardian-journey-pending-row-$index'),
            matching: find.byType(Text),
          )
        : find.text('Journey with ${['Maryam', 'Aaliyah', 'Sara'][index]}');
    expect(rowLabel, findsOneWidget);
    expect(globalRect(rowLabel).left, closeTo(rects['Journey']!.left, .01));
    for (final permission in ['view', 'chat']) {
      final key = pending
          ? 'guardian-journey-pending-$permission-$index'
          : isMain
          ? 'guardian-journey-$permission-required-$attempt'
          : 'guardian-journey-${permission == 'view' ? 'access' : 'chat'}-toggle-$attempt';
      final control = _key(key);
      expect(control, findsOneWidget);
      expect(
        tester.getCenter(control).dx,
        closeTo(rects[permission == 'view' ? 'View' : 'Chat']!.center.dx, .01),
      );
      expect(
        tester.getCenter(control).dy,
        closeTo(tester.getCenter(rowLabel).dy, .01),
      );
      if (!pending && isMain) {
        expect(tester.getSize(control), const Size(26, 26));
      } else {
        expect(tester.getSize(control), const Size.square(44));
        final face = find.descendant(
          of: control,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        );
        expect(face, findsOneWidget);
        expect(tester.getSize(face), const Size.square(26));
      }
    }
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captures.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captures/$name.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

Future<void> _press(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Finder _confirmationChoice(String id, String text) =>
    find.descendant(of: _key(id), matching: find.text(text));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;

  setUpAll(() async {
    if (_captures.isNotEmpty) {
      if (!_captures.startsWith('/')) {
        throw StateError(
          'Capture output must be an existing absolute directory.',
        );
      }
      var path = '';
      for (final component
          in _captures.split('/').where((part) => part.isNotEmpty)) {
        if (component == '.' || component == '..') {
          throw StateError('Capture output cannot contain aliases.');
        }
        path += '/$component';
        if (FileSystemEntity.typeSync(path, followLinks: false) !=
            FileSystemEntityType.directory) {
          throw StateError(
            'Capture output must contain only existing nonlinked directories.',
          );
        }
      }
    }
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

  for (final person in [_main, _additional]) {
    final role = person.isMain ? 'Main' : 'Additional';
    for (var count = 0; count <= 3; count++) {
      testWidgets(
        '$role $count Journeys omits count and starts at the table header',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await _mount(
              tester,
              _page(people: [person], activeJourneyCount: count),
            );
            _expectOnlyRequestedLabelsRemoved();
            final summary = _key('guardian-journey-access-summary');
            final container = tester.widget<Container>(summary);
            final border = (container.decoration! as BoxDecoration).border!;
            final topInset =
                container.padding!.resolve(TextDirection.ltr).top +
                border.dimensions.resolve(TextDirection.ltr).top;
            final top = tester.getRect(summary).top;
            expect(
              tester.getRect(_key('guardian-journey-permission-header')).top -
                  top,
              closeTo(topInset, .01),
            );
            for (final label in ['Journey', 'View', 'Chat']) {
              final header = find.descendant(
                of: summary,
                matching: find.text(label),
              );
              expect(header, findsOneWidget);
              expect(
                tester.getRect(header).top - top,
                closeTo(topInset + 4, .01),
              );
            }
            _expectHeaderGeometry(tester, count, isMain: person.isMain);
            const names = ['Maryam', 'Aaliyah', 'Sara'];
            for (var index = 0; index < 3; index++) {
              expect(
                find.text('Journey with ${names[index]}'),
                index < count ? findsOneWidget : findsNothing,
              );
              expect(
                _key('guardian-journey-pending-row-$index'),
                index < count ? findsNothing : findsOneWidget,
              );
            }
            expect(find.text('Awaiting a Journey'), findsNWidgets(3 - count));
            final data = tester.getSemantics(summary).getSemanticsData();
            expect(
              data.label,
              isNot(
                matches(
                  RegExp(
                    r'(?:no|[0-3]) active Journeys?',
                    caseSensitive: false,
                  ),
                ),
              ),
            );
            for (final name in names.take(count)) {
              expect(data.label, contains(name));
            }
            expect(
              data.label,
              contains(
                person.isMain
                    ? 'View is required for each active Journey.'
                    : 'View and Chat permissions are set separately for each active Journey.',
              ),
            );
            expect(
              find.bySemanticsLabel(
                RegExp(r'(?:no|[0-3]) active Journeys?', caseSensitive: false),
              ),
              findsNothing,
            );
            expect(find.text(person.firstName), findsOneWidget);
            expect(find.text(person.linkedDateLabel!), findsOneWidget);
            expect(_key('guardian-remove'), findsOneWidget);
            expect(
              _key(
                person.isMain ? 'guardian-clear-main' : 'guardian-make-main',
              ),
              findsOneWidget,
            );
            if (person.isMain) {
              await _capture(tester, switch (count) {
                0 => '00-zero',
                1 => '01-one',
                2 => '02-two',
                _ => '03-three',
              });
            }
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
    testWidgets(
      '$role larger permission header remains aligned at 320x568 with 2x text',
      (tester) async {
        await _mount(
          tester,
          _page(people: [person], activeJourneyCount: 3),
          size: const Size(320, 568),
          scale: 2,
        );
        _expectOnlyRequestedLabelsRemoved();
        _expectHeaderGeometry(tester, 3, isMain: person.isMain);
        expect(find.byType(SingleChildScrollView), findsNothing);
        final page = tester.getRect(_key('guardian-page-view'));
        final remove = tester.getRect(_key('guardian-remove'));
        final nav = tester.getRect(_key('floating-nav-quiet-true'));
        expect(remove.bottom, lessThanOrEqualTo(page.bottom + .01));
        expect(page.bottom, lessThanOrEqualTo(nav.top - 20 + .01));
        expect(_key('guardian-remove').hitTestable(), findsOneWidget);
        expect(find.text(person.firstName), findsOneWidget);
        await _capture(
          tester,
          person.isMain ? '04-main-compact200' : '05-additional-compact200',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$role removes only requested captions and keeps recorded identity/date',
      (tester) async {
        await _mount(tester, _page(people: [person]));
        _expectOnlyRequestedLabelsRemoved();
        expect(find.text(person.firstName), findsOneWidget);
        expect(
          find.text(
            '${person.relationshipLabel} · ${person.isMain ? 'Main Guardian' : 'Additional Guardian'}',
          ),
          findsOneWidget,
        );
        expect(find.text('Linked'), findsOneWidget);
        expect(find.text(person.linkedDateLabel!), findsOneWidget);
        expect(_key('guardian-remove'), findsOneWidget);
        expect(
          _key(person.isMain ? 'guardian-clear-main' : 'guardian-make-main'),
          findsOneWidget,
        );
        expect(find.text('CURRENT OBLIGATION'), findsNothing);
        expect(find.text('3 ACTIVE JOURNEYS'), findsNothing);
      },
    );

    testWidgets(
      '$role manage actions still require actual Confirm and respect Cancel',
      (tester) async {
        final called = <String>[];
        var changed = 0;
        Future<bool> roleAction(String id) async {
          called.add('role:$id');
          return true;
        }

        await _mount(
          tester,
          _page(
            people: [person],
            makeMain: roleAction,
            clearMain: roleAction,
            remove: (id) async {
              called.add('remove:$id');
              return null;
            },
            onChanged: () => changed++,
          ),
        );
        final roleKey = person.isMain
            ? 'guardian-clear-main'
            : 'guardian-make-main';
        final confirmation = '$roleKey-confirmation';
        await _press(tester, _key(roleKey));
        expect(called, isEmpty);
        await _press(tester, _confirmationChoice(confirmation, 'Cancel'));
        expect(called, isEmpty);
        expect(changed, 0);
        await _press(tester, _key(roleKey));
        await _press(tester, _confirmationChoice(confirmation, 'Confirm'));
        expect(called, ['role:${person.id}']);
        expect(changed, 1);
        // Confirmation notifies the owner; it must not fabricate a new DTO role.
        expect(find.text(person.linkedDateLabel!), findsOneWidget);
        await _press(tester, _key('guardian-remove'));
        await _press(
          tester,
          _confirmationChoice('guardian-remove-confirmation', 'Cancel'),
        );
        expect(called, ['role:${person.id}']);
        await _press(tester, _key('guardian-remove'));
        await _press(
          tester,
          _confirmationChoice('guardian-remove-confirmation', 'Confirm'),
        );
        expect(called, ['role:${person.id}', 'remove:${person.id}']);
        expect(changed, 2);
        _expectOnlyRequestedLabelsRemoved();
      },
    );

    testWidgets(
      '$role unavailable Chat eligibility and Main required View survive caption cleanup',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          var reads = 0;
          var writes = 0;
          Future<ZyraSourceResult<List<GuardianJourneyAccessState>>> access({
            required String guardianId,
            String? attemptId,
            bool? enabled,
            bool? chatEnabled,
          }) async {
            expect(guardianId, person.id);
            if (attemptId == null) {
              reads++;
            } else {
              writes++;
            }
            return ZyraSourceResult.available([
              GuardianJourneyAccessState(
                attemptId: 'basic-attempt',
                matchId: 'basic-match',
                counterpartFirstName: 'Sara',
                included: true,
                canChange: !person.isMain,
                guardianIsMain: person.isMain,
                chatAvailable: false,
                chatEnabled: false,
              ),
            ]);
          }

          await _mount(
            tester,
            _page(people: [person], preview: false, accessLoader: access),
          );
          _expectOnlyRequestedLabelsRemoved();
          expect(reads, 1);
          expect(writes, 0);
          expect(
            _key('guardian-journey-view-required-basic-attempt'),
            person.isMain ? findsOneWidget : findsNothing,
          );
          final chatKey = _key('guardian-journey-chat-toggle-basic-attempt');
          final chat = tester.widget<Semantics>(chatKey).properties;
          expect(chat.onTap, isNull);
          expect(chat.enabled, isFalse);
          expect(chat.toggled, isFalse);
          expect(
            tester
                .widget<InkWell>(
                  find.descendant(of: chatKey, matching: find.byType(InkWell)),
                )
                .onTap,
            isNull,
          );
          await tester.tap(chatKey);
          await tester.pumpAndSettle();
          expect(writes, 0);
          expect(tester.widget<Semantics>(chatKey).properties.toggled, isFalse);
          expect(
            find.text('Chat is unavailable for this Journey.'),
            findsOneWidget,
          );
          if (person.isMain) {
            final data = tester
                .getSemantics(_key('guardian-journey-access-summary'))
                .getSemanticsData();
            expect(
              data.label,
              contains('View is required for each active Journey.'),
            );
          }
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets(
    'Current Obligation remains for a real recorded waiting-review fixture',
    (tester) async {
      await _mount(
        tester,
        _page(
          people: [_additional],
          activity: {
            _additional.id: [
              GuardianActivity(
                waliId: _additional.id,
                type: 'review_waiting',
                occurredAt: DateTime.utc(2026, 10, 11),
                detail: 'Private fixture detail must not become summary copy',
              ),
            ],
          },
        ),
      );
      _expectOnlyRequestedLabelsRemoved();
      expect(find.text('CURRENT OBLIGATION'), findsOneWidget);
      expect(find.text('Family Review is open'), findsOneWidget);
      expect(
        find.text('Private fixture detail must not become summary copy'),
        findsNothing,
      );
      expect(_key('guardian-remove'), findsOneWidget);
    },
  );

  testWidgets(
    'normal page still fits and pagination/nav clearance does not change',
    (tester) async {
      await _mount(tester, _page(people: [_main, _additional]));
      _expectOnlyRequestedLabelsRemoved();
      expect(find.byType(SingleChildScrollView), findsNothing);
      final page = tester.getRect(_key('guardian-page-view'));
      final remove = tester.getRect(_key('guardian-remove'));
      expect(remove.top, greaterThanOrEqualTo(page.top));
      expect(remove.bottom, lessThanOrEqualTo(page.bottom + .01));
      final dots = tester.getRect(_key('guardian-page-dot-0'));
      final nav = tester.getRect(_key('floating-nav-quiet-true'));
      expect(dots.top - page.bottom, closeTo(12, .01));
      expect(nav.top - dots.bottom, closeTo(28.12, .01));
      await tester.drag(_key('guardian-page-view'), const Offset(-330, 0));
      await tester.pumpAndSettle();
      _expectOnlyRequestedLabelsRemoved();
      expect(find.text('Yusuf'), findsOneWidget);
      final activeDot = tester.widget<AnimatedContainer>(
        _key('guardian-page-dot-1'),
      );
      expect(
        (activeDot.decoration! as BoxDecoration).color,
        ZyraColors.journeyGold,
      );
      expect(find.text('23 Sep 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unrecorded or unsupported DTO metadata is never replaced with fake facts',
    (tester) async {
      const person = WaliLinkedPerson(
        id: 'legacy-link',
        firstName: 'Legacy Guardian',
        isMain: true,
        relationship: 'unsupported-fixture-code',
      );
      await _mount(tester, _page(people: [person]));
      _expectOnlyRequestedLabelsRemoved();
      expect(find.text('Main Guardian'), findsOneWidget);
      expect(find.text('Not recorded'), findsOneWidget);
      expect(find.textContaining('Father'), findsNothing);
      expect(find.textContaining('unsupported-fixture-code'), findsNothing);
      expect(find.text('20 Sep 2026'), findsNothing);
      expect(find.text('23 Sep 2026'), findsNothing);
    },
  );
}
