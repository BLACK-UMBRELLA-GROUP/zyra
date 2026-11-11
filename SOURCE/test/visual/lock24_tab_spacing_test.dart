import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_browse_filter.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/main.dart' show ZyraApp;
import 'package:zyra/widgets/zyra_floating_surface.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';
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
  bool populated = false,
  bool noMatches = false,
  List<String> pages = const [],
}) async {
  final ready = Completer<void>();
  final model = ViewRequestDraftModel(
    capacity: !guardian && basic ? 1 : 3,
    clock: _clock,
  );
  if (active || count != null) expect(model.seedJourneys(count ?? 1), isTrue);
  if (populated) {
    expect(model.seedReceived('draft-amira'), isTrue);
    expect(model.seedReceived('draft-aisha'), isTrue);
    if (!guardian) {
      expect(model.end('draft-sara'), isTrue);
      model.seedHistory();
      for (final id in ['draft-maryam', 'draft-hana']) {
        expect(
          model.seedPastRequest(
            profileId: id,
            outcome: DraftPastRequestOutcome.cancelled,
            requestedAt: _clock().subtract(const Duration(days: 3)),
            movedAt: _clock().subtract(const Duration(days: 1)),
          ),
          isTrue,
        );
      }
    }
  }
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
          guardianTabs: guardian && populated
              ? const ZyraGuardianTabsSnapshot(
                  review: ZyraGuardianReview.open,
                  connection: ZyraGuardianConnection.pending,
                  sent: {'aisha', 'noor'},
                  introduced: {'adam:aisha', 'adam:noor'},
                )
              : const ZyraGuardianTabsSnapshot.quiet(),
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
  'My ZYRA' || 'My ZYRA — activity' => find.byKey(
    const PageStorageKey('my-zyra-focus-scroll'),
  ),
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
  'Quick · Guardian Journey requests' ||
  'Guardian Journey requests — populated' => find.byKey(
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
  'Journey' || 'Journey — free place' => _key(
    basic ? 'journey_tab_upsell' : 'concept_request_row_surface',
  ),
  'Journey options' => _key('journey_options_actions_card_draft-sara'),
  'My ZYRA' || 'My ZYRA — activity' =>
    _key('focus-notifications').evaluate().isNotEmpty
        ? _key('focus-notifications')
        : _key('guardian_notifications'),
  'Guardian' ||
  'Guardian — populated' ||
  'Guardian — invited' => _fixedCard(screen),
  'Guardian — Add card' => _key('guardian-card-center'),
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
  'Guardian Journey requests — populated' => find.text(
    'You see these as their Main Guardian. Each Seeker decides on their own requests.',
  ),
  'Quick · Guardian Connect with Guardian' ||
  'Quick · Guardian Introductions' => _key('guardian_empty_network'),
  _ => null,
};

Finder? _fixedCard(String screen) => switch (screen) {
  'Profiles' => _key('concept_browse_portrait_card'),
  'Journey' || 'Journey — free place' => _key('journey_tab_card'),
  'Guardian' ||
  'Guardian — populated' => _key('guardian-card-draft-guardian-hassan'),
  'Guardian — invited' => _key('guardian-card-preview-invited-omar'),
  'Guardian — Add card' => _key('guardian-card-add'),
  'Network' => _key('guardian-network-card'),
  'Journeys' => _key('guardian_journey_card'),
  _ => null,
};

Map<String, double> _verifySpacing(
  WidgetTester t,
  String screen, {
  required bool guardian,
  required bool basic,
}) {
  final results = <String, double>{};
  Rect box(Finder finder) {
    expect(finder, findsOneWidget, reason: screen);
    return t.getRect(finder);
  }

  void check(String name, double actual, double expected) {
    results[name] = actual;
    expect(actual, closeTo(expected, .02), reason: '$screen · $name');
  }

  void margins(Finder surface) {
    final rect = box(surface);
    final width = MediaQuery.sizeOf(
      t.element(find.byType(ZyraOneJourneyConceptShell)),
    ).width;
    check('left page margin', rect.left, 20);
    check('right page margin', width - rect.right, 20);
  }

  void gap(String name, Finder upper, Finder lower, double expected) {
    check(name, box(lower).top - box(upper).bottom, expected);
  }

  void titleToDots(
    Finder title,
    Finder dotTarget,
    Finder dot, {
    Finder? titleBlock,
    Finder? card,
  }) {
    gap('title block to dot slot', titleBlock ?? title, dotTarget, 12);
    results['title text to dot slot'] = box(dotTarget).top - box(title).bottom;
    results['title text to painted dot'] = box(dot).top - box(title).bottom;
    if (card != null) gap('painted dot to card', dot, card, 12);
  }

  Finder surfaceFor(Finder child) => find
      .ancestor(of: child, matching: find.byType(ZyraFloatingSurface))
      .first;

  void cardGaps(List<Finder> cards) {
    for (var i = 1; i < cards.length; i++) {
      gap('card gap $i', cards[i - 1], cards[i], 12);
    }
  }

  switch (screen) {
    case 'Profiles':
      final card = _key('concept_browse_portrait_card');
      margins(card);
      titleToDots(
        _key('concept_browse_title'),
        _key('concept_browse_dot_target_0'),
        find
            .descendant(
              of: _key('concept_browse_dot_target_0'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
        card: card,
      );
      gap('card to pill', card, _key('concept_request_row_surface'), 12);
    case 'Journey':
    case 'Journey — free place':
      final card = _key('journey_tab_card');
      margins(card);
      titleToDots(
        find.text('Journey'),
        _key('journey_tab_dot_target_0'),
        _key('journey_tab_dot_0'),
        card: card,
      );
      gap('card to pill', card, _key('concept_request_row_surface'), 12);
    case 'Journey options':
      final cards = [
        for (final group in ['main', 'guardians', 'actions'])
          _key('journey_options_${group}_card_draft-sara'),
      ];
      margins(cards.first);
      gap(
        'title to identity',
        find.text('Journey'),
        _key('journey_options_photo_draft-sara'),
        22,
      );
      cardGaps(cards);
    case 'Journey — empty':
      if (basic) {
        gap(
          'empty state to plans card',
          find.byType(ZyraEmptyState),
          _key('journey_tab_upsell'),
          12,
        );
      }
    case 'Network':
      final card = _key('guardian-network-card');
      margins(card);
      gap('card to pill', card, _key('guardian_connect_confirm'), 12);
      gap(
        'card to Introduce pill',
        card,
        _key('guardian_introduce_confirm'),
        12,
      );
    case 'Journeys':
      final card = _key('guardian_journey_card');
      margins(card);
      titleToDots(
        find.text('Journeys'),
        _key('guardian_journey_dot_target_0'),
        _key('guardian_journey_dot_0'),
        titleBlock: _key('guardian_journeys_title_block'),
        card: card,
      );
      gap('card to Ended Journeys card', card, _key('guardian_ended'), 12);
    case 'Seekers':
      final first = _key('guardian_seeker_0');
      final last = _key('guardian_seeker_1');
      margins(first);
      cardGaps([first, last]);
      gap(
        'roster card to footer',
        last,
        find.text('You can support up to 10 Seekers.'),
        10,
      );
    case 'Profile':
      final cards = [
        for (final row in [
          guardian ? 'your_seekers' : 'manage_photos',
          'membership',
          guardian ? 'safety_advice' : 'guardian_info',
          'sign_out',
        ])
          surfaceFor(_key('concept_$row')),
      ];
      margins(cards.first);
      cardGaps(cards);
    case 'My ZYRA':
    case 'My ZYRA — activity':
      final tiles = [
        for (final key
            in guardian
                ? const [
                    'guardian_requests',
                    'guardian_connect',
                    'guardian_introductions',
                    'guardian_notifications',
                  ]
                : const [
                    'concept-my-requests',
                    'concept-my-introductions',
                    'concept-my-ended',
                    'focus-notifications',
                  ])
          _key(key),
      ];
      final width = MediaQuery.sizeOf(
        t.element(find.byType(ZyraOneJourneyConceptShell)),
      ).width;
      check('left page margin', box(tiles.first).left, 20);
      check('right page margin', width - box(tiles.last).right, 20);
      for (var i = 1; i < tiles.length; i++) {
        check('card gap $i', box(tiles[i]).left - box(tiles[i - 1]).right, 12);
      }
      if (screen.endsWith('activity') && (!guardian || !basic)) {
        titleToDots(
          find.text('My ZYRA'),
          _key('focus-dot-target-0'),
          _key('focus-dot-0'),
          titleBlock: guardian
              ? find.text(
                  'Assalamu alaikum, Hassan. You support Adam and Yusuf.',
                )
              : null,
        );
      } else {
        expect(_key('focus-dot-target-0'), findsNothing);
      }
    case 'Guardian Journey requests — populated':
      final requestLabels = find.text('Journey request to Adam');
      expect(requestLabels, findsNWidgets(2));
      final cards = [
        for (var i = 0; i < 2; i++) surfaceFor(requestLabels.at(i)),
      ];
      margins(cards.first);
      cardGaps(cards);
    case 'Guardian':
    case 'Guardian — populated':
    case 'Guardian — invited':
    case 'Guardian — Add card':
      final card = _fixedCard(screen)!;
      margins(card);
      titleToDots(
        _key('guardian-manager-title'),
        _key('guardian-card-dot-target-0'),
        _key('guardian-card-dot-0'),
        titleBlock: _key('guardian-manager-title-block'),
        card: card,
      );
      if (screen == 'Guardian — Add card') {
        gap('card to pill', card, _key('guardian-card-center'), 12);
      } else if (screen == 'Guardian' || screen == 'Guardian — populated') {
        gap(
          'Journey access label to row',
          _key('guardian-card-journey-label'),
          screen == 'Guardian'
              ? _key('guardian-card-free-place-0')
              : _key('guardian-card-tile-draft-sara'),
          8,
        );
      }
  }
  return results;
}

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
              final ruleB = _verifySpacing(
                t,
                screen,
                guardian: guardian,
                basic: basic,
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
                  'ruleB': ruleB,
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
                        (screen == 'Guardian — populated' &&
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

            Future<void> measurePopulatedLists() async {
              Future<void> open(String tileId) async {
                await mount(
                  t,
                  guardian: guardian,
                  basic: basic,
                  tab: 2,
                  active: true,
                  populated: true,
                );
                final tile = _key(tileId);
                await Scrollable.ensureVisible(t.element(tile), alignment: .5);
                await t.pump(const Duration(milliseconds: 500));
                expect(tile.hitTestable(), findsOneWidget);
                await t.tap(tile);
                await t.pump(const Duration(milliseconds: 650));
              }

              Future<void> inspectList(
                String name,
                Finder firstCard,
                Finder lastCard,
              ) async {
                expect(firstCard, findsOneWidget, reason: name);
                final viewport = find.ancestor(
                  of: firstCard,
                  matching: find.byType(Scrollable),
                );
                final position = t
                    .stateList<ScrollableState>(viewport)
                    .singleWhere((s) => s.position.axis == Axis.vertical)
                    .position;
                final first = t.getRect(firstCard);
                final firstBottom = first.bottom + position.pixels;
                // At Larger Text the last sliver child can be outside the
                // cache at the top. Measure it in the same content coordinates
                // at the genuine end, after the lazy extent has settled.
                for (var frame = 0; frame < 3; frame++) {
                  if ((position.maxScrollExtent - position.pixels).abs() <
                      .02) {
                    break;
                  }
                  position.jumpTo(position.maxScrollExtent);
                  await t.pump(const Duration(milliseconds: 650));
                }
                expect(position.pixels, closeTo(position.maxScrollExtent, .02));
                expect(lastCard, findsOneWidget, reason: name);
                final endLast = t.getRect(lastCard);
                final nav = t.getRect(find.byKey(_nav));
                final exception = t.takeException();
                expect(exception, isNull, reason: name);
                final values = {
                  'left page margin': first.left,
                  'right page margin': (compact ? 375.0 : 430.0) - first.right,
                  'card gap': endLast.top + position.pixels - firstBottom,
                  'last card to bar': nav.top - endLast.bottom,
                  'scroll extent': position.maxScrollExtent,
                };
                expect(values['left page margin'], closeTo(20, .02));
                expect(values['right page margin'], closeTo(20, .02));
                expect(values['card gap'], closeTo(12, .02), reason: name);
                if (position.maxScrollExtent > 0) {
                  expect(
                    values['last card to bar'],
                    closeTo(16, .02),
                    reason: name,
                  );
                }
                if (_captureRoot.isNotEmpty) {
                  report[name] = {
                    'listGeometry': values,
                    'exception': exception?.toString(),
                  };
                }
              }

              Finder surfaceFor(Finder child) => find
                  .ancestor(
                    of: child,
                    matching: find.byType(ZyraFloatingSurface),
                  )
                  .first;
              Finder paintIn(Finder child) => find
                  .descendant(of: child, matching: find.byType(DecoratedBox))
                  .first;
              Finder requestPaint(Finder card, String keyPrefix) => paintIn(
                find.descendant(
                  of: card,
                  matching: find.byWidgetPredicate((widget) {
                    final key = widget.key;
                    return widget is Container &&
                        key is ValueKey<String> &&
                        key.value.startsWith(keyPrefix);
                  }),
                ),
              );
              Finder received(String id) => requestPaint(
                find.byWidgetPredicate(
                  (w) => w is ZyraRequestActivityCard && w.profile.id == id,
                ),
                'request_activity_card_',
              );
              Finder past(String id) => requestPaint(
                find.byWidgetPredicate(
                  (w) => w is ZyraPastRequestActivityCard && w.profile.id == id,
                ),
                'past_request_activity_card_',
              );
              Finder ended(String id) => paintIn(
                find.byWidgetPredicate(
                  (w) =>
                      w is ZyraOneJourneyConnectionsActiveCard &&
                      w.profile.id == id,
                ),
              );

              if (guardian) {
                if (basic) return;
                await open('guardian_connect');
                await inspectList(
                  'Guardian Connect — populated',
                  surfaceFor(find.text("Aisha's Main Guardian")),
                  surfaceFor(find.text("Noor's Main Guardian")),
                );
                await open('guardian_introductions');
                final introductions = find.text('Suggested to Adam');
                expect(introductions, findsNWidgets(2));
                await inspectList(
                  'Guardian Introductions — populated',
                  surfaceFor(introductions.first),
                  surfaceFor(introductions.last),
                );
              } else {
                await open('concept-my-requests');
                await inspectList(
                  'Seeker Requests — Received',
                  received('draft-amira'),
                  received('draft-aisha'),
                );
                final pastTab = _key('draft_requests_2');
                expect(pastTab.hitTestable(), findsOneWidget);
                await t.tap(pastTab);
                await t.pump();
                await t.pump(const Duration(milliseconds: 650));
                await t.pump();
                await inspectList(
                  'Seeker Requests — Past',
                  past('draft-hana'),
                  past('draft-maryam'),
                );
                await open('concept-my-ended');
                await inspectList(
                  'Seeker Ended Journeys — populated',
                  ended('draft-sara'),
                  ended('draft-noor'),
                );
              }
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
            final settings = _key('concept_settings');
            expect(settings.hitTestable(), findsOneWidget);
            await t.tap(settings);
            await t.pump(const Duration(milliseconds: 650));
            final settingsSpacing = <String, double>{};
            for (final label in ['ACCOUNT', 'PRIVACY']) {
              final card = _key('concept-settings-section-$label');
              if (card.evaluate().isEmpty) {
                await t.scrollUntilVisible(
                  card,
                  120,
                  scrollable: find.descendant(
                    of: _key('concept-current-settings-scroll'),
                    matching: find.byType(Scrollable),
                  ),
                );
              }
              final surface = t.getRect(card);
              final width = compact ? 375.0 : 430.0;
              final gap = surface.top - t.getRect(find.text(label)).bottom;
              expect(surface.left, closeTo(20, .02));
              expect(width - surface.right, closeTo(20, .02));
              expect(gap, closeTo(8, .02), reason: label);
              settingsSpacing['left page margin'] = surface.left;
              settingsSpacing['right page margin'] = width - surface.right;
              settingsSpacing['$label label to card'] = gap;
            }
            final settingsException = t.takeException();
            expect(settingsException, isNull, reason: 'Settings');
            if (_captureRoot.isNotEmpty) {
              report['Settings'] = {
                'ruleB': settingsSpacing,
                'exception': settingsException?.toString(),
              };
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
              if (!basic) {
                await t.tap(_key('journey_tab_dot_target_1'));
                await t.pump(const Duration(milliseconds: 500));
                expect(find.text('Free place'), findsOneWidget);
                await measure('Journey — free place');
                await t.tap(_key('journey_tab_dot_target_0'));
                await t.pump(const Duration(milliseconds: 500));
              }
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
              expect(find.text('Journey access'), findsNothing);
              expect(find.text('Details'), findsNothing);
              await measure('Guardian — populated');
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
                guardianPage: cardWidget.people.length + (basic ? 0 : 1),
              );
              expect(find.text('Add a Guardian'), findsWidgets);
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
            await mount(
              t,
              guardian: guardian,
              basic: basic,
              tab: 2,
              active: true,
              populated: true,
            );
            await measure('My ZYRA — activity');
            if (guardian) {
              final tile = _key('guardian_requests');
              await Scrollable.ensureVisible(t.element(tile), alignment: .5);
              await t.pump(const Duration(milliseconds: 500));
              await t.tap(tile);
              await t.pump(const Duration(milliseconds: 500));
              await measure('Guardian Journey requests — populated');
            }
            await measurePopulatedLists();
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
                expect(find.text('Guardian One'), findsOneWidget);
                expect(find.text('Chat in a Journey'), findsOneWidget);
                final gateException = t.takeException();
                if (_captureRoot.isNotEmpty) {
                  report[name] = {
                    'absent': 'Guardian Basic opens Guardian One comparison',
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
