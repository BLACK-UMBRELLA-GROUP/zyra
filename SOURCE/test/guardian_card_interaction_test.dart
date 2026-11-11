import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:zyra/widgets/zyra_guardian_add_card.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_family_sheet.dart';
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
Finder get _access => _key('guardian-card-access');
Finder get _details => _key('guardian-card-details');
Finder _dotTarget(int index) => _key('guardian-card-dot-target-$index');
Finder get _dots => find.byType(ZyraProfilesDots);
Finder get _center => _key('guardian-card-center');
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
    this.stage = 'Stage 4 of 8 · Faith & Values',
    this.familyState = ZyraGuardianFamilyState.noFamily,
  });

  final List<ZyraGuardianCardPerson> people;
  final bool basic;
  final int initialPage, journeys;
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
              stage: widget.stage,
              view: access.view,
              chat: access.chat,
              canChange: !person.person.isMain,
            ),
        ];
      },
      capacity: widget.basic ? 1 : 3,
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
    String stage = 'Stage 4 of 8 · Faith & Values',
    Size size = const Size(430, 932),
    double topInset = 0,
    double scale = 1,
    ZyraGuardianFamilyState familyState = ZyraGuardianFamilyState.noFamily,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.padding = FakeViewPadding(top: topInset);
    tester.view.viewPadding = FakeViewPadding(top: topInset);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: _Harness(
          key: host,
          people: people ?? _people(),
          basic: basic,
          initialPage: initialPage,
          journeys: journeys,
          stage: stage,
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

  Future<void> showAccess(WidgetTester tester) async {
    await tester.tap(_access);
    await tester.pump();
  }

  Future<void> dragAmount(
    WidgetTester tester,
    String id,
    double fraction,
  ) async {
    final detector = tester.widget<GestureDetector>(_card(id));
    final width = tester.getSize(_card(id)).width;
    detector.onHorizontalDragDown!(DragDownDetails());
    detector.onHorizontalDragUpdate!(
      DragUpdateDetails(
        globalPosition: Offset.zero,
        delta: Offset(width * fraction, 0),
      ),
    );
    detector.onHorizontalDragEnd!(DragEndDetails());
    await tester.pump();
  }

  Future<VoidCallback> confirmation(
    WidgetTester tester, {
    String label = 'Make Main',
  }) async {
    final action = find.text(label);
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    final confirm = find.widgetWithText(InkWell, 'Confirm');
    expect(confirm, findsOneWidget);
    return tester.widget<InkWell>(confirm).onTap!;
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
    expect(find.text('Send invitation again'), findsOneWidget);
    await next(tester);
    expect(_card('add'), findsOneWidget);
    expect(find.text('Add a Guardian'), findsNWidgets(2));
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

  testWidgets('Physical swipe opens next Details and card tap has no action', (
    tester,
  ) async {
    await mount(tester);
    await showAccess(tester);
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
    await next(tester);
    expect(find.text('Ibrahim'), findsOneWidget);
    await tester.tapAt(
      tester.getTopLeft(_card(_ibrahimId)) + const Offset(12, 12),
    );
    await tester.pump();
    expect(find.text('JOURNEY ACCESS'), findsNothing);
    expect(tester.widget<Semantics>(_details).properties.selected, isTrue);
    expect(
      tester.widget<Semantics>(_access).properties.role,
      SemanticsRole.tab,
    );
    await showAccess(tester);
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
    final before = haptics();
    semanticAction(tester, _details)();
    await tester.pump();
    expect(haptics() - before, 1);
    expect(find.text('Ibrahim'), findsOneWidget);
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
      await showAccess(tester);
      expect(tester.widget<ZyraProfilesDots>(_dots).count, count);
      expect(tester.widget<ZyraProfilesDots>(_dots).index, 0);
      final physicalHaptics = haptics();
      await tester.tap(_dotTarget(0));
      await tester.pump();
      expect(haptics() - physicalHaptics, 1);
      expect(find.text('JOURNEY ACCESS'), findsNothing);
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
        final inviteHaptics = haptics();
        await tester.tap(_center);
        await tester.pump();
        expect(state().adds, 1);
        expect(haptics() - inviteHaptics, 1);
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
    await tester.tap(_center);
    await tester.pump();
    expect(state().adds, 1);
    expect(haptics() - before, 1);
  });

  testWidgets('Guardian selection returns to Details after roster reorder', (
    tester,
  ) async {
    await mount(tester);
    await showAccess(tester);
    state().removeGuardian(_hassanId);
    await tester.pump();
    expect(_card(_ibrahimId), findsOneWidget);
    expect(find.text('JOURNEY ACCESS'), findsNothing);
  });

  testWidgets(
    'A parent page reset after removing the second Guardian opens first Details',
    (tester) async {
      await mount(tester, initialPage: 1);
      await showAccess(tester);
      expect(_card(_ibrahimId), findsOneWidget);
      state().removeGuardian(_ibrahimId, resetPage: true);
      await tester.pump();
      expect(_card(_hassanId), findsOneWidget);
      expect(tester.widget<ZyraProfilesDots>(_dots).index, 0);
      expect(find.text('JOURNEY ACCESS'), findsNothing);
    },
  );

  testWidgets('A drag begun before an authority revision cannot change cards', (
    tester,
  ) async {
    await mount(tester);
    await showAccess(tester);
    final original = tester.widget<GestureDetector>(_card(_hassanId));
    original.onHorizontalDragDown!(DragDownDetails());
    original.onHorizontalDragUpdate!(
      DragUpdateDetails(
        globalPosition: Offset.zero,
        delta: const Offset(-40, 0),
      ),
    );
    state().changeContext();
    await tester.pump();
    final current = tester.widget<GestureDetector>(_card(_hassanId));
    final before = haptics();
    current.onHorizontalDragUpdate!(
      DragUpdateDetails(
        globalPosition: Offset.zero,
        delta: const Offset(-120, 0),
      ),
    );
    current.onHorizontalDragEnd!(DragEndDetails());
    await tester.pump();
    expect(state().pages, isEmpty);
    expect(haptics(), before);
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
    await next(tester);
    expect(state().pages, [1]);
    expect(find.text('JOURNEY ACCESS'), findsNothing);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('Guardian frame stays static at ${scale}x text', (
      tester,
    ) async {
      ZyraText.testReadingFontFamily = _geometryFont;
      addTearDown(() => ZyraText.testReadingFontFamily = null);
      await mount(
        tester,
        size: const Size(375, 667),
        topInset: 20,
        scale: scale,
        journeys: 3,
        stage: _wrappedStage,
      );
      final rect = tester.getRect(_card(_hassanId));
      final name = tester.getRect(find.text('Hassan'));
      await tester.dragFrom(
        Offset(rect.center.dx, rect.bottom - 45),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(_card(_hassanId)), rect);
      if (scale == 1) expect(tester.getRect(find.text('Hassan')), name);
      final pillHaptics = haptics();
      await showAccess(tester);
      expect(haptics() - pillHaptics, 1);
      expect(tester.getRect(_card(_hassanId)), rect);
      final scrollable = find.descendant(
        of: _card(_hassanId),
        matching: find.byType(Scrollable),
      );
      if (scale == 1) {
        expect(scrollable, findsNothing);
        final tile = _key('guardian-card-tile-$_journeyId');
        final tileRect = tester.getRect(tile);
        final stage = find.descendant(
          of: tile,
          matching: find.text(_wrappedStage),
        );
        final stageRect = tester.getRect(stage);
        expect(tileRect.height, closeTo(98, 1));
        expect(tester.widget<Text>(stage).style!.fontSize, 12);
        expect(
          stageRect.height,
          greaterThan(25),
          reason: 'Stage wraps in the measured tile',
        );
        for (final control in [_view(_hassanId), _chat(_hassanId)]) {
          final controlRect = tester.getRect(control);
          expect(controlRect.height, 34);
          expect(controlRect.top, greaterThan(stageRect.bottom));
          expect(controlRect.bottom, lessThanOrEqualTo(tileRect.bottom - 1));
        }
        await tester.dragFrom(
          Offset(rect.center.dx, rect.bottom - 45),
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(_card(_hassanId)), rect);
        expect(tester.getRect(tile), tileRect);
        expect(tester.getRect(stage), stageRect);
        expect(tester.takeException(), isNull);
        return;
      }
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0));
      expect(position.physics, isA<ClampingScrollPhysics>());
      await tester.dragFrom(
        Offset(rect.center.dx, rect.bottom - 45),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(tester.getRect(_card(_hassanId)), rect);
    });
  }

  testWidgets(
    'History physical and semantic taps change one existing bit without flip',
    (tester) async {
      await mount(tester);
      await tester.tap(_history(_hassanId));
      await tester.pump();
      expect(state().histories, [(guardian: _hassanId, enabled: true)]);
      expect(find.text('Hassan'), findsOneWidget);
      expect(find.text('JOURNEY ACCESS'), findsNothing);
      semanticAction(tester, _history(_hassanId))();
      await tester.pump();
      expect(state().histories.last, (guardian: _hassanId, enabled: false));
      expect(find.text('Journey access'), findsOneWidget);
    },
  );

  testWidgets('View switch and management buttons do not flip the card', (
    tester,
  ) async {
    await mount(tester, initialPage: 1);
    await showAccess(tester);
    await tester.tap(_view(_ibrahimId));
    await tester.pump();
    expect(state().permissions.single, (
      guardian: _ibrahimId,
      journey: _journeyId,
      view: false,
      chat: null,
    ));
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
    final confirm = await confirmation(tester);
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
    confirm();
    await tester.pumpAndSettle();
    expect(state().management, ['main:$_ibrahimId']);
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
  });

  testWidgets(
    'Seeker Basic keeps one Guardian and locked Add without paid Chat',
    (tester) async {
      await mount(tester, people: _people(mainBasic: true), basic: true);
      expect(find.text('Hassan'), findsOneWidget);
      await showAccess(tester);
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
      expect(find.text('Add more Guardians'), findsOneWidget);
      expect(find.text('View Seeker One'), findsOneWidget);
      expect(find.text('Omar'), findsNothing);
      expect(find.text('Ibrahim'), findsNothing);
      expect(_key('guardian-card-next'), findsNothing);
      await tester.tap(_center);
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
    await showAccess(tester);
    final view = physicalPermission(tester, _view(_ibrahimId));
    final semanticView = semanticAction(tester, _view(_ibrahimId));
    final confirm = await confirmation(tester);
    await next(tester);
    final count = haptics();
    view();
    semanticView();
    confirm();
    await tester.pump();
    expect(state().permissions, isEmpty);
    expect(state().management, isEmpty);
    expect(haptics(), count);
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
      await showAccess(tester);
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
      await showAccess(tester);
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
    await showAccess(tester);
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
      await showAccess(tester);
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
    await showAccess(tester);
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
  testWidgets(
    'LOCK14V5 small gold and queue71 normal-ink pager contrast are preserved',
    (tester) async {
      await mount(tester);
      expect(
        tester.widget<Text>(find.text('MAIN GUARDIAN')).style!.color,
        ZyraColors.goldText,
      );
      final label = tester.widget<Text>(find.text('Details'));
      expect(label.style!.color, ZyraColors.goldText);
      expect(label.style!.fontWeight, FontWeight.w500);
      final surface = tester
          .element(find.text('Journey access'))
          .findAncestorWidgetOfExactType<Material>()!;
      expect(surface.color, const Color(0xFFFBF7F0));
      final contrast =
          (surface.color!.computeLuminance() + .05) /
          (label.style!.color!.computeLuminance() + .05);
      expect(contrast, greaterThan(4.5));
      await showAccess(tester);
      expect(
        tester.widget<Text>(find.text('JOURNEY ACCESS')).style!.color,
        ZyraColors.goldText,
      );
      expect(
        tester.widget<Text>(find.text('Journey access')).style!.color,
        ZyraColors.goldText,
      );
      final views = tester.widgetList<Text>(find.text('View'));
      expect(views.single.style!.color, ZyraColors.goldText);
    },
  );
  testWidgets(
    'Invited card has a solid surface; only Add uses a dashed outline',
    (tester) async {
      await mount(tester);
      await next(tester);
      await next(tester);
      // Q17 / LOCK 19 k07 and k08: check the actual dashed border, including
      // its absence on the invitation card.
      final dashed = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.foregroundPainter is ZyraGuardianDashedBorder,
      );
      expect(
        find.descendant(of: _card('preview-invited-omar'), matching: dashed),
        findsNothing,
      );
      await next(tester);
      expect(
        find.descendant(of: _card('add'), matching: dashed),
        findsOneWidget,
      );
    },
  );
}
