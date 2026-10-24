import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';

const _seeker = ValueKey('role-select-seeker');
const _guardian = ValueKey('role-select-guardian');
const _continue = ValueKey('role-choice-continue');

class _RoleRouteAudit extends NavigatorObserver {
  int pushes = 0;
  int replacements = 0;

  int get changes => pushes + replacements;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      replacements++;
}

Future<_RoleRouteAudit> _mountRoleChoice(
  WidgetTester tester, {
  Size viewport = const Size(390, 844),
  double textScale = 1,
  bool animateEntrance = false,
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final audit = _RoleRouteAudit();
  await tester.pumpWidget(
    MaterialApp(
      navigatorObservers: [audit],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
          accessibleNavigation: reducedMotion,
        ),
        child: ZyraOnboardingArrowScope(enabled: true, child: child!),
      ),
      home: RoleSelectionScreen(
        devPreview: true,
        animateDevEntrance: animateEntrance,
      ),
    ),
  );
  return audit;
}

Finder get _roleScrollView => find.descendant(
  of: find.byType(RoleSelectionScreen),
  matching: find.byType(SingleChildScrollView),
);

ScrollController _roleScrollController(WidgetTester tester) =>
    tester.widget<SingleChildScrollView>(_roleScrollView).controller!;

Future<void> _chooseRole(WidgetTester tester, Key role) async {
  await tester.ensureVisible(find.byKey(role));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(role));
  await tester.pumpAndSettle();
}

