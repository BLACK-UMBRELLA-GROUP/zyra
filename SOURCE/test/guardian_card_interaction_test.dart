import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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

const _hassanId = 'queue48-hassan';
const _ibrahimId = 'queue48-ibrahim';
const _journeyId = 'queue48-sara';
Finder _key(String id) => find.byKey(ValueKey(id));
Finder _card(String id) => _key('guardian-card-$id');
Finder get _next => _key('guardian-card-next');
Finder get _previous => _key('guardian-card-previous');
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
    this.familyState = ZyraGuardianFamilyState.noFamily,
  });

  final List<ZyraGuardianCardPerson> people;
  final bool basic;
  final int initialPage;
  final ZyraGuardianFamilyState familyState;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late List<ZyraGuardianCardPerson> people;
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
          ZyraGuardianCardJourney(
            id: _journeyId,
            attempt: 7,
            name: 'Sara',
            stage: 'Stage 4 of 8 · Faith & Values',
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
      initialPage: widget.initialPage,
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
    ZyraGuardianFamilyState familyState = ZyraGuardianFamilyState.noFamily,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: _Harness(
          key: host,
          people: people ?? _people(),
          basic: basic,
          initialPage: initialPage,
          familyState: familyState,
        ),
      ),
    );
    await tester.pump();
  }

  _HarnessState state() => host.currentState!;
  int haptics() =>
      calls.where((c) => c.method == 'HapticFeedback.vibrate').length;
  VoidCallback pageAction(WidgetTester tester, Finder finder) =>
      tester.widget<IconButton>(finder).onPressed!;
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

  Future<void> next(WidgetTester tester) async {
    await tester.tap(_next);
    await tester.pump();
  }

  Future<void> flip(WidgetTester tester) async {
    await tester.tap(_center);
    await tester.pump();
  }

  Future<void> dragAmount(
    WidgetTester tester,
    String id,
    double fraction,
  ) async {
    final detector = tester.widget<GestureDetector>(_card(id));
    final width = tester.getSize(_card(id)).width;
    detector.onHorizontalDragStart!(DragStartDetails());
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

  testWidgets('Pager ends are disabled at 35 percent opacity', (tester) async {
    await mount(tester);
    expect(tester.widget<IconButton>(_previous).onPressed, isNull);
    expect(
      tester
          .element(_previous)
          .findAncestorWidgetOfExactType<Opacity>()!
          .opacity,
      .35,
    );
    for (var i = 0; i < 3; i++) {
      await next(tester);
    }
    expect(tester.widget<IconButton>(_next).onPressed, isNull);
    expect(
      tester.element(_next).findAncestorWidgetOfExactType<Opacity>()!.opacity,
      .35,
    );
    expect(tester.widget<IconButton>(_previous).onPressed, isNotNull);
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

  testWidgets('Physical swipe moves and card background tap flips', (
    tester,
  ) async {
    await mount(tester);
    final card = tester.getRect(_card(_hassanId));
    await tester.dragFrom(
      Offset(card.right - 30, card.top + 25),
      Offset(-card.width * .6, 0),
    );
    await tester.pump();
    expect(find.text('Ibrahim'), findsOneWidget);
    await tester.tapAt(
      tester.getTopLeft(_card(_ibrahimId)) + const Offset(12, 12),
    );
    await tester.pump();
    expect(find.text('JOURNEY ACCESS'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    await flip(tester);
    expect(find.text('Ibrahim'), findsOneWidget);
    expect(find.text('Journey access'), findsOneWidget);
  });

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
    await flip(tester);
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
      await flip(tester);
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
      expect(tester.widget<IconButton>(_next).onPressed, isNull);
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
      final oldPage = pageAction(tester, _next);
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
      final oldPage = pageAction(tester, _next);
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
    await flip(tester);
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
      await flip(tester);
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
      await flip(tester);
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
    await flip(tester);
    final view = physicalPermission(tester, _view(_ibrahimId));
    final oldPage = pageAction(tester, _next);
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
      final oldPage = pageAction(tester, _next);
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
      await flip(tester);
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
    await flip(tester);
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
      final oldPage = pageAction(tester, _next),
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
      final oldPage = pageAction(tester, _next);
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
      final label = tester.widget<Text>(find.text('Journey access'));
      expect(label.style!.color, const Color(0xFF2B2420));
      final surface = tester
          .element(find.text('Journey access'))
          .findAncestorWidgetOfExactType<Material>()!;
      expect(surface.color, const Color(0xFFFBF7F0));
      final contrast =
          (surface.color!.computeLuminance() + .05) /
          (label.style!.color!.computeLuminance() + .05);
      expect(contrast, greaterThan(4.5));
      await flip(tester);
      expect(
        tester.widget<Text>(find.text('JOURNEY ACCESS')).style!.color,
        ZyraColors.goldText,
      );
      expect(
        tester.widget<Text>(find.text('Details')).style!.color,
        ZyraColors.espresso,
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
      final invited = find
          .descendant(
            of: _card('preview-invited-omar'),
            matching: find.byType(CustomPaint),
          )
          .first;
      expect(tester.widget<CustomPaint>(invited).foregroundPainter, isNull);
      await next(tester);
      final add = find
          .descendant(of: _card('add'), matching: find.byType(CustomPaint))
          .first;
      expect(tester.widget<CustomPaint>(add).foregroundPainter, isNotNull);
    },
  );
}
