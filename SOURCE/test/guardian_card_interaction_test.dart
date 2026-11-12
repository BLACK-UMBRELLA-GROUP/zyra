import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:zyra/widgets/zyra_guardian_add_card.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_family_sheet.dart';
import 'package:zyra/dev/zyra_one_journey_monogram_presentation.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_profiles_components.dart';
import 'support/guardian_card_driver.dart';

const _hassanId = 'queue48-hassan';
const _ibrahimId = 'queue48-ibrahim';
const _journeyId = 'queue48-sara';
const _geometryFont = 'Line77GuardianGeometryPoppins';
const _wrappedStage = 'Stage 1 of 8 · Salam Exchange';
Finder _key(String id) => find.byKey(ValueKey(id));
Finder _card(String id) => _key('guardian-card-$id');
Finder get _menu => _key('guardian-card-menu');
Finder get _menuSheet => _key('guardian-card-menu-sheet');
Finder get _menuCancel => _key('guardian-card-menu-cancel');
Finder _edge(String side) => _key('guardian-card-edge-$side');
Finder _free(int index) => _key('guardian-card-free-place-$index');
Finder _tile(String id) => _key('guardian-card-tile-$id');
Finder _dotTarget(int index) => _key('guardian-card-dot-target-$index');
Finder get _dots => find.byType(ZyraProfilesDots);
Finder get _addButton => _key('guardian-card-add-button');
Finder _history(String id) => _key('guardian-card-history-$id');
Finder _view(String id) => _key('guardian-card-view-$id-$_journeyId');
Finder _chat(String id) => _key('guardian-card-chat-$id-$_journeyId');

ZyraGuardianCardPerson _person({
  required String id,
  required String name,
  required DateTime linkedAt,
  bool main = false,
  bool basic = false,
  bool history = false,
}) => ZyraGuardianCardPerson(
  person: WaliLinkedPerson(
    id: id,
    firstName: name,
    isMain: main,
    relationship: main ? 'father' : 'uncle',
    linkedAt: linkedAt,
  ),
  membership: basic ? 'Guardian Basic' : 'Guardian One',
  history: history,
);

List<ZyraGuardianCardPerson> _people({bool mainBasic = false}) => [
  _person(
    id: _ibrahimId,
    name: 'Ibrahim',
    linkedAt: DateTime(2026, 10, 2),
    basic: true,
  ),
  _person(
    id: _hassanId,
    name: 'Hassan',
    linkedAt: DateTime(2026, 9, 20),
    main: true,
    basic: mainBasic,
  ),
];

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Guardian card interaction fixtures must remain offline.');
  }
}

class _Harness extends StatefulWidget {
  const _Harness({
    required super.key,
    required this.people,
    this.basic = false,
    this.initialPage = 0,
    this.journeys = 1,
    this.capacity,
    this.stage = 'Stage 4 of 8 · Faith & Values',
    this.stageNumber,
    this.familyState = ZyraGuardianFamilyState.noFamily,
  });

  final List<ZyraGuardianCardPerson> people;
  final bool basic;
  final int initialPage, journeys;
  final int? capacity, stageNumber;
  final String stage;
  final ZyraGuardianFamilyState familyState;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late List<ZyraGuardianCardPerson> people;
  late int initialPage;
  final permissions =
      <({String guardian, String journey, bool? view, bool? chat})>[];
  final histories = <({String guardian, bool enabled})>[];
  final management = <String>[];
  final pages = <int>[];
  final grants = <String, ({bool view, bool chat})>{};
  var allowed = true;
  var epoch = 0;
  var revision = 0;
  var identity = 'seeker-a';
  var adds = 0;
  var upgrades = 0;
  var circles = 0;
  bool Function()? authority;
  void replaceAuthority(bool Function() next) =>
      setState(() => authority = next);

  @override
  void initState() {
    super.initState();
    people = widget.people;
    initialPage = widget.initialPage;
    for (final person in people) {
      grants[person.person.id] = (
        view: true,
        chat: person.person.isMain && !person.basic,
      );
    }
  }

  void changeContext() => setState(() {
    identity = '$identity-next';
    epoch++;
    revision++;
  });

  void changeRevision() => setState(() => revision++);

  void changeEpoch() => setState(() => epoch++);

  void selectFromParent(int page) => setState(() => initialPage = page);

  void removeGuardian(String id, {bool resetPage = false}) => setState(() {
    people = people.where((p) => p.person.id != id).toList();
    if (resetPage) initialPage = 0;
    revision++;
  });

  void cover() => setState(() {
    allowed = false;
    epoch++;
    revision++;
  });

  void recover() => setState(() {
    allowed = true;
    epoch++;
    revision++;
  });

