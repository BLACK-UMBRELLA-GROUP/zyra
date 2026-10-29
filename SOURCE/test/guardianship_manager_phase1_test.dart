import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/screens/wali/wali_seekers_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mainGuardian = WaliLinkedPerson(
    id: 'main',
    firstName: 'Abdul',
    relationship: 'father',
    isMain: true,
    linkedAt: DateTime.utc(2026, 4, 12),
  );
  final additionalGuardian = WaliLinkedPerson(
    id: 'additional',
    firstName: 'Hassan',
    relationship: 'brother',
    linkedAt: DateTime.utc(2026, 5, 8),
  );

  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance.reset();
    ZyraText.useTestFontStubs = true;
    ZyraColors.restoreAppSurfaceStyle(null);
  });

  tearDown(() {
    ZyraDevScenario.instance.reset();
    ZyraText.useTestFontStubs = false;
  });

  Widget manager(
    List<WaliLinkedPerson> people, {
    VoidCallback? onAdd,
    double scale = 1,
    Future<ZyraSourceResult<List<PendingInvite>>> Function()?
    pendingInvitesLoader,
  }) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: GuardianshipManagerView(
            people: people,
            linksAvailable: true,
            onRetryLinks: () {},
            onOpenGuardian: (_) {},
            onAdd: onAdd ?? () {},
            pendingInvitesLoader:
                pendingInvitesLoader ??
                () async => const ZyraSourceResult.available(<PendingInvite>[]),
            comparisonNow: DateTime.utc(2026, 8, 30),
          ),
        ),
      ),
    ),
  );

  testWidgets('Guardian keeps one Add flow in the top-right plus', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var addCalls = 0;
    final invite = PendingInvite(
      token: 'LIVE1234',
      label: 'Dad',
      createdAt: DateTime.utc(2026, 8, 28),
      expiresAt: DateTime.utc(2026, 9, 2),
    );
    await tester.pumpWidget(
      manager(
        const [],
        onAdd: () => addCalls += 1,
        pendingInvitesLoader: () async => ZyraSourceResult.available([invite]),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('guardian-manager-title')),
      findsOneWidget,
    );
    expect(find.text('Guardian'), findsOneWidget);
    expect(find.text('Guardianship Manager'), findsNothing);
    expect(
      find.textContaining('Your Main Guardian acts on your Journey'),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('guardian-add-top')), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('guardian-add-top'))).label,
      'Add a Guardian',
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('guardian-add-top'))),
      const Size(48, 48),
    );
    expect(find.text('INVITATIONS'), findsNothing);
    expect(find.textContaining('Create a code, enter one'), findsNothing);
    expect(find.text('Invite or enter a code'), findsNothing);
    expect(find.textContaining('Invite someone you trust'), findsNothing);
    expect(find.byKey(const ValueKey('guardian-manager-invite')), findsNothing);
    expect(find.byKey(const ValueKey('guardian-manager-add')), findsNothing);
    expect(find.textContaining('Awaiting response'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guardian-add-top')));
    expect(addCalls, 1);
    semantics.dispose();
  });

  testWidgets('empty Add a Guardian group is vertically centred', (
    tester,
  ) async {
    await tester.pumpWidget(manager(const []));
    await tester.pumpAndSettle();

    final page = tester.getRect(
      find.byKey(const PageStorageKey('guardianship-manager')),
    );
    final prompt = tester.getRect(
      find.byKey(const ValueKey('guardianship-manager-empty')),
    );
    final title = tester.widget<Text>(
      find.byKey(const ValueKey('guardian-manager-title')),
    );
    final titleRect = tester.getRect(
      find.byKey(const ValueKey('guardian-manager-title')),
    );
    final shield = tester.widget<Icon>(
      find.byKey(const ValueKey('guardian-empty-shield')),
    );
    final groupCentre = prompt.center.dy;

    expect(groupCentre, closeTo(page.center.dy, 50));
    expect(title.style?.fontSize, ZyraText.pageTitleSize);
    expect(titleRect.top - page.top, closeTo(16, 0.1));
    expect(shield.color, ZyraColors.ink(.35));
    expect(
      tester.widget(find.byKey(const ValueKey('guardianship-manager-empty'))),
      isA<ZyraEmptyState>(),
    );
    expect(find.byKey(const ValueKey('guardian-add-top')), findsOneWidget);
    expect(find.byKey(const ValueKey('guardian-manager-add')), findsNothing);
    expect(find.textContaining('Invite someone you trust'), findsNothing);
  });

  testWidgets(
    'compact 200 percent Guardian empty retains shared styling and top Add',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      var additions = 0;
      await tester.pumpWidget(
        manager(const [], scale: 2, onAdd: () => additions++),
      );
      await tester.pumpAndSettle();
      final empty = find.byKey(const ValueKey('guardianship-manager-empty'));
      expect(tester.widget(empty), isA<ZyraEmptyState>());
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.text('Add a Guardian')),
        ).scale(15),
        30,
      );
      expect(
        find.descendant(of: empty, matching: find.byType(Container)),
        findsNothing,
      );
      expect(find.text('Add a Guardian').hitTestable(), findsOneWidget);
      final add = find.byKey(const ValueKey('guardian-add-top'));
      expect(tester.getSize(add), const Size(48, 48));
      await tester.tap(add);
      expect(additions, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final enlarged in [false, true]) {
    testWidgets(
      'confirmed empty Seekers uses the shared prompt at ${enlarged ? 'compact200' : 'normal'} size',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = enlarged
            ? const Size(320, 568)
            : const Size(393, 852);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(enlarged ? 2 : 1)),
              child: child!,
            ),
            home: Scaffold(
              body: WaliSeekersScreen(
                loadLinks: () async =>
                    const ZyraSourceResult.available(<WaliLinkedPerson>[]),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final empty = find.byKey(const ValueKey('guardian-seekers-empty'));
        expect(tester.widget(empty), isA<ZyraEmptyState>());
        expect(
          find.descendant(of: empty, matching: find.byType(Container)),
          findsNothing,
        );
        final icon = tester.widget<Icon>(
          find.descendant(of: empty, matching: find.byType(Icon)),
        );
        expect(icon.color, ZyraColors.ink(.35));
        expect(icon.size, 30);
        expect(find.text('Add a Seeker').hitTestable(), findsOneWidget);
        final add = find.byKey(const ValueKey('guardian-seeker-add-top'));
        expect(tester.getSize(add), const Size(48, 48));
        expect(tester.widget<InkWell>(add).onTap, isNotNull);
        expect(find.byType(ZyraUnknownErrorState), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'unavailable Seekers roster remains an error instead of an empty prompt',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WaliSeekersScreen(
              loadLinks: () async => const ZyraSourceResult.unavailable(
                ZyraSourceFailure.notReady,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('guardian-seekers-empty')),
        findsNothing,
      );
      expect(find.byType(ZyraUnknownErrorState), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Main is first in a vertical uncapped roster with no movement', (
    tester,
  ) async {
    final people = [
      additionalGuardian,
      mainGuardian,
      for (var index = 0; index < 5; index++)
        WaliLinkedPerson(
          id: 'additional-$index',
          firstName: 'Guardian $index',
          linkedAt: DateTime.utc(2026, 6, index + 1),
        ),
    ];
    await tester.pumpWidget(manager(people));
    await tester.pumpAndSettle();

    final mainCard = find.byKey(const ValueKey('guardian-manager-card-main'));
    final additionalCard = find.byKey(
      const ValueKey('guardian-manager-card-additional'),
    );
    expect(mainCard, findsOneWidget);
    expect(additionalCard, findsOneWidget);
    expect(
      tester.getTopLeft(mainCard).dy,
      lessThan(tester.getTopLeft(additionalCard).dy),
    );
    expect(find.text('Shared a profile suggestion'), findsNothing);
    expect(find.text('Family Review completed'), findsNothing);
    expect(
      find.byKey(const ValueKey('guardian-history-consent')),
      findsNothing,
    );
    expect(find.byType(PageView), findsNothing);
  });

  test('new comparison family is present and corrected hint is pinned', () {
    final designs = File(
      'lib/screens/wali/seeker_guardian_designs.dart',
    ).readAsStringSync();
    expect(designs, contains('class SeekerGuardianPage'));
    expect(designs, isNot(contains('guardianPulseCarousel')));
    final source = File(
      'lib/services/zyra_wali_link_service.dart',
    ).readAsStringSync();
    expect(source, contains('e.hint?.trim().isNotEmpty'));
    expect(
      source,
      contains('An active or paused Journey requires you to keep a Guardian.'),
    );
    expect(source, isNot(contains('or end or pause the Journey.')));
  });
}
