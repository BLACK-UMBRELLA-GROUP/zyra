import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/dev/zyra_browse_filter.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/main.dart' show ZyraApp;
import 'package:zyra/widgets/zyra_floating_surface.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

// Optional private evidence. A normal test run only checks geometry.
const _captureRoot = String.fromEnvironment('ZYRA_SPACING_CAPTURE_ROOT');
const _frameKey = ValueKey('line77-spacing-boundary');
const _nav = ValueKey('compact-nav-surface');

class _Frame extends StatelessWidget {
  const _Frame(this.child);
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final source = const ZyraApp().build(context) as ListenableBuilder;
    return ListenableBuilder(
      listenable: source.listenable,
      builder: (context, _) {
        final app = source.builder(context, null) as MaterialApp;
        return MaterialApp(
          theme: app.theme,
          scrollBehavior: app.scrollBehavior,
          builder: (context, child) =>
              RepaintBoundary(key: _frameKey, child: child!),
          home: child,
        );
      },
    );
  }
}

DateTime _clock() => DateTime.utc(2026, 11, 11, 12);

Future<void> mount(
  WidgetTester t, {
  required bool guardian,
  required bool basic,
  required int tab,
  required bool active,
  int? count,
  int guardianPage = 0,
  bool linked = true,
  bool noMatches = false,
  List<String> pages = const [],
}) async {
  final ready = Completer<void>();
  final model = ViewRequestDraftModel(
    capacity: !guardian && basic ? 1 : 3,
    clock: _clock,
  );
  if (active || count != null) expect(model.seedJourneys(count ?? 1), isTrue);
  if (guardian && basic) {
    expect(
      model.setSampleGuardianMembership(
        'draft-guardian-hassan',
        DraftGuardianMembership.basic,
      ),
      isTrue,
    );
  }
  ZyraPreviewNavigationCheckpoint? actual;
  await t.pumpWidget(
    _Frame(
      ZyraOneJourneyConceptShell(
        fixture: ZyraShellTestFixture().fixture,
        key: UniqueKey(),
        canAct: () => true,
        onExit: () => fail('Must stay inside actual Founder preview.'),
        initialGuardianRole: guardian,
        initialSeekerBasic: !guardian && basic,
        initialGuardianBasic: guardian && basic,
        initialCheckpoint: ZyraPreviewNavigationCheckpoint(
          guardian: guardian,
          model: model.snapshot(),
          tab: tab,
          pages: pages,
          guardianPage: guardianPage,
          removedGuardians: linked ? const [] : const ['draft-guardian-hassan'],
          browseFilter: noMatches
              ? const ZyraBrowseFilter(minAge: 69, maxAge: 70)
              : const ZyraBrowseFilter(),
          personId: 'draft-sara',
          seekerMembership: !guardian && basic ? 'Seeker Basic' : 'Seeker One',
          guardianMembership: guardian && basic
              ? 'Guardian Basic'
              : 'Guardian One',
        ),
        previewClock: _clock,
        onCheckpoint: (value) => actual = value,
        onPresentationReady: () {
          if (!ready.isCompleted) ready.complete();
        },
      ),
    ),
  );
  for (var frame = 0; frame < 150 && !ready.isCompleted; frame++) {
    await t.pump(const Duration(milliseconds: 20));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  expect(
    ready.isCompleted,
    isTrue,
    reason: 'Bundled local photos must prepare',
  );
  await t.pump(const Duration(milliseconds: 1800));
  await t.pump(const Duration(milliseconds: 400));
  expect(actual?.guardian, guardian);
  expect(actual?.tab, tab);
  expect(actual?.pages, pages);
  expect(
    guardian ? actual?.guardianMembership : actual?.seekerMembership,
    '${guardian ? 'Guardian' : 'Seeker'} ${basic ? 'Basic' : 'One'}',
  );
  expect(find.byType(ZyraShellNavigation), findsOneWidget);
  expect(find.byKey(_nav), findsOneWidget);
}

void viewport(WidgetTester t, {required bool compact, required bool large}) {
  final width = compact ? 375.0 : 430.0;
  final height = compact ? 667.0 : 932.0;
  const dpr = 3.0;
  final insets = FakeViewPadding(
    top: (compact ? 20 : 59) * dpr,
    bottom: (compact ? 0 : 34) * dpr,
  );
  t.view.devicePixelRatio = dpr;
  t.view.physicalSize = Size(width * dpr, height * dpr);
  t.view.padding = insets;
  t.view.viewPadding = insets;
  t.platformDispatcher.textScaleFactorTestValue = large ? 2 : 1;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
}

Rect? bounds(Element e) {
  final box = e.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

String rect(Rect? r) => r == null
    ? '-'
    : [
        r.left,
        r.top,
        r.right,
        r.bottom,
      ].map((v) => v.toStringAsFixed(1)).join(',');
List<ScrollableState> vertical(WidgetTester t) =>
    t
        .stateList<ScrollableState>(find.byType(Scrollable))
        .where(
          (s) =>
              s.position.axis == Axis.vertical &&
              s.position.hasContentDimensions,
        )
        .toList()
      ..sort(
        (a, b) => b.position.viewportDimension.compareTo(
          a.position.viewportDimension,
        ),
      );

String info(Widget widget) {
  if (widget is! Text) return '';
  return widget.data ?? widget.textSpan?.toPlainText() ?? '';
}

List<String> inspectTree(WidgetTester t) {
  final rows = <String>[];
  final ancestors = <Element>[];
  void visit(Element e) {
    final w = e.widget;
    if (w is ZyraShellNavigation || w is Offstage && w.offstage) return;
    final type = w.runtimeType.toString();
    final parent = ancestors.lastOrNull?.widget.runtimeType.toString();
    final r = bounds(e);
    final name = info(w).replaceAll('\n', ' / ');
    final key = (w.key?.toString() ?? '');
    final keyLabel = key.length > 160 ? '${key.substring(0, 80)}…' : key;
    final isComponent =
        (type.startsWith('Zyra') || type.startsWith('_')) &&
        RegExp(
          r'Dot|Card|Row|Pill|Tab|Empty|Button|Heading|Tile|Badge|Section',
        ).hasMatch(type);
    if (r != null &&
        (w.key != null ||
            w is Text ||
            isComponent ||
            (w is Column && r.width > 200) ||
            (parent == 'Column' && w is! Padding && w is! SizedBox))) {
      rows.add(
        '${' ' * ancestors.length.clamp(0, 45)}$type $keyLabel $name [${rect(r)}]',
      );
    }
    ancestors.add(e);
    e.visitChildElements(visit);
    ancestors.removeLast();
  }

  visit(t.element(find.byType(ZyraOneJourneyConceptShell)));
  return rows;
}

Finder _key(String id) => find.byKey(ValueKey(id));

Finder? _outerViewport(String screen) => switch (screen) {
  'Profiles' => _key('concept_browse_design_scroll'),
  'Profiles — no matches' => _key('concept_profiles_empty_viewport'),
  'Journey — empty' => _key('journey_tab_empty_scroll'),
  'Journey options' => _key('journey_options_scroll_draft-sara'),
  'My ZYRA' => find.byKey(const PageStorageKey('my-zyra-focus-scroll')),
  'Network' || 'Network — unlinked' => find.byKey(
    const PageStorageKey('guardian_tabs_network'),
  ),
  'Seekers' || 'Seekers — unlinked' => find.byKey(
    const PageStorageKey('guardian_tabs_seekers'),
  ),
  'Profile' => _key('concept-current-profile-scroll'),
  'Quick · Seeker Journey requests' ||
  'Quick · Seeker Introductions' ||
  'Quick · Seeker Ended Journeys' => find.byKey(
    const PageStorageKey('concept_connections_page_0'),
  ),
  'Quick · Seeker Notifications' ||
  'Quick · Guardian Notifications' => _key('draft_scroll'),
  'Quick · Guardian Journey requests' => find.byKey(
    const PageStorageKey('guardian_tabs_requests'),
  ),
  'Quick · Guardian Connect with Guardian' => _key(
    'guardian_quick_empty_connect',
  ),
  'Quick · Guardian Introductions' => _key(
    'guardian_quick_empty_introductions',
  ),
  _ => null,
};

ScrollPosition? _outerPosition(WidgetTester t, String screen) {
  final viewport = _outerViewport(screen);
  if (screen == 'Profiles — full places') {
    final action = _key('draft_focus_journey');
    if (action.evaluate().isEmpty) return null;
    final scrollable = find
        .ancestor(of: action, matching: find.byType(Scrollable))
        .first;
    return t.state<ScrollableState>(scrollable).position;
  }
  if (viewport == null || viewport.evaluate().isEmpty) return null;
  final scrollable = find.descendant(
    of: viewport,
    matching: find.byType(Scrollable),
  );
  return t
      .stateList<ScrollableState>(scrollable)
      .where((state) => state.position.axis == Axis.vertical)
      .firstOrNull
      ?.position;
}

Finder? _lastSurface(String screen, bool basic) => switch (screen) {
  'Profiles' => _key('concept_request_row_surface'),
  'Journey' => _key(
    basic ? 'journey_tab_upsell' : 'concept_request_row_surface',
  ),
  'Journey options' => _key('journey_options_actions_card_draft-sara'),
  'My ZYRA' =>
    _key('focus-notifications').evaluate().isNotEmpty
        ? _key('focus-notifications')
        : _key('guardian_notifications'),
  'Guardian' || 'Guardian — Journey access' => _key('guardian-card-access'),
  'Guardian — invited' || 'Guardian — Add card' => _key('guardian-card-center'),
  'Network' => _key('guardian_connect_confirm'),
  'Journeys' || 'Journeys — empty' => _key('guardian_ended'),
  'Profile' =>
    find
        .ancestor(
          of: _key('concept_sign_out'),
          matching: find.byType(ZyraFloatingSurface),
        )
        .first,
  // Centered empty and full-places surfaces have a separate open design decision.
  _ => null,
};

Finder? _quickLastSurface(String screen) => switch (screen) {
  'Quick · Seeker Journey requests' ||
  'Quick · Seeker Introductions' ||
  'Quick · Seeker Ended Journeys' =>
    find
        .descendant(
          of: _key('request_activity_empty'),
          matching: find.byType(Text),
        )
        .last,
  'Quick · Seeker Notifications' ||
  'Quick · Guardian Notifications' => _key('concept_notifications_end_card'),
  'Quick · Guardian Journey requests' => find.text('No received requests yet.'),
  'Quick · Guardian Connect with Guardian' ||
  'Quick · Guardian Introductions' => _key('guardian_empty_network'),
  _ => null,
};

Finder? _fixedCard(String screen) => switch (screen) {
  'Profiles' => _key('concept_browse_portrait_card'),
  'Journey' => _key('journey_tab_card'),
  'Guardian' ||
  'Guardian — Journey access' => _key('guardian-card-draft-guardian-hassan'),
  'Guardian — invited' => _key('guardian-card-preview-invited-omar'),
  'Guardian — Add card' => _key('guardian-card-add'),
  'Network' => _key('guardian-network-card'),
  'Journeys' => _key('guardian_journey_card'),
  _ => null,
};

Future<void> _capture(WidgetTester t, String sample, String screen) async {
  final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(_frameKey));
  await t.runAsync(() async {
    final frame = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await frame.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_captureRoot/renders/$sample/$screen.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      frame.dispose();
    }
  });
}