  void _permission(String guardian, String journey, {bool? view, bool? chat}) {
    permissions.add((
      guardian: guardian,
      journey: journey,
      view: view,
      chat: chat,
    ));
    final old = grants[guardian]!;
    final newView = view ?? old.view;
    setState(() {
      grants[guardian] = (view: newView, chat: newView && (chat ?? old.chat));
      revision++;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ZyraOneJourneyGuardianCards(
      people: people,
      journeysFor: (id) {
        final person = people.firstWhere((p) => p.person.id == id);
        final access = grants[id]!;
        return [
          for (var i = 0; i < widget.journeys; i++)
            ZyraGuardianCardJourney(
              id: i == 0 ? _journeyId : '$_journeyId-$i',
              attempt: 7 + i,
              name: 'Sara',
              stageNumber:
                  widget.stageNumber ?? (widget.stage == _wrappedStage ? 1 : 4),
              stage: widget.stage,
              view: access.view,
              chat: access.chat,
              canChange: !person.person.isMain,
            ),
        ];
      },
      capacity: widget.capacity ?? (widget.basic ? 1 : 3),
      basic: widget.basic,
      canAct: authority ?? () => allowed,
      interactionEpoch: () => epoch,
      contextIdentity: identity,
      renderIdentity: revision,
      initialPage: initialPage,
      unread: 2,
      familyState: widget.familyState,
      onPage: pages.add,
      onHistory: (id, enabled) {
        histories.add((guardian: id, enabled: enabled));
        setState(() {
          people = [
            for (final value in people)
              if (value.person.id == id)
                ZyraGuardianCardPerson(
                  person: value.person,
                  membership: value.membership,
                  history: enabled,
                  familyPlace: value.familyPlace,
                )
              else
                value,
          ];
          revision++;
        });
      },
      onPermission: _permission,
      makeMain: (id) async {
        management.add('main:$id');
        return true;
      },
      clearMain: (id) async {
        management.add('clear:$id');
        return true;
      },
      remove: (id) async {
        management.add('remove:$id');
        return null;
      },
      onAdd: () => adds++,
      onUpgrade: () => upgrades++,
      onCircle: () => circles++,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  late GlobalKey<_HarnessState> host;
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;

  setUpAll(() async {
    final font = FontLoader(_geometryFont);
    for (final weight in ['Light', 'Regular', 'Medium']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await font.load();
  });

  setUp(() {
    host = GlobalKey<_HarnessState>();
    calls.clear();
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    ZyraAccountState.resetForTesting();
    ZyraText.useTestFontStubs = true;
    ZyraInteractionStyle.restoreDefaults();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    ZyraText.useTestFontStubs = false;
    ZyraInteractionStyle.restoreDefaults();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> mount(
    WidgetTester tester, {
    List<ZyraGuardianCardPerson>? people,
    bool basic = false,
    int initialPage = 0,
    int journeys = 1,
    int? capacity,
    String stage = 'Stage 4 of 8 · Faith & Values',
    int? stageNumber,
    Size size = const Size(430, 932),
    double topInset = 0,
    double bottomInset = 0,
    double scale = 1,
    ZyraGuardianFamilyState familyState = ZyraGuardianFamilyState.noFamily,
    bool disableAnimations = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.padding = FakeViewPadding(top: topInset, bottom: bottomInset);
    tester.view.viewPadding = FakeViewPadding(
      top: topInset,
      bottom: bottomInset,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
        home: _Harness(
          key: host,
          people: people ?? _people(),
          basic: basic,
          initialPage: initialPage,
          journeys: journeys,
          capacity: capacity,
          stage: stage,
          stageNumber: stageNumber,
          familyState: familyState,
        ),
      ),
    );
    await tester.pump();
  }

  _HarnessState state() => host.currentState!;
  int haptics() =>
      calls.where((c) => c.method == 'HapticFeedback.vibrate').length;
  VoidCallback pageAction(WidgetTester tester) => tester
      .widget<GestureDetector>(
        _dotTarget(tester.widget<ZyraProfilesDots>(_dots).index + 1),
      )
      .onTap!;
  VoidCallback semanticAction(WidgetTester tester, Finder finder) =>
      tester.widget<Semantics>(finder).properties.onTap!;
  VoidCallback physicalHistory(WidgetTester tester, String id) => tester
      .element(_history(id))
      .findAncestorWidgetOfExactType<GestureDetector>()!
      .onTap!;
  VoidCallback physicalPermission(WidgetTester tester, Finder finder) => tester
      .widget<GestureDetector>(
        find
            .descendant(of: finder, matching: find.byType(GestureDetector))
            .first,
      )
      .onTap!;

  Future<void> next(WidgetTester tester) => swipeGuardianCard(tester);

  Future<void> dragAmount(
    WidgetTester tester,
    String id,
    double fraction,
  ) async {
    final bounds = tester.getRect(_card(id));
    final gesture = await tester.startGesture(bounds.center);
    await gesture.moveBy(Offset(bounds.width * fraction, 0));
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<VoidCallback> confirmation(
    WidgetTester tester, {
    String actionKey = 'guardian-make-main',
  }) async {
    if (_menuSheet.evaluate().isEmpty) {
      await tester.ensureVisible(_menu);
      await tester.tap(_menu);
      await tester.pumpAndSettle();
    }
    final action = _key(actionKey);
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    final confirm = _key('$actionKey-confirmation-approve');
    expect(confirm, findsOneWidget);
    return tester.widget<TextButton>(confirm).onPressed!;
  }

  test('Model starts Main Chat on and Additional Chat off', () {
    final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
    const peer = 'draft-sara';
    expect(
      model.sampleGuardianAccessFor(
        'draft-guardian-hassan',
        peer,
        isMain: true,
      ),
      (view: true, chat: true),
    );
    expect(model.sampleGuardianAccessFor('draft-guardian-yusuf', peer), (
      view: true,
      chat: false,
    ));
  });

  test('Model View off clears Chat and Basic cannot write a Chat grant', () {
    final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
    const guardian = 'draft-guardian-yusuf', peer = 'draft-sara';
    expect(
      model.setSampleGuardianJourneyAccess(guardian, peer, chatEnabled: true),
      isTrue,
    );
    expect(
      model.setSampleGuardianJourneyAccess(guardian, peer, viewEnabled: false),
      isTrue,
    );
    expect(model.sampleGuardianAccessFor(guardian, peer), (
      view: false,
      chat: false,
    ));
    expect(
      model.setSampleGuardianJourneyAccess(guardian, peer, viewEnabled: true),
      isTrue,
    );
    expect(model.sampleGuardianAccessFor(guardian, peer), (
      view: true,
      chat: false,
    ));
    expect(
      model.setSampleGuardianMembership(
        guardian,
        DraftGuardianMembership.basic,
      ),
      isTrue,
    );
    expect(
      model.setSampleGuardianJourneyAccess(guardian, peer, chatEnabled: true),
      isFalse,
    );
    expect(model.sampleGuardianAccessFor(guardian, peer).chat, isFalse);
  });

  testWidgets('Main then linked-date order, invited Omar, Add last', (
    tester,
  ) async {
    await mount(
      tester,
      people: [
        ..._people(),
        _person(
          id: 'queue48-yusuf',
          name: 'Yusuf',
          linkedAt: DateTime(2026, 9, 10),
        ),
      ],
    );
    expect(find.text('Hassan'), findsOneWidget);
    await next(tester);
    expect(find.text('Yusuf'), findsOneWidget);
    await next(tester);
    expect(find.text('Ibrahim'), findsOneWidget);
    await next(tester);
    expect(find.text('Omar'), findsOneWidget);
    expect(find.text('Waiting for Omar'), findsOneWidget);
    expect(find.text('Waiting for Omar to accept'), findsOneWidget);
    expect(find.text('Send invitation again'), findsNothing);
    await next(tester);
    expect(_card('add'), findsOneWidget);
    expect(find.text('Add a Guardian'), findsOneWidget);
    expect(state().pages, [1, 2, 3, 4]);
  });

  testWidgets('Guardian swipes stop at either end without arrows', (
    tester,
  ) async {
    await mount(tester);
    expect(_key('guardian-card-previous'), findsNothing);
    await swipeGuardianCard(tester, next: false);
    expect(_card(_hassanId), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await next(tester);
    }
    expect(_key('guardian-card-next'), findsNothing);
    expect(_card('add'), findsOneWidget);
    await next(tester);
    expect(state().pages, [1, 2, 3]);
    await swipeGuardianCard(tester, next: false);
    expect(_card('preview-invited-omar'), findsOneWidget);
  });

  testWidgets(
    'Normal horizontal touch slop separates a tap from a swipe both ways',
    (tester) async {
      await mount(tester);
      await dragAmount(tester, _hassanId, -.01);
      expect(find.text('Hassan'), findsOneWidget);
      await dragAmount(tester, _hassanId, -.20);
      expect(find.text('Ibrahim'), findsOneWidget);
      await dragAmount(tester, _ibrahimId, .01);
      expect(find.text('Ibrahim'), findsOneWidget);
      await dragAmount(tester, _ibrahimId, .20);
      expect(find.text('Hassan'), findsOneWidget);
      expect(state().pages, [1, 0]);
    },
  );

  testWidgets('Physical swipe selects the next complete card', (tester) async {
    await mount(tester);
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
    expect(_history(_hassanId), findsOneWidget);
    await next(tester);
    expect(find.text('Ibrahim'), findsOneWidget);
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
    expect(_history(_ibrahimId), findsOneWidget);
    expect(find.byKey(const ValueKey('guardian-card-details')), findsNothing);
    expect(find.byKey(const ValueKey('guardian-card-access')), findsNothing);
    final before = haptics();
    await tester.tapAt(tester.getRect(_card(_ibrahimId)).center);
    await tester.pump();
    expect(state().pages, [1]);
    expect(haptics(), before);
  });

  testWidgets('Guardian follows a chip drag and springs back below 60 pt', (
    tester,
  ) async {
    await mount(tester, initialPage: 1, disableAnimations: false);
    final chip = _view(_ibrahimId);
    final start = tester.getCenter(chip);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(-42, 0));
    await tester.pump();
    expect(tester.getCenter(chip).dx, closeTo(start.dx - 42, 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getCenter(chip), start);
    expect(state().permissions, isEmpty);
    expect(state().pages, isEmpty);
  });

  testWidgets('Guardian neighbour follows a chip swipe and stays inert', (
    tester,
  ) async {
    await mount(tester, initialPage: 1, disableAnimations: false);
    final chip = _chat(_ibrahimId);
    final current = _card(_ibrahimId);
    final neighbour = _card('preview-invited-omar');
    final bounds = tester.getRect(current);
    final gesture = await tester.startGesture(tester.getCenter(chip));
    await gesture.moveBy(const Offset(-185, 0));
    await tester.pump();
    expect(tester.getRect(current).left, closeTo(bounds.left - 185, 1));
    expect(tester.getRect(neighbour).left, lessThan(bounds.right));
    expect(
      tester.getRect(neighbour).left - tester.getRect(current).right,
      closeTo(24, 1),
    );
    expect(neighbour.hitTestable(), findsNothing);
    final scope = find.ancestor(
      of: neighbour,
      matching: find.byType(ExcludeFocus),
    );
    expect(tester.widget<ExcludeFocus>(scope.first).excluding, isTrue);
    expect(state().pages, isEmpty);

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.getRect(neighbour).left, greaterThan(bounds.left));
    expect(state().pages, isEmpty);
    await tester.pumpAndSettle();
    expect(tester.getRect(neighbour), bounds);
    expect(current, findsNothing);
    expect(state().pages, [2]);
    expect(state().permissions, isEmpty);
  });

  testWidgets('A retained neighbour action stays inert after springback', (
    tester,
  ) async {
    await mount(tester, disableAnimations: false);
    final gesture = await tester.startGesture(
      tester.getCenter(_card(_hassanId)),
    );
    await gesture.moveBy(const Offset(-44, 0));
    await tester.pump();
    final neighbourAction = tester
        .widget<Semantics>(_view(_ibrahimId))
        .properties
        .onTap!;
    await gesture.up();
    await tester.pumpAndSettle();

    final before = haptics();
    neighbourAction();
    await tester.pump();
    expect(state().permissions, isEmpty);
    expect(state().pages, isEmpty);
    expect(haptics(), before);
  });

  testWidgets('Guardian resists at the end and animates edge and dot taps', (
    tester,
  ) async {
    await mount(tester, disableAnimations: false);
    final first = _card(_hassanId);
    final second = _card(_ibrahimId);
    final start = tester.getCenter(first);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();
    expect(tester.getCenter(first).dx - start.dx, closeTo(36, 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(state().pages, isEmpty);
    await tester.tap(_edge('right'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getCenter(second).dx, greaterThan(start.dx));
    expect(state().pages, isEmpty);
    final before = haptics();
    await tester.tap(_dotTarget(0), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(state().pages, [1]);
    expect(haptics(), before);
    await tester.tap(_dotTarget(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getCenter(first).dx, lessThan(start.dx));
    await tester.pumpAndSettle();
    expect(state().pages, [1, 0]);
  });

  testWidgets(
    'Reduce Motion changes Guardian immediately without dragging artwork',
    (tester) async {
      await mount(tester, initialPage: 1);
      final chip = _view(_ibrahimId);
      final start = tester.getCenter(chip);
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(-110, 0));
      await tester.pump();
      expect(tester.getCenter(chip), start);
      expect(_card('preview-invited-omar'), findsNothing);
      await gesture.up();
      await tester.pump();
      expect(_card('preview-invited-omar'), findsOneWidget);
      expect(state().permissions, isEmpty);
      expect(state().pages, [2]);
    },
  );

  testWidgets('26 pt card edges select once and stop at the ends', (
    tester,
  ) async {
    await mount(tester);
    final main = tester.getRect(_card(_hassanId));
    expect(_edge('left'), findsNothing);
    final right = tester.getRect(_edge('right'));
    expect(
      right,
      Rect.fromLTRB(main.right - 26, main.top, main.right, main.bottom),
    );
    final before = haptics();
    await tester.tap(_edge('right'));
    await tester.pump();
    expect(state().pages, [1]);
    expect(haptics() - before, 1);
    final additional = tester.getRect(_card(_ibrahimId));
    final left = tester.getRect(_edge('left'));
    expect(
      left,
      Rect.fromLTRB(
        additional.left,
        additional.top,
        additional.left + 26,
        additional.bottom,
      ),
    );
    await tester.tap(_edge('left'));
    await tester.pump();
    expect(state().pages, [1, 0]);
    expect(haptics() - before, 2);
    await tester.tapAt(main.centerLeft + const Offset(12, 0));
    await tester.pump();
    expect(state().pages, [1, 0]);
    expect(haptics() - before, 2);
    for (var i = 0; i < 2; i++) {
      await tester.tap(_edge('right'));
      await tester.pump();
    }
    final invited = _card('preview-invited-omar');
    expect(invited, findsOneWidget);
    expect(_edge('right'), findsNothing);
    await tester.tapAt(
      tester.getRect(invited).centerRight - const Offset(12, 0),
    );
    await tester.pump();
    expect(state().pages, [1, 0, 1, 2]);
    expect(haptics() - before, 4);
    await next(tester);
    expect(_card('add'), findsOneWidget);
    expect(_edge('left'), findsNothing);
    expect(_edge('right'), findsNothing);
    expect(state().pages, [1, 0, 1, 2, 3]);
  });

  for (final count in [1, 2, 3, 4]) {
    testWidgets('Guardian dots count $count people and never count Add', (
      tester,
    ) async {
      final linked = count == 1 ? 1 : count - 1;
      await mount(
        tester,
        basic: count == 1,
        people: [
          _people().last,
          for (var i = 1; i < linked; i++)
            _person(
              id: 'extra-$i',
              name: 'Extra $i',
              linkedAt: DateTime(2026, 10, i),
            ),
        ],
      );
      final dots = tester.widget<ZyraProfilesDots>(_dots);
      expect(dots.count, count);
      expect(dots.index, 0);
      expect(_dotTarget(count), findsNothing);
      final firstDot = tester
          .element(_dotTarget(0))
          .findAncestorWidgetOfExactType<Semantics>()!
          .properties;
      expect(firstDot.label, 'Hassan');
      expect(firstDot.selected, isTrue);
      expect(tester.widget<ZyraProfilesDots>(_dots).count, count);
      expect(tester.widget<ZyraProfilesDots>(_dots).index, 0);
      final physicalHaptics = haptics();
      await tester.tap(_dotTarget(0));
      await tester.pump();
      expect(haptics() - physicalHaptics, 1);
      expect(find.text('JOURNEY ACCESS'), findsOneWidget);
      if (count > 1) {
        final lastDot = tester
            .element(_dotTarget(count - 1))
            .findAncestorWidgetOfExactType<Semantics>()!
            .properties;
        expect(lastDot.label, 'Omar');
        final semanticHaptics = haptics();
        lastDot.onTap!();
        await tester.pump();
        expect(haptics() - semanticHaptics, 1);
        expect(_card('preview-invited-omar'), findsOneWidget);
        expect(_addButton.hitTestable(), findsNothing);
        expect(state().adds, 0);
      }
      await next(tester);
      expect(_card('add'), findsOneWidget);
      expect(tester.widget<ZyraProfilesDots>(_dots).index, -1);
      expect(tester.widget<ZyraProfilesDots>(_dots).count, count);
      await tester.tap(_dotTarget(0));
      await tester.pump();
      expect(_card(_hassanId), findsOneWidget);
    });
  }

  testWidgets('Basic with no Guardian offers Add without page dots', (
    tester,
  ) async {
    await mount(tester, basic: true, people: []);
    expect(_dots, findsNothing);
    expect(_card('add'), findsOneWidget);
    expect(find.text('View Seeker One'), findsNothing);
    final before = haptics();
    await tester.tap(_addButton);
    await tester.pump();
    expect(state().adds, 1);
    expect(haptics() - before, 1);
  });

  testWidgets('Add presses to 96 percent and cancels without opening', (
    tester,
  ) async {
    await mount(tester, people: [], disableAnimations: false);
    final feedback = find.ancestor(
      of: _addButton,
      matching: find.byType(AnimatedScale),
    );
    expect(tester.widget<AnimatedScale>(feedback).scale, 1);
    final gesture = await tester.startGesture(tester.getCenter(_addButton));
    await tester.pump();
    expect(tester.widget<AnimatedScale>(feedback).scale, .96);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(feedback).scale, 1);
    expect(state().adds, 0);
  });

  testWidgets('Guardian card follows the selected roster entry after removal', (
    tester,
  ) async {
    await mount(tester);
    state().removeGuardian(_hassanId);
    await tester.pump();
    expect(_card(_ibrahimId), findsOneWidget);
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
  });

  testWidgets(
    'A parent page reset after removing the second Guardian opens the first card',
    (tester) async {
      await mount(tester, initialPage: 1);
      expect(_card(_ibrahimId), findsOneWidget);
      state().removeGuardian(_ibrahimId, resetPage: true);
      await tester.pump();
      expect(_card(_hassanId), findsOneWidget);
      expect(tester.widget<ZyraProfilesDots>(_dots).index, 0);
      expect(find.text('JOURNEY ACCESS'), findsOneWidget);
    },
  );

  testWidgets('A drag begun before an authority revision cannot change cards', (
    tester,
  ) async {
    await mount(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(_card(_hassanId)),
    );
    await gesture.moveBy(const Offset(-40, 0));
    state().changeContext();
    await tester.pump();
    final before = haptics();
    await gesture.moveBy(const Offset(-120, 0));
    await gesture.up();
    await tester.pump();
    expect(state().pages, isEmpty);
    expect(haptics(), before);
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
    await next(tester);
    expect(state().pages, [1]);
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
  });

  testWidgets('A pointer down under the old owner cannot start a new drag', (
    tester,
  ) async {
    await mount(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(_card(_hassanId)),
    );
    state().changeContext();
    await tester.pump();
    await gesture.moveBy(const Offset(-120, 0));
    await gesture.up();
    await tester.pump();
    expect(state().pages, isEmpty);
    expect(_card(_hassanId), findsOneWidget);
    await next(tester);
    expect(state().pages, [1]);
  });

  for (final size in [const Size(430, 932), const Size(375, 667)]) {
    for (final places in [1, 2, 3]) {
      testWidgets(
        'Guardian allocates $places equal Journey rows at ${size.width} pt',
        (tester) async {
          ZyraText.testReadingFontFamily = _geometryFont;
          addTearDown(() => ZyraText.testReadingFontFamily = null);
          await mount(
            tester,
            size: size,
            topInset: size.width == 430 ? 59 : 20,
            bottomInset: size.width == 430 ? 34 : 0,
            journeys: 1,
            capacity: places,
            stage: _wrappedStage,
          );
          final card = tester.getRect(_card(_hassanId));
          final tile = _tile(_journeyId);
          final first = tester.getRect(tile);
          final label = tester.getRect(find.text('JOURNEY ACCESS'));
          final stage = find.descendant(
            of: tile,
            matching: find.text(_wrappedStage),
          );
          expect(tester.widget<Text>(stage).style!.fontSize, 11);
          final photo = find.descendant(
            of: tile,
            matching: find.byType(ZyraGoldRingMonogram),
          );
          expect(tester.getSize(photo), const Size.square(42));
          final progress = find.descendant(
            of: tile,
            matching: find.byType(LinearProgressIndicator),
          );
          expect(tester.widget<LinearProgressIndicator>(progress).value, 1 / 8);
          expect(tester.getSize(progress).height, 3);
          expect(first.top - label.bottom, closeTo(8, 0.1));
          for (final item in [
            stage,
            progress,
            _view(_hassanId),
            _chat(_hassanId),
          ]) {
            final rect = tester.getRect(item);
            expect(rect.left, greaterThanOrEqualTo(first.left));
            expect(rect.top, greaterThanOrEqualTo(first.top));
            expect(rect.right, lessThanOrEqualTo(first.right));
            expect(rect.bottom, lessThanOrEqualTo(first.bottom));
          }
          var last = first;
          for (var i = 1; i < places; i++) {
            final row = tester.getRect(_free(i));
            expect(row.height, closeTo(first.height, 0.1));
            expect(row.top - last.bottom, closeTo(0, 0.1));
            last = row;
          }
          final summary = tester.getRect(_key('guardian-card-summary-row'));
          expect(summary.top - last.bottom, closeTo(0, 0.1));
          expect(card.bottom - summary.bottom, inInclusiveRange(0, 20));
          final reader = find.descendant(
            of: _card(_hassanId),
            matching: find.byType(Scrollable),
          );
          if (reader.evaluate().isNotEmpty) {
            expect(
              tester.state<ScrollableState>(reader).position.maxScrollExtent,
              0,
            );
          }
          await tester.dragFrom(first.center, const Offset(0, -100));
          await tester.pumpAndSettle();
          expect(tester.getRect(_card(_hassanId)), card);
          expect(tester.getRect(tile), first);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('All eight stage labels fit three occupied places at 375 pt', (
    tester,
  ) async {
    ZyraText.testReadingFontFamily = _geometryFont;
    addTearDown(() => ZyraText.testReadingFontFamily = null);
    for (final stage in ZyraJourneyStages.all) {
      final label = 'Stage ${stage.order} of 8 · ${stage.label}';
      await mount(
        tester,
        size: const Size(375, 667),
        topInset: 20,
        journeys: 3,
        stage: label,
        stageNumber: stage.order,
      );
      final card = _card(_hassanId);
      final reader = find.descendant(
        of: card,
        matching: find.byType(Scrollable),
      );
      expect(
        tester.state<ScrollableState>(reader).position.maxScrollExtent,
        0,
        reason: label,
      );
      final rows = [
        _tile(_journeyId),
        for (var i = 1; i < 3; i++) _tile('$_journeyId-$i'),
      ];
      final height = tester.getSize(rows.first).height;
      for (final row in rows) {
        expect(tester.getSize(row).height, closeTo(height, .1), reason: label);
        final tile = tester.getRect(row);
        final stageText = tester.getRect(
          find.descendant(of: row, matching: find.text(label)),
        );
        expect(tile.intersect(stageText), stageText, reason: label);
        final progress = find.descendant(
          of: row,
          matching: find.byType(LinearProgressIndicator),
        );
        expect(
          tester.widget<LinearProgressIndicator>(progress).value,
          stage.order / 8,
        );
      }
      expect(tester.takeException(), isNull);
    }
  });

  for (final viewport in [
    (size: const Size(375, 667), scale: 2.0),
    (size: const Size(320, 568), scale: 2.0),
  ]) {
    testWidgets(
      'Guardian frame stays fixed when content overflows at ${viewport.size.width} pt',
      (tester) async {
        ZyraText.testReadingFontFamily = _geometryFont;
        addTearDown(() => ZyraText.testReadingFontFamily = null);
        await mount(
          tester,
          size: viewport.size,
          topInset: 20,
          scale: viewport.scale,
          journeys: 3,
          stage: _wrappedStage,
        );
        final frame = tester.getRect(_card(_hassanId));
        final reader = find.descendant(
          of: _card(_hassanId),
          matching: find.byType(Scrollable),
        );
        final position = tester.state<ScrollableState>(reader).position;
        expect(position.maxScrollExtent, greaterThan(0));
        expect(position.physics, isA<ClampingScrollPhysics>());
        await tester.dragFrom(
          Offset(frame.center.dx, frame.bottom - 45),
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();
        expect(position.pixels, greaterThan(0));
        expect(tester.getRect(_card(_hassanId)), frame);
        await tester.ensureVisible(_history(_hassanId));
        expect(_history(_hassanId).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'History physical and semantic taps each change one bit on the same card',
    (tester) async {
      await mount(tester);
      final before = haptics();
      await tester.tap(_history(_hassanId));
      await tester.pump();
      expect(state().histories, [(guardian: _hassanId, enabled: true)]);
      expect(haptics() - before, 1);
      expect(find.text('Hassan'), findsOneWidget);
      expect(find.text('JOURNEY ACCESS'), findsOneWidget);
      semanticAction(tester, _history(_hassanId))();
      await tester.pump();
      expect(state().histories.last, (guardian: _hassanId, enabled: false));
      expect(haptics() - before, 2);
      expect(state().pages, isEmpty);
      expect(find.text('JOURNEY ACCESS'), findsOneWidget);
    },
  );

  testWidgets('View and management actions keep the selected Guardian', (
    tester,
  ) async {
    await mount(tester, initialPage: 1);
    final before = haptics();
    await tester.tap(_view(_ibrahimId));
    await tester.pump();
    expect(haptics() - before, 1);
    expect(state().permissions.single, (
      guardian: _ibrahimId,
      journey: _journeyId,
      view: false,
      chat: null,
    ));
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
    final confirm = await confirmation(tester);
    expect(haptics() - before, 3);
    expect(state().pages, isEmpty);
    confirm();
    confirm();
    await tester.pumpAndSettle();
    expect(haptics() - before, 4);
    expect(state().management, ['main:$_ibrahimId']);
    expect(state().pages, isEmpty);
    expect(_menuSheet, findsNothing);
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
  });

  testWidgets('Main and Remove confirmations are cancellable and exact once', (
    tester,
  ) async {
    await mount(tester);
    final initial = haptics();
    await tester.tap(_menu);
    await tester.pumpAndSettle();
    expect(haptics() - initial, 1);
    expect(find.text('Remove as Main Guardian'), findsOneWidget);
    final remove = tester.widget<Text>(find.text('Remove Hassan'));
    expect(remove.style!.color, const Color(0xFFAC453E));
    expect(find.text('Make Main Guardian'), findsNothing);
    final clear = await confirmation(tester, actionKey: 'guardian-clear-main');
    expect(haptics() - initial, 2);
    await tester.tap(
      find.byKey(ValueKey('guardian-clear-main-confirmation-keep')),
    );
    await tester.pumpAndSettle();
    clear();
    expect(haptics() - initial, 3);
    expect(state().management, isEmpty);
    final removeConfirmation = await confirmation(
      tester,
      actionKey: 'guardian-remove',
    );
    expect(haptics() - initial, 5);
    removeConfirmation();
    removeConfirmation();
    await tester.pumpAndSettle();
    expect(haptics() - initial, 6);
    expect(state().management, ['remove:$_hassanId']);
    expect(_menuSheet, findsNothing);
    expect(state().pages, isEmpty);
  });

  testWidgets('Guardian menu dims the whole screen and has owned dismissal', (
    tester,
  ) async {
    await mount(tester);
    Future<void> open() async {
      await tester.tap(_menu);
      await tester.pumpAndSettle();
      expect(_menuSheet, findsOneWidget);
    }

    await open();
    expect(find.text('Hassan · Main Guardian'), findsOneWidget);
    expect(
      find.descendant(of: _card(_hassanId), matching: _menuSheet),
      findsNothing,
    );
    final route =
        ModalRoute.of(tester.element(_menuSheet))
            as ModalBottomSheetRoute<dynamic>;
    expect(
      route.modalBarrierColor,
      const Color(0xFF1E1610).withValues(alpha: .38),
    );
    final sheet = tester.widget<Material>(_menuSheet);
    expect(sheet.color, const Color(0xFFF7F2EA));
    expect(
      sheet.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(26)),
    );
    final barrier = find.byWidgetPredicate(
      (w) =>
          w is AnimatedModalBarrier &&
          w.semanticsLabel == 'Dismiss Guardian actions',
    );
    expect(tester.getRect(barrier), const Rect.fromLTWH(0, 0, 430, 932));
    final staleCancel = tester
        .widget<InkWell>(
          find.descendant(of: _menuCancel, matching: find.byType(InkWell)),
        )
        .onTap!;
    await tester.tap(_menuCancel);
    await tester.pumpAndSettle();
    expect(_menuSheet, findsNothing);

    await open();
    final count = haptics();
    staleCancel();
    await tester.pumpAndSettle();
    expect(_menuSheet, findsOneWidget);
    expect(state().management, isEmpty);
    expect(haptics(), count);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(_menuSheet, findsNothing);
    expect(state().management, isEmpty);
  });

  testWidgets('Covering Guardian actions dismisses only its stale sheet', (
    tester,
  ) async {
    await mount(tester, initialPage: 1);
    await tester.tap(_menu);
    await tester.pumpAndSettle();
    final action = _key('guardian-make-main');
    final staleAction = tester
        .widget<InkWell>(
          find.descendant(of: action, matching: find.byType(InkWell)),
        )
        .onTap!;
    final sheetContext = tester.element(_menuSheet);
    final sheet = ModalRoute.of(sheetContext)!;
    final navigator = Navigator.of(sheetContext);
    final cover = MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Other route')),
    );

    navigator.push(cover);
    state().changeEpoch();
    await tester.pumpAndSettle();
    expect(cover.isCurrent, isTrue);
    expect(sheet.isActive, isFalse);
    navigator.pop();
    state().changeEpoch();
    await tester.pumpAndSettle();
    expect(_menuSheet, findsNothing);
    final before = haptics();
    staleAction();
    expect(state().management, isEmpty);
    expect(haptics(), before);

    await tester.tap(_menu);
    await tester.pumpAndSettle();
    await tester.tap(_menuCancel);
    await tester.pumpAndSettle();
    expect(_menuSheet, findsNothing);
  });

  testWidgets(
    'Seeker Basic keeps linked Guardians and opens independent Add and upgrade actions',
    (tester) async {
      await mount(tester, people: _people(mainBasic: true), basic: true);
      expect(find.text('Hassan'), findsOneWidget);
      expect(_view(_hassanId), findsOneWidget);
      expect(
        tester.widget<Semantics>(_chat(_hassanId)).properties.button,
        isTrue,
      );
      expect(
        tester.widget<Semantics>(_chat(_hassanId)).properties.toggled,
        isNull,
      );
      expect(state().grants[_hassanId]!.chat, isFalse);
      await next(tester);
      expect(find.text('Ibrahim'), findsOneWidget);
      await next(tester);
      expect(find.text('Add a Guardian'), findsOneWidget);
      expect(find.text('Used'), findsOneWidget);
      expect(find.text('Guardian Basic place'), findsOneWidget);
      expect(find.text('Guardian One places'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(
        find.text(
          'Your Guardian Basic place is used, so new Guardians need Guardian One.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Seeker One: any 10 Guardians ›'));
      await tester.pump();
      expect(state().upgrades, 1);
      expect(state().adds, 0);
      expect(find.text('Omar'), findsNothing);
      expect(find.text('Ibrahim'), findsNothing);
      expect(_key('guardian-card-next'), findsNothing);
      await tester.tap(_addButton);
      await tester.pump();
      expect(state().adds, 1);
      expect(state().permissions, isEmpty);
      expect(state().grants[_hassanId]!.chat, isFalse);
    },
  );

  testWidgets(
    'Retained page and history handlers reject a new Guardian target',
    (tester) async {
      await mount(tester);
      final oldPage = pageAction(tester);
      final oldPhysical = physicalHistory(tester, _hassanId);
      final oldSemantic = semanticAction(tester, _history(_hassanId));
      oldPage();
      await tester.pump();
      final count = haptics();
      oldPage();
      oldPhysical();
      oldSemantic();
      await tester.pump();
      expect(state().pages, [1]);
      expect(state().histories, isEmpty);
      expect(haptics(), count);
      expect(find.text('Ibrahim'), findsOneWidget);
    },
  );

  for (final change in [
    'account generation',
    'external epoch',
    'render revision',
    'context',
  ]) {
    testWidgets('Retained page/history handlers reject changed $change', (
      tester,
    ) async {
      await mount(tester);
      final oldPage = pageAction(tester);
      final oldPhysical = physicalHistory(tester, _hassanId);
      final oldSemantic = semanticAction(tester, _history(_hassanId));
      switch (change) {
        case 'account generation':
          ZyraAccountState.resetForTesting();
          break;
        case 'external epoch':
          state().epoch++;
          break;
        case 'render revision':
          state().changeRevision();
          await tester.pump();
          break;
        case 'context':
          state().changeContext();
          await tester.pump();
          break;
      }
      oldPage();
      oldPhysical();
      oldSemantic();
      await tester.pump();
      expect(state().pages, isEmpty);
      expect(state().histories, isEmpty);
      expect(haptics(), 0);
    });
  }

  testWidgets('Retained View and manage Confirm reject moved Guardian', (
    tester,
  ) async {
    await mount(tester, initialPage: 1);
    final view = physicalPermission(tester, _view(_ibrahimId));
    final semanticView = semanticAction(tester, _view(_ibrahimId));
    final beforeView = haptics();
    await next(tester);
    view();
    semanticView();
    await tester.pump();
    expect(state().permissions, isEmpty);
    expect(haptics() - beforeView, 1);

    await tester.tap(_dotTarget(1));
    await tester.pump();
    final confirm = await confirmation(tester);
    final beforeConfirm = haptics();
    state().selectFromParent(2);
    await tester.pumpAndSettle();
    expect(_menuSheet, findsNothing);
    confirm();
    await tester.pump();
    expect(state().management, isEmpty);
    expect(haptics(), beforeConfirm);
    expect(find.text('Omar'), findsOneWidget);
  });

  for (final change in [
    'account generation',
    'external epoch',
    'render revision',
    'context',
  ]) {
    testWidgets('Retained View/Confirm handlers reject changed $change', (
      tester,
    ) async {
      await mount(tester, initialPage: 1);
      final view = physicalPermission(tester, _view(_ibrahimId));
      final semanticView = semanticAction(tester, _view(_ibrahimId));
      final confirm = await confirmation(tester);
      final count = haptics();
      switch (change) {
        case 'account generation':
          ZyraAccountState.resetForTesting();
          break;
        case 'external epoch':
          state().epoch++;
          break;
        case 'render revision':
          state().changeRevision();
          await tester.pump();
          break;
        case 'context':
          state().changeContext();
          await tester.pump();
          break;
      }
      view();
      semanticView();
      confirm();
      await tester.pump();
      expect(state().permissions, isEmpty);
      expect(state().management, isEmpty);
      expect(haptics(), count);
    });
  }

  testWidgets(
    'Actual semantic View activation denies changed epoch before haptic',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await mount(tester, initialPage: 1);
      final target = _view(_ibrahimId);
      final node = tester.getSemantics(target);
      final owner = tester.element(target).renderObject!.owner!.semanticsOwner!;
      expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      final count = haptics();
      state().epoch++;
      owner.performAction(node.id, ui.SemanticsAction.tap);
      await tester.pump();
      expect(state().permissions, isEmpty);
      expect(haptics(), count);
      semantics.dispose();
    },
  );

  testWidgets('External cover and recovery never revive old handlers', (
    tester,
  ) async {
    await mount(tester, initialPage: 1);
    final view = physicalPermission(tester, _view(_ibrahimId));
    final oldPage = pageAction(tester);
    final confirm = await confirmation(tester);
    state().cover();
    await tester.pump();
    final count = haptics();
    view();
    oldPage();
    confirm();
    state().recover();
    await tester.pump();
    view();
    oldPage();
    confirm();
    await tester.pump();
    expect(state().permissions, isEmpty);
    expect(state().management, isEmpty);
    expect(state().pages, isEmpty);
    expect(haptics(), count);
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
  });

  testWidgets(
    'Covered navigation route and return do not revive a page handle',
    (tester) async {
      await mount(tester);
      final oldPage = pageAction(tester);
      state().epoch++;
      Navigator.of(state().context).push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('External cover')),
        ),
      );
      await tester.pumpAndSettle();
      final count = haptics();
      oldPage();
      Navigator.of(tester.element(find.text('External cover'))).pop();
      state().epoch++;
      state().changeRevision();
      await tester.pumpAndSettle();
      oldPage();
      await tester.pump();
      expect(state().pages, isEmpty);
      expect(haptics(), count);
      await next(tester);
      expect(state().pages, [1]);
    },
  );

  testWidgets(
    'Local Family send reopens Invited and Cancel never enables Chat',
    (tester) async {
      await mount(
        tester,
        initialPage: 1,
        familyState: ZyraGuardianFamilyState.freePlace,
      );
      await tester.tap(_chat(_ibrahimId));
      await tester.pumpAndSettle();
      expect(find.text('Give Ibrahim the place'), findsOneWidget);
      await tester.tap(_key('guardian-family-introduction-primary'));
      await tester.pump();
      expect(find.text('Invite sent to Ibrahim'), findsOneWidget);
      await tester.tap(_key('guardian-family-invited-primary'));
      await tester.pumpAndSettle();
      expect(state().permissions, isEmpty);
      expect(state().grants[_ibrahimId]!.chat, isFalse);
      expect(
        find.descendant(of: _chat(_ibrahimId), matching: find.text('Invited')),
        findsOneWidget,
      );
      await tester.tap(_chat(_ibrahimId));
      await tester.pumpAndSettle();
      expect(find.text('Invite sent to Ibrahim'), findsOneWidget);
      final cancel = tester
          .widget<TextButton>(_key('guardian-family-invited-secondary'))
          .onPressed!;
      cancel();
      await tester.pumpAndSettle();
      final count = haptics();
      cancel();
      await tester.pump();
      expect(haptics(), count);
      expect(find.byType(ZyraGuardianFamilySheet), findsNothing);
      expect(
        find.descendant(of: _chat(_ibrahimId), matching: find.text('Chat')),
        findsOneWidget,
      );
      expect(state().permissions, isEmpty);
      expect(state().grants[_ibrahimId]!.chat, isFalse);
    },
  );

  testWidgets('Context replacement clears a local invite and any owned sheet', (
    tester,
  ) async {
    await mount(
      tester,
      initialPage: 1,
      familyState: ZyraGuardianFamilyState.freePlace,
    );
    await tester.tap(_chat(_ibrahimId));
    await tester.pumpAndSettle();
    await tester.tap(_key('guardian-family-introduction-primary'));
    await tester.pump();
    final staleDone = tester
        .widget<FilledButton>(_key('guardian-family-invited-primary'))
        .onPressed!;
    state().changeContext();
    await tester.pumpAndSettle();
    final count = haptics();
    staleDone();
    await tester.pump();
    expect(haptics(), count);
    expect(find.byType(ZyraGuardianFamilySheet), findsNothing);
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
    await tester.tap(_chat(_ibrahimId));
    await tester.pumpAndSettle();
    expect(find.text('Give Ibrahim the place'), findsOneWidget);
    expect(find.text('Invite sent to Ibrahim'), findsNothing);
    expect(state().permissions, isEmpty);
    expect(state().grants[_ibrahimId]!.chat, isFalse);
  });
  testWidgets(
    'Same widget replacement never revives the original admission before feedback',
    (tester) async {
      await mount(tester);
      var admitted = true;
      state().replaceAuthority(() => admitted);
      await tester.pump();
      final oldPage = pageAction(tester),
          oldHistory = physicalHistory(tester, _hassanId);
      admitted = false;
      state().replaceAuthority(() => true);
      await tester.pump();
      final count = haptics();
      oldPage();
      oldHistory();
      await tester.pump();
      expect(state().pages, isEmpty);
      expect(state().histories, isEmpty);
      expect(haptics(), count);
      admitted = true;
      oldPage();
      oldHistory();
      await tester.pump();
      expect(state().pages, isEmpty);
      expect(state().histories, isEmpty);
      expect(haptics(), count);
      await next(tester);
      expect(state().pages, [1]);
    },
  );
  testWidgets(
    'Observed denial permanently revokes that handle through authority return',
    (tester) async {
      await mount(tester);
      final oldPage = pageAction(tester);
      state().allowed = false;
      oldPage();
      state().allowed = true;
      oldPage();
      await tester.pump();
      expect(state().pages, isEmpty);
      expect(haptics(), 0);
      state().changeRevision();
      await tester.pump();
      await next(tester);
      expect(state().pages, [1]);
    },
  );
  testWidgets('LOCK19 uses small gold for role, access and enabled chips', (
    tester,
  ) async {
    await mount(tester);
    final role = tester.widget<Text>(find.text('MAIN GUARDIAN'));
    final heading = tester.widget<Text>(find.text('JOURNEY ACCESS'));
    final view = tester.widget<Text>(find.text('View'));
    expect(role.style!.fontSize, 11);
    expect(role.style!.letterSpacing, 1.2);
    expect(role.style!.color, ZyraColors.goldText);
    expect(heading.style!.color, ZyraColors.goldText);
    expect(view.style!.color, const Color(0xFF845F24));
    final contrast =
        (const Color(0xFFF3EDE3).computeLuminance() + .05) /
        (view.style!.color!.computeLuminance() + .05);
    expect(contrast, greaterThan(4.5));
  });
  testWidgets(
    'Invited card uses a dashed waiting panel without a resend pill',
    (tester) async {
      await mount(tester);
      await next(tester);
      await next(tester);
      final dashed = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.foregroundPainter is ZyraGuardianDashedBorder,
      );
      final invited = _card('preview-invited-omar');
      expect(_menu, findsNothing);
      expect(find.descendant(of: invited, matching: _addButton), findsNothing);
      expect(find.text('Waiting for Omar to accept'), findsOneWidget);
      expect(
        find.textContaining('Access starts once they accept.'),
        findsOneWidget,
      );
      expect(find.descendant(of: invited, matching: dashed), findsNWidgets(2));
      await next(tester);
      expect(
        find.descendant(of: _card('add'), matching: dashed),
        findsOneWidget,
      );
    },
  );
}
