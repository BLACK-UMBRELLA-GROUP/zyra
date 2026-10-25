import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_subscription_wallet_draft.dart';
import 'package:zyra/dev/zyra_subscription_wallet_preview.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Subscription samples must stay local.');
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));

class _Harness extends StatefulWidget {
  const _Harness({
    required this.draft,
    this.switchOnly = true,
    this.currentRole = ZyraWalletRole.seeker,
    this.canAct,
  });

  final ZyraSubscriptionWalletDraft draft;
  final bool switchOnly;
  final ZyraWalletRole currentRole;
  final bool Function()? canAct;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late ZyraSubscriptionWalletDraft draft = widget.draft;
  int changes = 0;
  int backs = 0;
  final switches = <ZyraWalletRole>[];
  final setups = <ZyraWalletRole>[];
  final memberships = <ZyraWalletRole>[];

  void replace(ZyraSubscriptionWalletDraft next) =>
      setState(() => draft = next);

  void changed(ZyraSubscriptionWalletDraft next) => setState(() {
    changes++;
    draft = next;
  });

  @override
  Widget build(BuildContext context) => widget.switchOnly
      ? ZyraSubscriptionSwitchPreview(
          draft: draft,
          currentRole: widget.currentRole,
          onChanged: changed,
          onSwitch: switches.add,
          onSetup: setups.add,
          onMembership: memberships.add,
          onBack: () => backs++,
          canAct: widget.canAct,
        )
      : ZyraSubscriptionWalletPreview(
          draft: draft,
          currentRole: widget.currentRole,
          onChanged: changed,
          onSwitch: switches.add,
          onSetup: setups.add,
          onMembership: memberships.add,
          onBack: () => backs++,
          canAct: widget.canAct,
        );
}

Widget _app(
  Widget child, {
  bool largeText = false,
  bool reducedMotion = true,
}) => MaterialApp(
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(largeText ? 2 : 1),
      disableAnimations: reducedMotion,
    ),
    child: child!,
  ),
  home: Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
      child: child,
    ),
  ),
);

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

Future<void> _familyPage(WidgetTester tester, int page) async {
  if (_key('wallet_family_pages').evaluate().isEmpty) {
    await _tap(tester, 'wallet_group_family');
  }
  int current() =>
      int.parse(
        tester
            .widget<Text>(_key('wallet_family_position'))
            .data!
            .split(' ')
            .first,
      ) -
      1;
  while (current() < page) {
    await _tap(tester, 'wallet_family_next');
  }
  while (current() > page) {
    await _tap(tester, 'wallet_family_previous');
  }
}

_HarnessState _state(WidgetTester tester) =>
    tester.state<_HarnessState>(find.byType(_Harness));

BoxDecoration _cardDecoration(WidgetTester tester, String key) =>
    tester.widget<Container>(_key(key)).decoration! as BoxDecoration;