void main() {
  setUpAll(
    () => baselineSetUp(
      evidenceRoot: null,
      useSystemSymbolFont: Platform.isMacOS,
    ),
  );
  tearDownAll(baselineTearDown);
  for (final guardian in [false, true]) {
    for (final basic in [false, true]) {
      for (final compact in [false, true]) {
        for (final large in [false, true]) {
          final role =
              '${guardian ? 'Guardian' : 'Seeker'} ${basic ? 'Basic' : 'One'}';
          final key =
              '${role.replaceAll(' ', '-')}-${compact ? '375' : '430'}-${large ? 'large' : 'default'}';
          testWidgets('LOCK24 $key', (t) async {
            viewport(t, compact: compact, large: large);
            final names = guardian
                ? ['Network', 'Journeys', 'My ZYRA', 'Seekers', 'Profile']
                : ['Profiles', 'Journey', 'My ZYRA', 'Guardian', 'Profile'];
            final report = <String, Object?>{};
            if (_captureRoot.isNotEmpty) {
              addTearDown(() {
                final file = File('$_captureRoot/after-$key.json');
                file.parent.createSync(recursive: true);
                file.writeAsStringSync(
                  const JsonEncoder.withIndent('  ').convert(report),
                );
              });
            }
            Future<void> measure(String screen) async {
              final nav = t.getRect(find.byKey(_nav));
              expect(
                nav.height,
                58,
                reason: '$screen has the full V4 tab bar.',
              );
              expect(nav.width, compact ? 335 : 390);
              expect(nav.top, compact ? 595 : 840);
              final media = MediaQuery.of(
                t.element(find.byType(ZyraOneJourneyConceptShell)),
              );
              expect(media.padding.bottom, compact ? 0 : 34);
              expect(media.viewPadding.bottom, compact ? 0 : 34);
              expect(media.textScaler.scale(20), large ? 40 : 20);
              expect(
                media.size,
                compact ? const Size(375, 667) : const Size(430, 932),
              );
              final capture = _captureRoot.isNotEmpty;
              final start = capture ? inspectTree(t) : null;
              final max = capture
                  ? [for (final s in vertical(t)) s.position.maxScrollExtent]
                  : null;
              final outer = _outerPosition(t, screen);
              final outerMax = outer?.maxScrollExtent;
              if (outer != null && outerMax != null) {
                outer.jumpTo(outerMax);
                await t.pump(const Duration(milliseconds: 500));
                await t.pump(const Duration(milliseconds: 1200));
                expect(
                  outer.pixels,
                  closeTo(outer.maxScrollExtent, .01),
                  reason: '$screen is at the actual outer scroll end.',
                );
              }
              final renderException = t.takeException();
              final endNav = t.getRect(find.byKey(_nav));
              final endSurface =
                  _lastSurface(screen, basic) ??
                  ((outerMax ?? 0) > 0
                      ? switch (screen) {
                          'Journey — empty' => _key(
                            basic ? 'journey_tab_upsell' : 'journey_tab_browse',
                          ),
                          'Profiles — no matches' => _key(
                            'concept_edit_filters',
                          ),
                          'Profiles — full places' => _key(
                            'draft_focus_journey',
                          ),
                          'Network — unlinked' => _key('guardian_invite'),
                          'Seekers' || 'Seekers — unlinked' => find.text(
                            'You can support up to 10 Seekers.',
                          ),
                          _ => _quickLastSurface(screen),
                        }
                      : null);
              final quickLast = _quickLastSurface(screen);
              if (capture) {
                report[screen] = {
                  'nav': rect(nav),
                  'endNav': rect(endNav),
                  'max': max,
                  'outerMax': outerMax,
                  if (quickLast != null)
                    'quickLast': rect(t.getRect(quickLast)),
                  'start': start,
                  'end': inspectTree(t),
                  'exception': renderException?.toString(),
                };
              }
              expect(renderException, isNull, reason: screen);
              if (quickLast != null) {
                expect(quickLast, findsOneWidget, reason: screen);
                expect(
                  endNav.top - t.getRect(quickLast).bottom,
                  greaterThanOrEqualTo(15),
                  reason: '$screen content clears the full-size bar.',
                );
              }
              if (endSurface != null) {
                expect(endSurface, findsOneWidget, reason: screen);
                expect(
                  endNav.top - t.getRect(endSurface).bottom,
                  closeTo(16, 1),
                  reason: '$screen ends 16 pt above the resting tab bar.',
                );
              }
              if (capture) {
                if (!basic &&
                    (screen == names[0] ||
                        screen == 'Journey' ||
                        screen == 'Guardian' ||
                        (screen == 'Guardian — Journey access' &&
                            compact &&
                            !large) ||
                        screen == 'Network' ||
                        screen == 'My ZYRA' ||
                        screen == 'Profile' ||
                        screen.startsWith('Quick · '))) {
                  await _capture(t, key, screen);
                }
              }
              final card = _fixedCard(screen);
              if (card == null) return;
              expect(card, findsOneWidget, reason: screen);
              final frame = t.getRect(card);
              final contents = t
                  .stateList<ScrollableState>(
                    find.descendant(
                      of: card,
                      matching: find.byType(Scrollable),
                    ),
                  )
                  .map((s) => s.position)
                  .where((s) => s.axis == Axis.vertical)
                  .toList();
              final overflow = contents
                  .where((s) => s.maxScrollExtent > .01)
                  .firstOrNull;
              if (large && overflow != null) {
                final initial = overflow.pixels;
                final finger = await t.startGesture(frame.center);
                await finger.moveBy(const Offset(0, -28));
                await t.pump();
                await finger.moveBy(const Offset(0, -47));
                await t.pump(const Duration(milliseconds: 80));
                expect(
                  overflow.pixels,
                  greaterThan(initial),
                  reason:
                      '$screen lets larger overflowing content move upward.',
                );
                expect(t.getRect(card), frame);
                await finger.up();
                await t.pump(const Duration(milliseconds: 400));
                overflow.jumpTo(overflow.maxScrollExtent);
                await t.pump();
                final atEnd = await t.startGesture(frame.center);
                await atEnd.moveBy(const Offset(0, -28));
                await t.pump();
                await atEnd.moveBy(const Offset(0, -37));
                await t.pump(const Duration(milliseconds: 80));
                expect(
                  overflow.pixels,
                  closeTo(overflow.maxScrollExtent, .01),
                  reason:
                      '$screen clamps the content at the end during the drag.',
                );
                expect(t.getRect(card), frame);
                await atEnd.up();
                await t.pump(const Duration(milliseconds: 400));
              } else {
                for (final offset in [-65.0, 65.0]) {
                  final offsets = contents.map((s) => s.pixels).toList();
                  final finger = await t.startGesture(frame.center);
                  await finger.moveBy(Offset(0, offset.sign * 28));
                  await t.pump();
                  await finger.moveBy(Offset(0, offset.sign * 37));
                  await t.pump(const Duration(milliseconds: 80));
                  expect(
                    t.getRect(card),
                    frame,
                    reason: '$screen stays fixed even during a vertical drag.',
                  );
                  expect(
                    contents.map((s) => s.pixels),
                    offsets,
                    reason: '$screen does not drag its content at rest.',
                  );
                  await finger.up();
                  await t.pump(const Duration(milliseconds: 400));
                  expect(
                    t.getRect(card),
                    frame,
                    reason: '$screen does not bounce.',
                  );
                  expect(contents.map((s) => s.pixels), offsets);
                }
              }
              final gestureException = t.takeException();
              if (capture) {
                (report[screen] as Map<String, Object?>)['gestureException'] =
                    gestureException?.toString();
              }
              expect(gestureException, isNull, reason: '$screen during drags');
            }

            for (var tab = 0; tab < names.length; tab++) {
              final screen = names[tab];
              await mount(
                t,
                guardian: guardian,
                basic: basic,
                tab: tab,
                active: guardian || tab == 1,
              );
              await measure(screen);
            }
            if (!guardian) {
              await mount(
                t,
                guardian: guardian,
                basic: basic,
                tab: 1,
                active: false,
              );
              await measure('Journey — empty');
              await mount(
                t,
                guardian: guardian,
                basic: basic,
                tab: 0,
                active: true,
                count: basic ? 1 : 3,
              );
              await measure('Profiles — full places');
              await mount(
                t,
                guardian: guardian,
                basic: basic,
                tab: 1,
                active: true,
              );
              final options = find.byKey(
                const ValueKey('draft_journey_options_draft-sara'),
              );
              expect(options, findsOneWidget);
              await t.tap(options);
              await t.pump(const Duration(milliseconds: 1800));
              await t.pump(const Duration(milliseconds: 400));
              expect(
                find.byKey(const ValueKey('journey_options_card_draft-sara')),
                findsOneWidget,
              );
              await measure('Journey options');
              await mount(
                t,
                guardian: guardian,
                basic: basic,
                tab: 0,
                active: false,
                noMatches: true,
              );
              expect(
                find.byKey(const ValueKey('concept_edit_filters')),
                findsOneWidget,
              );
              await measure('Profiles — no matches');
              await mount(
                t,
                guardian: guardian,
                basic: basic,
                tab: 3,
                active: true,
              );
              final cardWidget = t.widget<ZyraOneJourneyGuardianCards>(
                find.byType(ZyraOneJourneyGuardianCards),
              );
              final access = find.text('Journey access');
              expect(access, findsOneWidget);
              await t.tap(access);
              await t.pump(const Duration(milliseconds: 600));
              expect(find.text('Details'), findsOneWidget);
              await measure('Guardian — Journey access');
              if (!basic) {
                await mount(
                  t,
                  guardian: guardian,
                  basic: basic,
                  tab: 3,
                  active: false,
                  guardianPage: cardWidget.people.length,
                );
                expect(find.text('Send invitation again'), findsOneWidget);
                await measure('Guardian — invited');
              }
              await mount(
                t,
                guardian: guardian,
                basic: basic,
                tab: 3,
                active: false,
                guardianPage: basic ? 1 : cardWidget.people.length + 1,
              );
              expect(
                find.text(basic ? 'View Seeker One' : 'Add a Guardian'),
                findsWidgets,
              );
              await measure('Guardian — Add card');
            } else {
              await mount(
                t,
                guardian: guardian,
                basic: basic,
                tab: 1,
                active: false,
              );
              await measure('Journeys — empty');
              await mount(
                t,
                guardian: guardian,
                basic: basic,
                tab: 0,
                active: false,
                linked: false,
              );
              expect(find.text('Invite your Seeker'), findsOneWidget);
              await measure('Network — unlinked');
              await mount(
                t,
                guardian: guardian,
                basic: basic,
                tab: 3,
                active: false,
                linked: false,
              );
              expect(
                find.byKey(const ValueKey('guardian_seeker_0')),
                findsNothing,
              );
              await measure('Seekers — unlinked');
            }
            final quickRoutes = guardian
                ? const [
                    ('guardian_requests', 'Guardian Journey requests'),
                    ('guardian_connect', 'Guardian Connect with Guardian'),
                    ('guardian_introductions', 'Guardian Introductions'),
                    ('guardian_notifications', 'Guardian Notifications'),
                  ]
                : const [
                    ('concept-my-requests', 'Seeker Journey requests'),
                    ('concept-my-introductions', 'Seeker Introductions'),
                    ('concept-my-ended', 'Seeker Ended Journeys'),
                    ('focus-notifications', 'Seeker Notifications'),
                  ];
            for (final (keyId, label) in quickRoutes) {
              await mount(
                t,
                guardian: guardian,
                basic: basic,
                tab: 2,
                active: false,
              );
              final tile = _key(keyId);
              await Scrollable.ensureVisible(t.element(tile), alignment: .5);
              await t.pump(const Duration(milliseconds: 500));
              expect(tile.hitTestable(), findsOneWidget);
              await t.tap(tile);
              await t.pump(const Duration(milliseconds: 500));
              final name = 'Quick · $label';
              if (guardian &&
                  basic &&
                  (keyId == 'guardian_connect' ||
                      keyId == 'guardian_introductions')) {
                expect(find.byKey(_nav), findsNothing);
                expect(find.text('Membership'), findsWidgets);
                final gateException = t.takeException();
                if (_captureRoot.isNotEmpty) {
                  report[name] = {
                    'absent': 'Guardian Basic opens Membership',
                    'exception': gateException?.toString(),
                  };
                }
                expect(gateException, isNull, reason: name);
                continue;
              }
              final nav = find.byType(ZyraShellNavigation);
              expect(nav, findsOneWidget, reason: name);
              expect(t.widget<ZyraShellNavigation>(nav).currentIndex, 2);
              await measure(name);
            }
          }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
        }
      }
    }
  }
}