void _expectDestination(Key role) {
  expect(find.byType(RoleSelectionScreen), findsNothing);
  expect(
    find.byType(OnboardingFlow),
    role == _seeker ? findsOneWidget : findsNothing,
  );
  expect(
    find.byType(GuardianOnboardingOverviewScreen),
    role == _guardian ? findsOneWidget : findsNothing,
  );
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    // Both route destinations stay inside the existing local preview latch;
    // these gesture tests do not initialise or contact a member backend.
    ZyraInternalPreviewClient.beginPreview();
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraInternalPreviewClient.finishSignOut();
  });

  testWidgets('Guided paths is the ordinary role-choice default', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RoleSelectionScreen()));
    expect(find.text('PATH 01'), findsOneWidget);
    expect(find.text('PATH 02'), findsOneWidget);
    expect(find.byKey(_seeker), findsOneWidget);
    expect(find.byKey(_guardian), findsOneWidget);
    expect(find.byKey(_continue), findsNothing);
    expect(find.text('CHOOSE YOUR PATH'), findsOneWidget);
    expect(find.textContaining('ACCOUNT SETUP · 1 OF 2'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'both role choices stay legible and tappable in all visual directions',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final direction in const [
        'current',
        'structured',
        'luma',
        'revolut',
        'headspace',
        'mozi',
        'wise',
        'uber',
        'ahead',
        'howWeFeel',
        'atoms',
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.4),
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
              ),
              child: child!,
            ),
            home: OnboardingPreviewStyle(
              directionName: direction,
              child: const RoleSelectionScreen(devPreview: true),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final seeker = find.byKey(_seeker);
        final guardian = find.byKey(_guardian);
        expect(seeker, findsOneWidget, reason: direction);
        expect(guardian, findsOneWidget, reason: direction);
        expect(find.text('CHOOSE YOUR PATH'), findsOneWidget);
        expect(
          find.byKey(ValueKey('onboarding-preview-progress-$direction')),
          findsNothing,
          reason: direction,
        );
        expect(
          find.descendant(
            of: seeker,
            matching: find.byIcon(Icons.favorite_border),
          ),
          findsNothing,
          reason: direction,
        );
        for (final choice in [seeker, guardian]) {
          await tester.ensureVisible(choice);
          await tester.pumpAndSettle();
          expect(tester.getSize(choice).height, greaterThanOrEqualTo(104));
          expect(choice.hitTestable(), findsOneWidget, reason: direction);
        }
        expect(tester.takeException(), isNull, reason: direction);
      }
    },
  );

  testWidgets('role cards announce one clear button each', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RoleSelectionScreen(devPreview: true)),
    );
    final seekerSemantics = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label?.startsWith('Seek marriage.') == true,
    );
    final guardianSemantics = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label?.startsWith('Support as Guardian.') == true,
    );
    expect(seekerSemantics, findsOneWidget);
    expect(guardianSemantics, findsOneWidget);
    for (final choice in [seekerSemantics, guardianSemantics]) {
      final semantics = tester.widget<Semantics>(choice);
      expect(semantics.properties.button, isTrue);
      expect(semantics.properties.onTap, isNotNull);
      expect(semantics.excludeSemantics, isTrue);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected role expands; tapping it again restores both choices', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: RoleSelectionScreen(devPreview: true)),
    );
    expect(find.byKey(_continue), findsNothing);
    expect(find.byKey(_seeker), findsOneWidget);
    expect(find.byKey(_guardian), findsOneWidget);
    expect(
      find.text('One identity · one secure sign-in · two experiences'),
      findsNothing,
    );
    final initialSeekerHeight = tester.getSize(find.byKey(_seeker)).height;
    final initialGuardianHeight = tester.getSize(find.byKey(_guardian)).height;

    await tester.tap(find.byKey(_seeker));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(find.byType(OnboardingFlow), findsNothing);
    expect(find.byKey(_guardian), findsNothing);
    expect(
      tester.getSize(find.byKey(_seeker)).height,
      greaterThan(initialSeekerHeight),
    );
    expect(find.byKey(_continue), findsOneWidget);
    expect(
      tester.widget<ZyraOnboardingArrowAction>(find.byKey(_continue)).active,
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('role-choice-selected-seeker')),
      findsOneWidget,
    );
    final selectedSeeker = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label?.startsWith('Seek marriage.') == true,
      ),
    );
    expect(selectedSeeker.properties.button, isTrue);
    expect(selectedSeeker.properties.selected, isTrue);
    expect(selectedSeeker.properties.onTap, isNotNull);

    await tester.tap(find.byKey(_seeker));
    await tester.pumpAndSettle();
    expect(find.byKey(_seeker), findsOneWidget);
    expect(find.byKey(_guardian), findsOneWidget);
    expect(find.byKey(_continue), findsNothing);
    expect(
      find.byKey(const ValueKey('role-choice-selected-seeker')),
      findsNothing,
    );

    await tester.ensureVisible(find.byKey(_guardian));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_guardian));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(find.byType(OnboardingFlow), findsNothing);
    expect(find.byKey(_seeker), findsNothing);
    expect(
      tester.getSize(find.byKey(_guardian)).height,
      greaterThan(initialGuardianHeight),
    );
    expect(find.byKey(_continue), findsOneWidget);
    expect(
      find.byKey(const ValueKey('role-choice-selected-seeker')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('role-choice-selected-guardian')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(_guardian));
    await tester.pumpAndSettle();
    expect(find.byKey(_seeker), findsOneWidget);
    expect(find.byKey(_guardian), findsOneWidget);
    expect(find.byKey(_continue), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected card grows continuously while the other recedes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: RoleSelectionScreen(devPreview: true)),
    );
    final initialHeight = tester.getSize(find.byKey(_seeker)).height;

    await tester.tap(find.byKey(_seeker));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    final midHeight = tester.getSize(find.byKey(_seeker)).height;
    expect(midHeight, greaterThan(initialHeight));
    expect(find.byKey(_guardian), findsOneWidget);

    await tester.pumpAndSettle();
    final focusedHeight = tester.getSize(find.byKey(_seeker)).height;
    expect(midHeight, lessThan(focusedHeight));
    expect(find.byKey(_guardian), findsNothing);
    expect(find.byKey(_continue), findsOneWidget);

    await tester.tap(find.byKey(_seeker));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    final returningHeight = tester.getSize(find.byKey(_seeker)).height;
    expect(returningHeight, lessThan(focusedHeight));
    expect(returningHeight, greaterThan(initialHeight));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(_seeker)).height, initialHeight);
    expect(find.byKey(_guardian), findsOneWidget);
    expect(find.byKey(_continue), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced-motion setting shows the chosen state immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: true, accessibleNavigation: true),
          child: child!,
        ),
        home: const RoleSelectionScreen(devPreview: true),
      ),
    );
    await tester.ensureVisible(find.byKey(_guardian));
    await tester.pump();
    await tester.tap(find.byKey(_guardian));
    await tester.pump();
    expect(find.byKey(_seeker), findsNothing);
    expect(find.byKey(_guardian), findsOneWidget);
    expect(find.byKey(_continue), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected Seeker can continue with a light upward swipe', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: ZyraOnboardingArrowScope(
          enabled: true,
          child: RoleSelectionScreen(devPreview: true),
        ),
      ),
    );
    await tester.drag(find.byKey(_guardian), const Offset(0, -90));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(find.byKey(_continue), findsNothing);

    await tester.tap(find.byKey(_seeker));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(find.byKey(_continue), findsOneWidget);
    await tester.drag(find.byKey(_seeker), const Offset(0, -90));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsNothing);
    expect(find.byType(OnboardingFlow), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final role in [_seeker, _guardian]) {
    final name = role == _seeker ? 'Seeker' : 'Guardian';

    testWidgets('$name finger drag does not bounce fitted content', (
      tester,
    ) async {
      await _mountRoleChoice(tester);
      await _chooseRole(tester, role);
      final scroll = _roleScrollController(tester);
      final view = tester.widget<SingleChildScrollView>(_roleScrollView);
      expect(view.physics, isA<ClampingScrollPhysics>());
      expect(view.physics!.parent, isA<AlwaysScrollableScrollPhysics>());
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      final edge = scroll.position.maxScrollExtent;
      final pointer = await tester.startGesture(
        tester.getCenter(_roleScrollView),
      );
      await pointer.moveBy(const Offset(0, -45));
      await tester.pump(const Duration(milliseconds: 16));
      expect(scroll.offset, closeTo(edge, .01));
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      await pointer.moveBy(const Offset(0, -45));
      await tester.pump(const Duration(milliseconds: 16));
      expect(scroll.offset, closeTo(edge, .01));
      await pointer.up();
      await tester.pumpAndSettle();
      _expectDestination(role);
      expect(tester.takeException(), isNull);
    });

    for (final input in ['arrow', 'swipe']) {
      testWidgets('$name $input reaches the same single destination', (
        tester,
      ) async {
        final audit = await _mountRoleChoice(tester);
        await _chooseRole(tester, role);
        final before = audit.changes;
        if (input == 'arrow') {
          await tester.tap(find.byKey(_continue));
        } else {
          final scroll = _roleScrollController(tester);
          scroll.jumpTo(scroll.position.maxScrollExtent);
          await tester.pump();
          await tester.fling(_roleScrollView, const Offset(0, -100), 1200);
        }
        await tester.pumpAndSettle();
        _expectDestination(role);
        expect(audit.changes, before + 1);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('$name early focus swipe cannot advance', (tester) async {
      final audit = await _mountRoleChoice(tester);
      await tester.ensureVisible(find.byKey(role));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(role));
      await tester.pump();
      final before = audit.changes;
      expect(
        tester.widget<ZyraOnboardingArrowAction>(find.byKey(_continue)).active,
        isFalse,
      );
      await tester.drag(_roleScrollView, const Offset(0, -90));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(find.byType(OnboardingFlow), findsNothing);
      expect(find.byType(GuardianOnboardingOverviewScreen), findsNothing);
      expect(audit.changes, before);
      await tester.pumpAndSettle();
      expect(
        tester.widget<ZyraOnboardingArrowAction>(find.byKey(_continue)).active,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('$name compact overflow must be read before swipe advance', (
      tester,
    ) async {
      final audit = await _mountRoleChoice(
        tester,
        viewport: const Size(320, 568),
        textScale: 1.4,
      );
      await _chooseRole(tester, role);
      final scroll = _roleScrollController(tester);
      expect(scroll.position.maxScrollExtent, greaterThan(40));
      scroll.jumpTo(0);
      await tester.pump();
      final before = audit.changes;
      await tester.drag(_roleScrollView, const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(audit.changes, before);
      // Reading the remainder is not itself permission to advance: the next
      // fresh gesture must start at the bottom edge.
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      await tester.drag(_roleScrollView, const Offset(0, -90));
      await tester.pumpAndSettle();
      _expectDestination(role);
      expect(audit.changes, before + 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$name repeated arrow callbacks open once', (tester) async {
      final audit = await _mountRoleChoice(tester);
      await _chooseRole(tester, role);
      final before = audit.changes;
      final staleAdvance = tester
          .widget<ZyraOnboardingArrowAction>(find.byKey(_continue))
          .onPressed!;
      staleAdvance();
      staleAdvance();
      staleAdvance();
      await tester.pumpAndSettle();
      _expectDestination(role);
      expect(audit.changes, before + 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('role entrance must finish before continuing', (tester) async {
    final audit = await _mountRoleChoice(tester, animateEntrance: true);
    await tester.tap(find.byKey(_seeker));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 480));
    expect(
      tester.widget<ZyraOnboardingArrowAction>(find.byKey(_continue)).active,
      isFalse,
    );
    final before = audit.changes;
    await tester.drag(_roleScrollView, const Offset(0, -90));
    await tester.pump();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(audit.changes, before);
    await tester.pumpAndSettle();
    expect(
      tester.widget<ZyraOnboardingArrowAction>(find.byKey(_continue)).active,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing selection cancels the stale focus guard', (
    tester,
  ) async {
    await _mountRoleChoice(tester);
    await tester.tap(find.byKey(_seeker));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(_seeker));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(_seeker));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    // The first focus deadline has passed; the latest focus is still moving.
    expect(
      tester.widget<ZyraOnboardingArrowAction>(find.byKey(_continue)).active,
      isFalse,
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<ZyraOnboardingArrowAction>(find.byKey(_continue)).active,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale continue callback cannot bypass a fresh focus animation', (
    tester,
  ) async {
    final audit = await _mountRoleChoice(tester);
    await _chooseRole(tester, _seeker);
    final staleAdvance = tester
        .widget<ZyraOnboardingArrowAction>(find.byKey(_continue))
        .onPressed!;
    await tester.tap(find.byKey(_seeker));
    await tester.pump();
    await tester.tap(find.byKey(_seeker));
    await tester.pump();
    final before = audit.changes;
    staleAdvance();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(audit.changes, before);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('revoked preview cannot advance when focus finishes', (
    tester,
  ) async {
    final audit = await _mountRoleChoice(tester);
    await tester.tap(find.byKey(_seeker));
    await tester.pump();
    final staleAdvance = tester
        .widget<ZyraOnboardingArrowAction>(find.byKey(_continue))
        .onPressed!;
    final before = audit.changes;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    staleAdvance();
    await tester.pump();
    expect(find.byKey(const ValueKey('role_preview_denied')), findsOneWidget);
    expect(find.byType(OnboardingFlow), findsNothing);
    expect(audit.changes, before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing focused role choice cancels its readiness deadline', (
    tester,
  ) async {
    await _mountRoleChoice(tester);
    await tester.tap(find.byKey(_seeker));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion has no entrance or focus continuation delay', (
    tester,
  ) async {
    await _mountRoleChoice(tester, animateEntrance: true, reducedMotion: true);
    await tester.tap(find.byKey(_seeker));
    await tester.pump();
    expect(
      tester.widget<ZyraOnboardingArrowAction>(find.byKey(_continue)).active,
      isTrue,
    );
    await tester.tap(find.byKey(_continue));
    await tester.pumpAndSettle();
    _expectDestination(_seeker);
    expect(tester.takeException(), isNull);
  });
}