void main() {
  late HttpOverrides? previousHttp;
  late _NoNetwork network;

  setUp(() {
    ZyraText.useTestFontStubs = true;
    previousHttp = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousHttp;
    ZyraText.useTestFontStubs = false;
  });

  group('detached subscription draft', () {
    test('coverage and readiness are independent for both roles', () {
      for (final role in ZyraWalletRole.values) {
        for (final coverage in [
          ZyraWalletCoverage.individualOne,
          ZyraWalletCoverage.assignedFamily,
          ZyraWalletCoverage.basic,
        ]) {
          final draft = ZyraSubscriptionWalletDraft.sample().withRole(
            role,
            coverage: coverage,
            readiness: ZyraWalletReadiness.ready,
          );
          expect(draft.nextStep(role), ZyraWalletNextStep.switchProfile);
          expect(
            draft
                .withRole(role, readiness: ZyraWalletReadiness.missing)
                .nextStep(role),
            ZyraWalletNextStep.finishSetup,
          );
          expect(
            draft
                .withRole(role, readiness: ZyraWalletReadiness.unfinished)
                .nextStep(role),
            ZyraWalletNextStep.finishSetup,
          );
        }
      }
    });

    test('none uses a known spare before offering membership', () {
      final sample = ZyraSubscriptionWalletDraft.sample().withRole(
        ZyraWalletRole.guardian,
        coverage: ZyraWalletCoverage.none,
      );
      expect(
        sample.nextStep(ZyraWalletRole.guardian),
        ZyraWalletNextStep.usePlace,
      );
      final noPlaces = sample.copyWith(places: []);
      expect(
        noPlaces.nextStep(ZyraWalletRole.guardian),
        ZyraWalletNextStep.chooseMembership,
      );
      expect(
        noPlaces
            .withRole(
              ZyraWalletRole.guardian,
              readiness: ZyraWalletReadiness.missing,
            )
            .nextStep(ZyraWalletRole.guardian),
        ZyraWalletNextStep.startSetup,
      );
    });

    test('unreadable status or inventory never becomes an unpaid account', () {
      final sample = ZyraSubscriptionWalletDraft.sample();
      final unknownCoverage = sample.withRole(
        ZyraWalletRole.guardian,
        coverage: ZyraWalletCoverage.unavailable,
      );
      final unknownReadiness = sample.withRole(
        ZyraWalletRole.guardian,
        readiness: ZyraWalletReadiness.unknown,
      );
      for (final draft in [unknownCoverage, unknownReadiness]) {
        expect(
          draft.nextStep(ZyraWalletRole.guardian),
          ZyraWalletNextStep.unavailable,
        );
        expect(
          identical(draft.useAvailablePlace(ZyraWalletRole.guardian), draft),
          isTrue,
        );
      }
      final inventoryError = sample
          .withRole(ZyraWalletRole.guardian, coverage: ZyraWalletCoverage.none)
          .copyWith(inventoryAvailable: false);
      expect(inventoryError.availableFor(ZyraWalletRole.guardian), isEmpty);
      expect(
        inventoryError.nextStep(ZyraWalletRole.guardian),
        ZyraWalletNextStep.unavailable,
      );
      expect(
        identical(
          inventoryError.assignFictionalRecipient('sample-spare-guardian'),
          inventoryError,
        ),
        isTrue,
      );
    });

    test('using a place is role-specific and does not complete setup', () {
      final before = ZyraSubscriptionWalletDraft.sample().withRole(
        ZyraWalletRole.guardian,
        readiness: ZyraWalletReadiness.missing,
        coverage: ZyraWalletCoverage.none,
      );
      expect(
        identical(
          before.useAvailablePlace(
            ZyraWalletRole.guardian,
            placeId: 'sample-spare-seeker',
          ),
          before,
        ),
        isTrue,
      );
      final after = before.useAvailablePlace(ZyraWalletRole.guardian);
      expect(after.ownerId, before.ownerId);
      expect(after.revision, before.revision + 1);
      expect(after.guardian.coverage, ZyraWalletCoverage.assignedFamily);
      expect(after.guardian.readiness, ZyraWalletReadiness.missing);
      expect(
        after.nextStep(ZyraWalletRole.guardian),
        ZyraWalletNextStep.finishSetup,
      );
      expect(after.availableFor(ZyraWalletRole.guardian), isEmpty);
      expect(before.availableFor(ZyraWalletRole.guardian), hasLength(1));
      expect(after.seeker, same(before.seeker));
      expect(
        identical(after.useAvailablePlace(ZyraWalletRole.guardian), after),
        isTrue,
      );
    });

    test(
      'assignment is a pending fictional invitation, never an access grant',
      () {
        final before = ZyraSubscriptionWalletDraft.sample();
        final after = before.assignFictionalRecipient('sample-spare-guardian');
        final place = after.places.singleWhere(
          (place) => place.id == 'sample-spare-guardian',
        );
        expect(place.state, ZyraWalletPlaceState.invitationPending);
        expect(place.recipient, 'Omar');
        expect(after.guardian, same(before.guardian));
        expect(after.seeker, same(before.seeker));
        expect(after.availableFor(ZyraWalletRole.guardian), isEmpty);
        for (final id in [
          'sample-yusuf-pending',
          'sample-sara-funded',
          'sample-amira',
          'sample-self-seeker',
        ]) {
          expect(
            identical(before.assignFictionalRecipient(id), before),
            isTrue,
          );
        }
      },
    );

    test(
      'defensive inventory snapshots cannot be mutated or share caller lists',
      () {
        final source = <ZyraWalletPlace>[];
        final sample = ZyraSubscriptionWalletDraft.sample();
        final draft = sample.copyWith(places: source);
        source.add(sample.places.first);
        expect(draft.places, isEmpty);
        expect(
          () => draft.places.add(sample.places.first),
          throwsUnsupportedError,
        );
        expect(
          () => sample.availableFor(ZyraWalletRole.guardian).clear(),
          throwsUnsupportedError,
        );
        expect(
          () => sample.copyWith(
            places: [sample.places.first, sample.places.first],
          ),
          throwsArgumentError,
        );
      },
    );
  });

  testWidgets('covered target switches without membership or allocation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_Harness(draft: ZyraSubscriptionWalletDraft.sample())),
    );
    expect(find.text('Switch profile'), findsOneWidget);
    expect(find.text('Guardian One · Individual'), findsOneWidget);
    expect(
      find.textContaining('No additional membership purchase'),
      findsOneWidget,
    );
    await _tap(tester, 'wallet_primary_guardian');
    final state = _state(tester);
    expect(state.switches, [ZyraWalletRole.guardian]);
    expect(state.memberships, isEmpty);
    expect(state.changes, 0);
    expect(state.setups, isEmpty);
  });

  testWidgets('covered missing profile finishes setup without a second sale', (
    tester,
  ) async {
    final draft = ZyraSubscriptionWalletDraft.sample().withRole(
      ZyraWalletRole.seeker,
      readiness: ZyraWalletReadiness.missing,
    );
    await tester.pumpWidget(
      _app(_Harness(draft: draft, currentRole: ZyraWalletRole.guardian)),
    );
    expect(find.text('Seeker One · ZYRA Family'), findsOneWidget);
    expect(find.text('Finish Seeker setup'), findsOneWidget);
    await _tap(tester, 'wallet_primary_seeker');
    expect(_state(tester).setups, [ZyraWalletRole.seeker]);
    expect(_state(tester).memberships, isEmpty);
    expect(_state(tester).switches, isEmpty);
  });

  testWidgets('spare place needs confirmation and setup stays separate', (
    tester,
  ) async {
    final draft = ZyraSubscriptionWalletDraft.sample().withRole(
      ZyraWalletRole.guardian,
      readiness: ZyraWalletReadiness.missing,
      coverage: ZyraWalletCoverage.none,
    );
    await tester.pumpWidget(_app(_Harness(draft: draft)));
    await _tap(tester, 'wallet_primary_guardian');
    expect(_state(tester).changes, 0);
    expect(find.text('Use this Guardian place?'), findsOneWidget);
    final staleConfirm = tester
        .widget<OutlinedButton>(_key('wallet_confirm'))
        .onPressed!;
    await _tap(tester, 'wallet_confirm');
    expect(_state(tester).changes, 1);
    expect(
      _state(tester).draft.guardian.coverage,
      ZyraWalletCoverage.assignedFamily,
    );
    expect(find.text('Finish Guardian setup'), findsOneWidget);
    staleConfirm();
    expect(_state(tester).changes, 1);
    await _tap(tester, 'wallet_primary_guardian');
    expect(_state(tester).setups, [ZyraWalletRole.guardian]);
    expect(_state(tester).memberships, isEmpty);
  });

  testWidgets('confirmed no coverage and no spare opens membership only', (
    tester,
  ) async {
    final draft = ZyraSubscriptionWalletDraft.sample()
        .withRole(ZyraWalletRole.guardian, coverage: ZyraWalletCoverage.none)
        .copyWith(places: []);
    await tester.pumpWidget(_app(_Harness(draft: draft)));
    expect(find.text('Choose Guardian membership'), findsOneWidget);
    await _tap(tester, 'wallet_primary_guardian');
    expect(_state(tester).memberships, [ZyraWalletRole.guardian]);
    expect(_state(tester).switches, isEmpty);
    expect(_state(tester).changes, 0);
  });

  testWidgets('unavailable cannot switch, allocate or upsell', (tester) async {
    final draft = ZyraSubscriptionWalletDraft.sample().withRole(
      ZyraWalletRole.guardian,
      coverage: ZyraWalletCoverage.unavailable,
    );
    await tester.pumpWidget(_app(_Harness(draft: draft)));
    expect(find.text('Coverage unavailable'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(_key('wallet_primary_guardian')).onPressed,
      isNull,
    );
    expect(find.text('Choose Guardian membership'), findsNothing);
    expect(find.text('Use a Guardian place for me'), findsNothing);
  });

  testWidgets('wallet shows own, spare, assigned, pending and funded places', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _Harness(
          draft: ZyraSubscriptionWalletDraft.sample(),
          switchOnly: false,
        ),
      ),
    );
    expect(find.text('Your subscriptions'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(_key('wallet_primary_seeker')).onPressed,
      isNull,
    );
    final places = _state(tester).draft.places;
    for (var page = 0; page < places.length; page++) {
      await _familyPage(tester, page);
      expect(find.text(places[page].statusLabel), findsOneWidget);
      if (places[page].state != ZyraWalletPlaceState.available) {
        expect(_key('wallet_assign_${places[page].id}'), findsNothing);
        expect(_key('wallet_use_${places[page].id}'), findsNothing);
      }
    }
    await _familyPage(tester, 2);
    await _tap(tester, 'wallet_assign_sample-spare-guardian');
    expect(find.textContaining('Omar'), findsOneWidget);
    expect(_state(tester).changes, 0);
    await _tap(tester, 'wallet_confirm');
    expect(_state(tester).changes, 1);
    expect(find.text('Invitation pending · Omar'), findsOneWidget);
    expect(_key('wallet_assign_sample-spare-guardian'), findsNothing);
    expect(_state(tester).memberships, isEmpty);
  });

  testWidgets('cancel leaves sample inventory unchanged', (tester) async {
    await tester.pumpWidget(
      _app(
        _Harness(
          draft: ZyraSubscriptionWalletDraft.sample(),
          switchOnly: false,
        ),
      ),
    );
    await _familyPage(tester, 1);
    await _tap(tester, 'wallet_assign_sample-spare-seeker');
    await _tap(tester, 'wallet_cancel');
    expect(_state(tester).changes, 0);
    expect(
      _state(tester).draft.availableFor(ZyraWalletRole.seeker),
      hasLength(1),
    );
    expect(_key('wallet_confirmation'), findsNothing);
  });

  testWidgets(
    'paged scrolled place actions reveal confirmation beside the tapped place',
    (tester) async {
      tester.view.physicalSize = const Size(393, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final forSelf in [true, false]) {
        await tester.pumpWidget(const SizedBox.shrink());
        final draft = ZyraSubscriptionWalletDraft.sample().withRole(
          ZyraWalletRole.guardian,
          coverage: ZyraWalletCoverage.none,
        );
        await tester.pumpWidget(
          _app(_Harness(draft: draft, switchOnly: false), largeText: true),
        );
        await _familyPage(tester, 2);
        final action = _key(
          forSelf
              ? 'wallet_use_sample-spare-guardian'
              : 'wallet_assign_sample-spare-guardian',
        );
        await Scrollable.ensureVisible(tester.element(action), alignment: 0.4);
        await tester.pumpAndSettle();
        final scrollable = find
            .descendant(
              of: _key('wallet_scroll'),
              matching: find.byType(Scrollable),
            )
            .first;
        expect(
          tester.state<ScrollableState>(scrollable).position.pixels,
          greaterThan(0),
        );
        await tester.tap(action);
        await tester.pumpAndSettle();

        // No ensureVisible/scroll after the tap: the response itself must be
        // visible at this nonzero offset, not inserted up by the page heading.
        final heading = find.text(
          forSelf ? 'Use this Guardian place?' : 'Assign this Guardian place?',
        );
        final rect = tester.getRect(heading);
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(700));
        expect(
          find.descendant(
            of: _key('wallet_place_sample-spare-guardian'),
            matching: _key('wallet_confirmation'),
          ),
          findsOneWidget,
        );
        expect(_state(tester).changes, 0);
      }
    },
  );

  testWidgets('role place action keeps confirmation inside its role card', (
    tester,
  ) async {
    final draft = ZyraSubscriptionWalletDraft.sample().withRole(
      ZyraWalletRole.guardian,
      coverage: ZyraWalletCoverage.none,
    );
    await tester.pumpWidget(_app(_Harness(draft: draft)));
    await _tap(tester, 'wallet_primary_guardian');
    expect(
      find.descendant(
        of: _key('wallet_role_guardian'),
        matching: _key('wallet_confirmation'),
      ),
      findsOneWidget,
    );
    expect(_key('wallet_primary_guardian'), findsNothing);
    await _tap(tester, 'wallet_cancel');
    expect(_key('wallet_primary_guardian'), findsOneWidget);
  });

  testWidgets('revocation without rebuild denies captured actions', (
    tester,
  ) async {
    var allowed = true;
    await tester.pumpWidget(
      _app(
        _Harness(
          draft: ZyraSubscriptionWalletDraft.sample(),
          canAct: () => allowed,
        ),
      ),
    );
    final action = tester
        .widget<OutlinedButton>(_key('wallet_primary_guardian'))
        .onPressed!;
    final back = tester.widget<TextButton>(_key('wallet_back')).onPressed!;
    allowed = false;
    action();
    back();
    expect(_state(tester).switches, isEmpty);
    expect(_state(tester).backs, 0);
  });

  testWidgets('replacement and owner changes invalidate old callbacks', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_Harness(draft: ZyraSubscriptionWalletDraft.sample())),
    );
    final state = _state(tester);
    final old = tester
        .widget<OutlinedButton>(_key('wallet_primary_guardian'))
        .onPressed!;
    state.replace(
      ZyraSubscriptionWalletDraft.sample(ownerId: 'other-sample-owner'),
    );
    await tester.pumpAndSettle();
    old();
    expect(state.switches, isEmpty);
    final current = tester
        .widget<OutlinedButton>(_key('wallet_primary_guardian'))
        .onPressed!;
    await tester.pumpWidget(const SizedBox.shrink());
    current();
    expect(state.switches, isEmpty);
  });

  testWidgets('pending confirmation is revoked by a changed draft', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _Harness(
          draft: ZyraSubscriptionWalletDraft.sample(),
          switchOnly: false,
        ),
      ),
    );
    await _familyPage(tester, 2);
    await _tap(tester, 'wallet_assign_sample-spare-guardian');
    final old = tester
        .widget<OutlinedButton>(_key('wallet_confirm'))
        .onPressed!;
    _state(
      tester,
    ).replace(_state(tester).draft.copyWith(inventoryAvailable: false));
    await tester.pumpAndSettle();
    old();
    expect(_state(tester).changes, 0);
    expect(_key('wallet_confirmation'), findsNothing);
  });

  testWidgets('320px and 200 percent text remain scrollable without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        _Harness(
          draft: ZyraSubscriptionWalletDraft.sample(),
          switchOnly: false,
        ),
        largeText: true,
      ),
    );
    await _familyPage(tester, 2);
    await _tap(tester, 'wallet_assign_sample-spare-guardian');
    expect(tester.takeException(), isNull);
    await _tap(tester, 'wallet_confirm');
    expect(tester.takeException(), isNull);
    expect(find.text('Invitation pending · Omar'), findsOneWidget);
  });

  testWidgets(
    'halo wallet omits sample labels but retains unavailable coverage information',
    (tester) async {
      await tester.pumpWidget(
        _app(
          _Harness(
            draft: ZyraSubscriptionWalletDraft.sample(),
            switchOnly: false,
          ),
        ),
      );
      expect(
        find.text('Your own memberships and ZYRA Family places, together.'),
        findsNothing,
      );
      expect(
        find.text(
          'Local testing · sample subscriptions and places. No purchase, account or invitation is changed.',
        ),
        findsNothing,
      );
      expect(find.text('Your profiles. Your family places.'), findsNothing);
      expect(find.text('Sample'), findsNothing);
      expect(find.textContaining('(sample)'), findsNothing);
      expect(tester.getSize(_key('wallet_halo_seeker')), const Size(80, 80));
      await _tap(tester, 'wallet_info');
      expect(_key('wallet_info_dialog'), findsOneWidget);
      expect(
        find.textContaining('Real paid subscriptions are not verified here.'),
        findsOneWidget,
      );
      expect(
        find.text('No purchase, account or invitation is changed here.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Invitations need the recipient’s agreement'),
        findsOneWidget,
      );
      expect(_state(tester).changes, 0);
      await _tap(tester, 'wallet_info_close');
    },
  );

  for (final palette in const [
    ZyraDevPalette.midnightPlum,
    ZyraDevPalette.midnightBlue,
    ZyraDevPalette.paperWhite,
  ]) {
    testWidgets(
      'wallet cards keep shared quiet fill and coverage outlines for ${palette.name}',
      (tester) async {
        final previousPalette = ZyraColors.devPalette;
        final previousSurface = ZyraColors.appSurfaceStyle;
        addTearDown(() {
          ZyraColors.selectDevPalette(previousPalette);
          ZyraColors.selectAppSurfaceStyle(previousSurface);
        });
        final draft = ZyraSubscriptionWalletDraft.sample().withRole(
          ZyraWalletRole.guardian,
          coverage: ZyraWalletCoverage.none,
        );
        for (final surface in ZyraAppSurfaceStyle.values) {
          await tester.pumpWidget(const SizedBox.shrink());
          ZyraColors.selectDevPalette(palette);
          ZyraColors.selectAppSurfaceStyle(surface);
          await tester.pumpWidget(
            _app(_Harness(draft: draft, switchOnly: false)),
          );
          await tester.pumpAndSettle();
          final state = _state(tester);
          final covered = _cardDecoration(tester, 'wallet_role_seeker');
          expect(covered.color, ZyraColors.surfaceFill);
          expect(
            (covered.border! as Border).top.color,
            ZyraColors.journeyGold.withValues(alpha: .5),
          );
          expect(
            tester
                .widget<OutlinedButton>(_key('wallet_primary_seeker'))
                .onPressed,
            isNull,
          );

          await _tap(tester, 'wallet_profiles_next');
          expect(find.text('2 of 2 profiles'), findsOneWidget);
          final uncovered = _cardDecoration(tester, 'wallet_role_guardian');
          expect(uncovered.color, ZyraColors.surfaceFill);
          expect(
            (uncovered.border! as Border).top.color,
            ZyraColors.surfaceBorder,
          );
          expect(find.text('Use a Guardian place for me'), findsOneWidget);
          expect(
            tester
                .widget<OutlinedButton>(_key('wallet_primary_guardian'))
                .onPressed,
            isNotNull,
          );

          await _familyPage(tester, 2);
          expect(find.text('3 of 6 places'), findsOneWidget);
          final place = _cardDecoration(
            tester,
            'wallet_place_sample-spare-guardian',
          );
          expect(place.color, ZyraColors.surfaceFill);
          expect((place.border! as Border).top.color, ZyraColors.surfaceBorder);
          await _tap(tester, 'wallet_assign_sample-spare-guardian');
          final confirmation = _cardDecoration(tester, 'wallet_confirmation');
          expect(confirmation.color, ZyraColors.surfaceFill);
          expect(
            (confirmation.border! as Border).top.color,
            ZyraColors.journeyGold.withValues(alpha: .5),
          );
          expect(find.text('Assign this Guardian place?'), findsOneWidget);
          expect(state.changes, 0);
          expect(state.draft, same(draft));
          expect(state.switches, isEmpty);
          expect(state.setups, isEmpty);
          expect(state.memberships, isEmpty);
          await _tap(tester, 'wallet_cancel');
          expect(_key('wallet_confirmation'), findsNothing);
          expect(_key('wallet_assign_sample-spare-guardian'), findsOneWidget);
          expect(state.changes, 0);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets(
    'touch paging is independent within Profiles and six Family places',
    (tester) async {
      await tester.pumpWidget(
        _app(
          _Harness(
            draft: ZyraSubscriptionWalletDraft.sample(),
            switchOnly: false,
          ),
        ),
      );
      await tester.drag(_key('wallet_profiles_pages'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 of 2 profiles'), findsOneWidget);
      expect(_key('wallet_role_guardian'), findsOneWidget);
      await _familyPage(tester, 3);
      expect(find.text('4 of 6 places'), findsOneWidget);
      await tester.drag(_key('wallet_family_pages'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('5 of 6 places'), findsOneWidget);
      await _tap(tester, 'wallet_group_profiles');
      expect(find.text('2 of 2 profiles'), findsOneWidget);
      await tester.drag(_key('wallet_profiles_pages'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 of 2 profiles'), findsOneWidget);
      expect(_key('wallet_family_pages'), findsNothing);
      await _tap(tester, 'wallet_group_family');
      expect(find.text('5 of 6 places'), findsOneWidget);
      expect(_state(tester).changes, 0);
      expect(_state(tester).switches, isEmpty);
      expect(_state(tester).memberships, isEmpty);
    },
  );

  testWidgets(
    'paging and changing section clear adjacent confirmation and old intent',
    (tester) async {
      await tester.pumpWidget(
        _app(
          _Harness(
            draft: ZyraSubscriptionWalletDraft.sample(),
            switchOnly: false,
          ),
        ),
      );
      for (final changeSection in [false, true]) {
        await _familyPage(tester, 2);
        await _tap(tester, 'wallet_assign_sample-spare-guardian');
        final retained = tester
            .widget<OutlinedButton>(_key('wallet_confirm'))
            .onPressed!;
        await _tap(
          tester,
          changeSection ? 'wallet_group_profiles' : 'wallet_family_next',
        );
        expect(_key('wallet_confirmation'), findsNothing);
        retained();
        expect(_state(tester).changes, 0);
        await _familyPage(tester, 2);
        expect(_key('wallet_confirmation'), findsNothing);
        expect(
          _state(tester).draft.availableFor(ZyraWalletRole.guardian),
          hasLength(1),
        );
      }
    },
  );

  for (final forSelf in [false, true]) {
    testWidgets(
      'focus reveal retains the adjacent ${forSelf ? 'use' : 'assignment'} confirmation',
      (tester) async {
        final draft = ZyraSubscriptionWalletDraft.sample().withRole(
          ZyraWalletRole.guardian,
          coverage: ZyraWalletCoverage.none,
        );
        await tester.pumpWidget(
          _app(_Harness(draft: draft, switchOnly: false), largeText: true),
        );
        await _familyPage(tester, 2);
        await _tap(
          tester,
          forSelf
              ? 'wallet_use_sample-spare-guardian'
              : 'wallet_assign_sample-spare-guardian',
        );
        expect(_key('wallet_confirmation'), findsOneWidget);
        await tester.ensureVisible(_key('wallet_confirm'));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: _key('wallet_place_sample-spare-guardian'),
            matching: _key('wallet_confirmation'),
          ),
          findsOneWidget,
        );
        expect(_key('wallet_confirm').hitTestable(), findsOneWidget);
        expect(_key('wallet_cancel'), findsOneWidget);
        expect(
          tester.widget<PageView>(_key('wallet_family_pages')).controller!.page,
          2,
        );
        expect(_state(tester).changes, 0);
        await _tap(tester, 'wallet_confirm');
        expect(_state(tester).changes, 1);
        expect(
          _state(tester).draft.places[2].state,
          forSelf
              ? ZyraWalletPlaceState.assignedToSelf
              : ZyraWalletPlaceState.invitationPending,
        );
        expect(_state(tester).switches, isEmpty);
        expect(_state(tester).memberships, isEmpty);
      },
    );
  }

  testWidgets(
    'new paging and information callbacks are stale after section, owner or revocation',
    (tester) async {
      var allowed = true;
      await tester.pumpWidget(
        _app(
          _Harness(
            draft: ZyraSubscriptionWalletDraft.sample(),
            switchOnly: false,
            canAct: () => allowed,
          ),
        ),
      );
      final oldNext = tester
          .widget<IconButton>(_key('wallet_profiles_next'))
          .onPressed!;
      final oldInfo = tester.widget<IconButton>(_key('wallet_info')).onPressed!;
      await _familyPage(tester, 0);
      oldNext();
      oldInfo();
      await tester.pumpAndSettle();
      expect(find.text('1 of 6 places'), findsOneWidget);
      expect(_key('wallet_info_dialog'), findsNothing);
      final next = tester
          .widget<IconButton>(_key('wallet_family_next'))
          .onPressed!;
      final info = tester.widget<IconButton>(_key('wallet_info')).onPressed!;
      allowed = false;
      next();
      info();
      await tester.pumpAndSettle();
      expect(find.text('1 of 6 places'), findsOneWidget);
      expect(_key('wallet_info_dialog'), findsNothing);
      allowed = true;
      _state(tester).replace(
        ZyraSubscriptionWalletDraft.sample(ownerId: 'new-sample-owner'),
      );
      await tester.pumpAndSettle();
      next();
      info();
      expect(_key('wallet_info_dialog'), findsNothing);
      expect(find.text('1 of 2 profiles'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      next();
      info();
      oldNext();
      oldInfo();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unknown inventory does not become available places in the halo layout',
    (tester) async {
      await tester.pumpWidget(
        _app(
          _Harness(
            draft: ZyraSubscriptionWalletDraft.sample().copyWith(
              inventoryAvailable: false,
            ),
            switchOnly: false,
          ),
        ),
      );
      await _tap(tester, 'wallet_group_family');
      expect(_key('wallet_places_empty'), findsOneWidget);
      expect(tester.widget(_key('wallet_places_empty')), isA<Container>());
      expect(
        find.descendant(
          of: _key('wallet_places_empty'),
          matching: find.byType(ZyraEmptyState),
        ),
        findsNothing,
      );
      expect(
        find.textContaining('No places are assumed to be spare'),
        findsOneWidget,
      );
      expect(find.text('Sample'), findsNothing);
      expect(_key('wallet_availability'), findsNothing);
      expect(_key('wallet_family_pages'), findsNothing);
      expect(_key('wallet_assign_sample-spare-guardian'), findsNothing);
    },
  );

  for (final enlarged in [false, true]) {
    testWidgets(
      'confirmed zero Family places is a plain empty state at ${enlarged ? 'compact200' : 'normal'} size',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = enlarged
            ? const Size(320, 568)
            : const Size(393, 852);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          _app(
            _Harness(
              draft: ZyraSubscriptionWalletDraft.sample().copyWith(
                places: const [],
              ),
              switchOnly: false,
            ),
            largeText: enlarged,
          ),
        );
        await _tap(tester, 'wallet_group_family');
        final empty = _key('wallet_places_empty');
        expect(tester.widget(empty), isA<ZyraEmptyState>());
        expect(
          find.descendant(of: empty, matching: find.byType(Container)),
          findsNothing,
        );
        final icon = tester.widget<Icon>(
          find.descendant(of: empty, matching: find.byType(Icon)),
        );
        expect(icon.size, 30);
        expect(icon.color, ZyraColors.ink(.35));
        final message = find.text(
          'No Family places. Your individual memberships stay separate.',
        );
        await tester.ensureVisible(message);
        await tester.pumpAndSettle();
        expect(message.hitTestable(), findsOneWidget);
        expect(find.textContaining('could not be checked'), findsNothing);
        expect(_key('wallet_family_pages'), findsNothing);
        expect(_key('wallet_availability'), findsNothing);
        final scroll = tester
            .state<ScrollableState>(
              find.descendant(
                of: _key('wallet_scroll'),
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Scrollable &&
                      (widget.axisDirection == AxisDirection.down ||
                          widget.axisDirection == AxisDirection.up),
                ),
              ),
            )
            .position;
        if (!enlarged) {
          final group = find.descendant(
            of: empty,
            matching: find.byType(Column),
          );
          expect(
            tester.getRect(group).center.dy,
            closeTo(tester.getRect(empty).center.dy, .01),
          );
          expect(scroll.maxScrollExtent, 0);
        } else {
          expect(scroll.maxScrollExtent, greaterThan(0));
          final messageContext = tester.element(message);
          expect(MediaQuery.textScalerOf(messageContext).scale(13.5), 27);
          await tester.drag(_key('wallet_scroll'), const Offset(0, -120));
          await tester.pumpAndSettle();
          expect(scroll.pixels, greaterThan(0));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  if (const String.fromEnvironment(
    'ZYRA_WALLET_EMPTY_CAPTURE_DIR',
  ).isNotEmpty) {
    testWidgets('optional real-font confirmed-empty Wallet evidence', (
      tester,
    ) async {
      const directory = String.fromEnvironment('ZYRA_WALLET_EMPTY_CAPTURE_DIR');
      expect(
        directory,
        '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SYSTEM/RESOURCES/REVIEWS/OA305_QUIET_EMPTY_2026_10_22.LWSWe3/FRAMES_WALLET',
      );
      const family = 'PoppinsWalletEmptyEvidence';
      final font = FontLoader(family);
      for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
        font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
      }
      await font.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      final oldReading = ZyraText.testReadingFontFamily;
      ZyraText.testReadingFontFamily = family;
      addTearDown(() => ZyraText.testReadingFontFamily = oldReading);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      for (final enlarged in [false, true]) {
        tester.view.physicalSize = enlarged
            ? const Size(320, 568)
            : const Size(393, 852);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: _app(
              _Harness(
                draft: ZyraSubscriptionWalletDraft.sample().copyWith(
                  places: const [],
                ),
                switchOnly: false,
              ),
              largeText: enlarged,
            ),
          ),
        );
        await _tap(tester, 'wallet_group_family');
        expect(_key('wallet_places_empty'), findsOneWidget);
        final message = find.text(
          'No Family places. Your individual memberships stay separate.',
        );
        await tester.ensureVisible(message);
        await tester.pumpAndSettle();
        expect(message.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        final image = await tester.runAsync(
          () => boundary.toImage(pixelRatio: 1),
        );
        final bytes = await tester.runAsync(
          () => image!.toByteData(format: ui.ImageByteFormat.png),
        );
        image!.dispose();
        expect(bytes, isNotNull);
        await tester.runAsync(() async {
          final file = File(
            '$directory/known-empty-${enlarged ? 'compact200' : 'normal'}.png',
          );
          await file.parent.create(recursive: true);
          expect(await file.exists(), isFalse);
          await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
        });
      }
    });
  }

  testWidgets(
    'confirmed zero Family places keeps natural height under an unbounded parent',
    (tester) async {
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: _Harness(
              draft: ZyraSubscriptionWalletDraft.sample().copyWith(
                places: const [],
              ),
              switchOnly: false,
            ),
          ),
        ),
      );
      await _tap(tester, 'wallet_group_family');
      final message = find.text(
        'No Family places. Your individual memberships stay separate.',
      );
      await tester.ensureVisible(message);
      await tester.pumpAndSettle();
      expect(message.hitTestable(), findsOneWidget);
      expect(tester.widget(_key('wallet_places_empty')), isA<ZyraEmptyState>());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'halo wallet keeps natural height under an unbounded scrolling parent',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            key: const ValueKey('wallet_parent_scroll'),
            child: _Harness(
              draft: ZyraSubscriptionWalletDraft.sample(),
              switchOnly: false,
            ),
          ),
          largeText: true,
        ),
      );
      await _familyPage(tester, 5);
      expect(find.text('Funded until renewal · Sara'), findsOneWidget);
      await _tap(tester, 'wallet_info');
      await _tap(tester, 'wallet_info_close');
      expect(find.byType(FittedBox), findsNothing);
      expect(tester.takeException(), isNull);
      expect(_state(tester).changes, 0);
    },
  );

  testWidgets(
    'covered-route halo callbacks cannot open info or page behind a destination',
    (tester) async {
      await tester.pumpWidget(
        _app(
          _Harness(
            draft: ZyraSubscriptionWalletDraft.sample(),
            switchOnly: false,
          ),
        ),
      );
      final next = tester
          .widget<IconButton>(_key('wallet_profiles_next'))
          .onPressed!;
      final info = tester.widget<IconButton>(_key('wallet_info')).onPressed!;
      final navigator = Navigator.of(tester.element(_key('wallet_info')));
      navigator.push<void>(
        MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Text('Covered wallet destination')),
        ),
      );
      await tester.pumpAndSettle();
      next();
      info();
      await tester.pumpAndSettle();
      expect(find.text('Covered wallet destination'), findsOneWidget);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.text('1 of 2 profiles'), findsOneWidget);
      expect(_key('wallet_info_dialog'), findsNothing);
    },
  );

  testWidgets(
    'halo arrows honor reduced motion without animating or changing coverage',
    (tester) async {
      await tester.pumpWidget(
        _app(
          _Harness(
            draft: ZyraSubscriptionWalletDraft.sample(),
            switchOnly: false,
          ),
        ),
      );
      await tester.ensureVisible(_key('wallet_profiles_next'));
      await tester.pumpAndSettle();
      await tester.tap(_key('wallet_profiles_next'));
      await tester.pump();
      final controller = tester
          .widget<PageView>(_key('wallet_profiles_pages'))
          .controller!;
      expect(controller.page, 1);
      expect(controller.position.isScrollingNotifier.value, isFalse);
      await tester.pumpAndSettle();
      expect(_state(tester).changes, 0);
      expect(
        _state(tester).draft.guardian.coverage,
        ZyraWalletCoverage.individualOne,
      );
    },
  );

  for (final drag in [false, true]) {
    testWidgets(
      'revoked in-flight ${drag ? 'drag' : 'animation'} rewinds locally before access resumes',
      (tester) async {
        var allowed = true;
        await tester.pumpWidget(
          _app(
            _Harness(
              draft: ZyraSubscriptionWalletDraft.sample(),
              switchOnly: false,
              canAct: () => allowed,
            ),
            reducedMotion: false,
          ),
        );
        final controller = tester
            .widget<PageView>(_key('wallet_profiles_pages'))
            .controller!;
        if (drag) {
          final gesture = await tester.startGesture(
            tester.getCenter(_key('wallet_profiles_pages')),
          );
          await gesture.moveBy(const Offset(-100, 0));
          await tester.pump(const Duration(milliseconds: 16));
          allowed = false;
          await gesture.moveBy(const Offset(-500, 0));
          expect(controller.page, greaterThan(.5));
          await gesture.up();
        } else {
          await tester.ensureVisible(_key('wallet_profiles_next'));
          await tester.pumpAndSettle();
          expect(_key('wallet_profiles_next').hitTestable(), findsOneWidget);
          await tester.tap(_key('wallet_profiles_next'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 24));
          allowed = false;
          await tester.pump(const Duration(milliseconds: 100));
          expect(controller.page, greaterThan(.5));
        }
        await tester.pumpAndSettle();
        expect(controller.page, 0);
        expect(find.text('1 of 2 profiles'), findsOneWidget);
        expect(_state(tester).changes, 0);
        expect(_state(tester).switches, isEmpty);
        expect(_state(tester).setups, isEmpty);
        expect(_state(tester).memberships, isEmpty);
        allowed = true;
        // Deliberately no rebuild on permission restoration.
        expect(controller.page, 0);
        await _tap(tester, 'wallet_profiles_next');
        expect(controller.page, 1);
        expect(find.text('2 of 2 profiles'), findsOneWidget);
        expect(
          tester
              .widget<OutlinedButton>(_key('wallet_primary_guardian'))
              .onPressed,
          isNotNull,
        );
        expect(_state(tester).changes, 0);
        expect(_state(tester).switches, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
