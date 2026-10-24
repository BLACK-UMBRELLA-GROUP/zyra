import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/screens/wali/wali_gn_shared.dart';
import 'package:zyra/screens/wali/wali_network_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

Future<void> _loadNetworkActionReadingFonts() async {
  final reading = FontLoader('PoppinsNetworkActionTest');
  for (final weight in [
    'ExtraLight',
    'Light',
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
  ]) {
    reading.addFont(
      Future.value(
        ByteData.sublistView(
          File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
        ),
      ),
    );
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([reading.load(), icons.load()]);
}

Future<void> _edgeReturn(WidgetTester tester) async {
  final sensor = find.byKey(const ValueKey('zyra_back_swipe_edge'));
  expect(sensor, findsOneWidget);
  final rect = tester.getRect(sensor);
  await tester.timedDragFrom(
    Offset(rect.left + 8, rect.top + rect.height * .35),
    const Offset(180, 0),
    const Duration(milliseconds: 450),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevScenario.instance.reset();
    GNContext.instance.reset();
  });

  tearDown(() {
    GNContext.instance.reset();
    ZyraDevScenario.instance.reset();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = false;
  });

  for (final entry in [
    (relationship: 'father', main: true, label: 'Father · Main Guardian'),
    (
      relationship: 'brother',
      main: false,
      label: 'Brother · Additional Guardian',
    ),
    (
      relationship: null,
      main: false,
      label: 'Relationship not recorded · Additional Guardian',
    ),
  ]) {
    testWidgets('Seeker picker uses compact identity: ${entry.label}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GNSeekerPickerIdentity(
              person: WaliLinkedPerson(
                id: 'seeker-1',
                firstName: 'Aaliyah',
                relationship: entry.relationship,
                isMain: entry.main,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Aaliyah'), findsOneWidget);
      expect(find.text(entry.label), findsOneWidget);
      expect(find.textContaining('Your relationship:'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  Future<void> pumpNetwork(
    WidgetTester tester, {
    Size viewport = const Size(430, 932),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(body: WaliNetworkScreen()),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpAccess(
    WidgetTester tester, {
    required double width,
    required bool entitled,
    required bool linked,
    VoidCallback? onLink,
    VoidCallback? onPlan,
  }) async {
    tester.view.physicalSize = Size(width, 568);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF73558A), Color(0xFF2D2037)],
              ),
            ),
            child: GuardianNetworkAccessView(
              hasEntitlement: entitled,
              hasLinkedSeeker: linked,
              onLinkSeeker: onLink ?? () {},
              onMembership: onPlan ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Network bottom sheets use the canonical dark modal surface', (
    tester,
  ) async {
    ZyraColors.restoreAppPalette(null);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GNSheetShell(title: 'TEST', child: Text('Sheet content')),
        ),
      ),
    );

    final shell = tester.widget<Container>(
      find.byKey(const ValueKey('zyra-modal-sheet-surface')),
    );
    final decoration = shell.decoration! as BoxDecoration;
    expect(decoration.color, ZyraColors.modalSheetSurface);
    expect(decoration.gradient, isNull);
  });

  testWidgets('D14 preview serves one family in the active Seeker context', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    await pumpNetwork(tester);

    expect(find.byKey(const Key('guardian-network-preview')), findsOneWidget);
    expect(find.text('Network'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
    expect(find.byKey(const Key('gn-preview-controls')), findsNothing);
    expect(find.textContaining('Chosen for'), findsNothing);
    expect(find.byKey(const Key('gn-served-fam-h')), findsOneWidget);
    expect(
      GNContext.instance.networkCardDesign,
      GNNetworkCardDesign.portraitFocus,
    );
    expect(
      find.byKey(const Key('gn-card-design-portraitFocus')),
      findsOneWidget,
    );
    expect(
      GNContext.instance.networkActionLayout,
      GNNetworkActionLayout.current,
    );
    expect(find.text('H., 27'), findsOneWidget);
    expect(find.text('West Midlands, UK'), findsOneWidget);
    expect(find.text('HIGH FIT'), findsNothing);
    expect(find.text('Practising'), findsNothing);
    expect(find.text('Nearby region'), findsNothing);
    expect(find.text('High compatibility'), findsNothing);
    expect(find.byKey(const Key('gn-family-photo')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('gn-family-photo'))).height,
      greaterThan(250),
    );
    expect(find.text('Main Guardian · Father'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('View profile'), findsOneWidget);
    expect(find.text('Speak to Guardian'), findsOneWidget);

    final served = tester.widget<Container>(
      find.byKey(const Key('gn-served-fam-h')),
    );
    expect(
      served.decoration,
      isNull,
      reason: 'The recommendation should live directly on the page.',
    );
    final speak = tester.widget<GNActionPill>(
      find.byKey(const Key('gn-speak-action')),
    );
    expect(speak.primary, isFalse);
    expect(speak.goldAccent, isTrue);
    expect(speak.borderless, isFalse);
  });

  testWidgets('all five borderless Network designs are selectable', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    await pumpNetwork(tester);

    for (final design in GNNetworkCardDesign.values) {
      GNContext.instance.setNetworkCardDesign(design);
      await tester.pump();

      expect(find.byKey(Key('gn-card-design-${design.name}')), findsOneWidget);
      final served = tester.widget<Container>(
        find.byKey(const Key('gn-served-fam-h')),
      );
      expect(served.decoration, isNull);
      expect(find.byKey(const Key('gn-family-photo')), findsOneWidget);
      expect(find.byKey(const Key('gn-speak-action')), findsOneWidget);
      expect(find.byKey(const Key('gn-next-action')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: design.label);
    }
  });

  testWidgets(
    'all Browser action layouts retain profile, Guardian contact and Next',
    (tester) async {
      ZyraDevScenario.instance.setWaliLinkedSeekers(1);
      await pumpNetwork(tester);

      for (final layout in GNNetworkActionLayout.values) {
        GNContext.instance.setNetworkActionLayout(layout);
        await tester.pump();

        final browser = find.byKey(const Key('gn-served-fam-h'));
        expect(browser, findsOneWidget, reason: layout.label);
        for (final label in ['View profile', 'Speak to Guardian', 'Next']) {
          expect(
            find.descendant(of: browser, matching: find.text(label)),
            findsOneWidget,
            reason: '${layout.label}: $label',
          );
        }
        expect(
          find.descendant(
            of: browser,
            matching: find.byKey(const Key('gn-speak-action')),
          ),
          findsOneWidget,
          reason: layout.label,
        );
        expect(
          find.descendant(
            of: browser,
            matching: find.byKey(const Key('gn-next-action')),
          ),
          findsOneWidget,
          reason: layout.label,
        );
        expect(tester.takeException(), isNull, reason: layout.label);
      }
    },
  );

  testWidgets('Browser layouts expose four distinct action hierarchies', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    await pumpNetwork(tester);
    final card = find.byKey(const Key('gn-served-fam-h'));

    for (final layout in GNNetworkActionLayout.values) {
      GNContext.instance.setNetworkActionLayout(layout);
      await tester.pump();
      final view = tester.getRect(
        find.byKey(const Key('gn-view-profile-action')),
      );
      final speak = tester.getRect(find.byKey(const Key('gn-speak-action')));
      final next = tester.getRect(find.byKey(const Key('gn-next-action')));
      final width = tester.getSize(card).width;

      switch (layout) {
        case GNNetworkActionLayout.current:
          expect(view.center.dy, closeTo(speak.center.dy, 1));
          expect(next.top, greaterThan(view.bottom));
          expect(next.width, closeTo(width, 1));
        case GNNetworkActionLayout.quietNext:
          expect(view.center.dy, closeTo(speak.center.dy, 1));
          expect(next.top, greaterThan(view.bottom));
          expect(next.width, lessThan(width * 0.6));
          expect(next.height, greaterThanOrEqualTo(44));
        case GNNetworkActionLayout.speakFirst:
          expect(speak.bottom, lessThan(view.top));
          expect(view.center.dy, closeTo(next.center.dy, 1));
          expect(speak.width, closeTo(width, 1));
          expect(next.height, greaterThanOrEqualTo(44));
        case GNNetworkActionLayout.profileFirst:
          expect(view.bottom, lessThan(speak.top));
          expect(speak.center.dy, closeTo(next.center.dy, 1));
          expect(view.width, closeTo(width, 1));
          expect(speak.width, greaterThan(next.width));
          expect(next.height, greaterThanOrEqualTo(44));
      }
      final contact = tester.widget<GNActionPill>(
        find.byKey(const Key('gn-speak-action')),
      );
      expect(contact.goldAccent, isTrue, reason: layout.label);
      expect(contact.primary, isFalse, reason: layout.label);
      expect(contact.enabled, isTrue, reason: layout.label);
      expect(tester.takeException(), isNull, reason: layout.label);
    }
  });

  testWidgets(
    'Browser action choice leaves Sent and Received controls intact',
    (tester) async {
      ZyraDevScenario.instance.setWaliLinkedSeekers(1);
      GNContext.instance.setPreviewCount(GNNetworkPreviewArea.sent, 1);
      GNContext.instance.setPreviewCount(GNNetworkPreviewArea.received, 1);
      await pumpNetwork(tester);

      for (final layout in GNNetworkActionLayout.values) {
        GNContext.instance.setNetworkActionLayout(layout);
        await tester.pump();

        await tester.tap(find.byKey(const Key('gn-mode-sent')));
        await tester.pumpAndSettle();
        final sent = find.byKey(const Key('gn-sent-fam-h'));
        expect(sent, findsOneWidget);
        for (final label in [
          'View profile',
          'Withdraw request',
          'Waiting for their family to respond',
        ]) {
          expect(
            find.descendant(of: sent, matching: find.text(label)),
            findsOneWidget,
            reason: '${layout.label}: Sent $label',
          );
        }
        expect(
          find.descendant(of: sent, matching: find.text('Next')),
          findsNothing,
        );

        await tester.tap(find.byKey(const Key('gn-mode-received')));
        await tester.pumpAndSettle();
        final received = find.byKey(const Key('gn-incoming-fam-h'));
        expect(received, findsOneWidget);
        for (final label in [
          'View profile',
          'View Guardian',
          'Not for us',
          'Connect',
        ]) {
          expect(
            find.descendant(of: received, matching: find.text(label)),
            findsOneWidget,
            reason: '${layout.label}: Received $label',
          );
        }
        expect(
          find.descendant(of: received, matching: find.text('Next')),
          findsNothing,
        );
        expect(tester.takeException(), isNull, reason: layout.label);

        await tester.tap(find.byKey(const Key('gn-mode-browser')));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('each Browser layout keeps the three actions wired correctly', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    GNContext.instance.setPreviewCount(GNNetworkPreviewArea.browser, 1);
    await pumpNetwork(tester);

    final wards = ZyraDevScenario.composeWaliWards();
    final ward = wards.single;
    final family = GNContext.instance.familiesFor(wards, ward).first;

    for (final layout in GNNetworkActionLayout.values) {
      GNContext.instance.setNetworkActionLayout(layout);
      await tester.pump();

      await tester.ensureVisible(find.text('View profile'));
      await tester.tap(find.text('View profile'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('gn-profile-photo-viewer')),
        findsOneWidget,
        reason: layout.label,
      );
      await swipeZyraBack(tester);

      await tester.ensureVisible(find.byKey(const Key('gn-speak-action')));
      await tester.tap(find.byKey(const Key('gn-speak-action')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('gn-request-page-swipe-surface')),
        findsOneWidget,
        reason: layout.label,
      );
      await swipeZyraBack(tester);

      await tester.ensureVisible(find.byKey(const Key('gn-next-action')));
      await tester.tap(find.byKey(const Key('gn-next-action')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        GNContext.instance.stageOf(ward, family),
        GNStage.setAside,
        reason: layout.label,
      );
      expect(
        GNContext.instance.analytics,
        contains('family_next · ${family.id}'),
        reason: layout.label,
      );
      expect(find.byType(SnackBar), findsNothing);
      GNContext.instance.setStage(ward, family, GNStage.none);
      await tester.pump();
    }
  });

  testWidgets(
    'Browser action layouts do not grant Additional Guardians contact',
    (tester) async {
      ZyraDevScenario.instance.setWaliLinkedSeekers(1);
      GNContext.instance.setMainWali(false);
      await pumpNetwork(tester);

      for (final layout in GNNetworkActionLayout.values) {
        GNContext.instance.setNetworkActionLayout(layout);
        await tester.pump();
        expect(find.text('View profile'), findsOneWidget);
        expect(find.text('Ask Main Guardian'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
        final ask = tester.widget<GNActionPill>(
          find.byKey(const Key('gn-speak-action')),
        );
        expect(ask.enabled, isFalse, reason: layout.label);
        expect(tester.takeException(), isNull, reason: layout.label);
      }
    },
  );

  testWidgets('all card and action layouts stay reachable with larger text', (
    tester,
  ) async {
    // The artificial Ahem fallback expands the existing title/control Row
    // beyond 320px. Use the shipped reading font for a real layout assertion,
    // while retaining the same overflow, target-size and hit-test checks.
    await tester.runAsync(_loadNetworkActionReadingFonts);
    final previousReadingFont = ZyraText.testReadingFontFamily;
    ZyraText.testReadingFontFamily = 'PoppinsNetworkActionTest';
    addTearDown(() => ZyraText.testReadingFontFamily = previousReadingFont);
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    await pumpNetwork(tester, viewport: const Size(320, 568), textScale: 1.4);

    for (final design in GNNetworkCardDesign.values) {
      GNContext.instance.setNetworkCardDesign(design);
      for (final layout in GNNetworkActionLayout.values) {
        GNContext.instance.setNetworkActionLayout(layout);
        await tester.pumpAndSettle();
        for (final key in const [
          'gn-view-profile-action',
          'gn-speak-action',
          'gn-next-action',
        ]) {
          final action = find.byKey(Key(key));
          expect(
            action,
            findsOneWidget,
            reason: '${design.label}, ${layout.label}: $key',
          );
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          expect(
            action.hitTestable(),
            findsOneWidget,
            reason: '${design.label}, ${layout.label}: $key',
          );
          final rect = tester.getRect(action);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
          expect(
            rect.height,
            greaterThanOrEqualTo(44),
            reason: '${design.label}, ${layout.label}: $key tap target',
          );
        }
        expect(
          tester.takeException(),
          isNull,
          reason: '${design.label}, ${layout.label}',
        );
      }
    }
  });

  testWidgets(
    'Browser, Sent and Received independently preview one, two or three profiles',
    (tester) async {
      ZyraDevScenario.instance.setWaliLinkedSeekers(1);
      await pumpNetwork(tester);
      const ids = ['fam-h', 'fam-s', 'fam-t'];

      for (var count = 1; count <= 3; count++) {
        for (final area in GNNetworkPreviewArea.values) {
          GNContext.instance.setPreviewCount(area, count);
        }
        await tester.pump();

        await tester.tap(find.byKey(const Key('gn-mode-browser')));
        await tester.pumpAndSettle();
        for (var index = 0; index < ids.length; index++) {
          expect(
            find.byKey(Key('gn-served-${ids[index]}')),
            index < count ? findsOneWidget : findsNothing,
          );
        }

        await tester.tap(find.byKey(const Key('gn-mode-sent')));
        await tester.pumpAndSettle();
        for (var index = 0; index < ids.length; index++) {
          expect(
            find.byKey(Key('gn-sent-${ids[index]}')),
            index < count ? findsOneWidget : findsNothing,
          );
        }

        await tester.tap(find.byKey(const Key('gn-mode-received')));
        await tester.pumpAndSettle();
        for (var index = 0; index < ids.length; index++) {
          expect(
            find.byKey(Key('gn-incoming-${ids[index]}')),
            index < count ? findsOneWidget : findsNothing,
          );
        }
        expect(tester.takeException(), isNull, reason: '$count per tab');
      }
    },
  );

  testWidgets('every Network card design is shared by all three tabs', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    for (final area in GNNetworkPreviewArea.values) {
      GNContext.instance.setPreviewCount(area, 3);
    }
    await pumpNetwork(tester);

    for (final design in GNNetworkCardDesign.values) {
      GNContext.instance.setNetworkCardDesign(design);
      await tester.pump();

      for (final target in const [
        ('gn-mode-browser', 'gn-served-fam-h'),
        ('gn-mode-sent', 'gn-sent-fam-h'),
        ('gn-mode-received', 'gn-incoming-fam-h'),
      ]) {
        await tester.tap(find.byKey(Key(target.$1)));
        await tester.pumpAndSettle();
        final card = find.byKey(Key(target.$2));
        expect(card, findsOneWidget);
        expect(
          find.descendant(
            of: card,
            matching: find.byKey(Key('gn-card-design-${design.name}')),
          ),
          findsOneWidget,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${design.label} ${target.$1}',
        );
      }
    }
  });

  testWidgets('blank Guardian invitation is centred in the usable page', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(0);
    await pumpNetwork(tester);

    final invitation = find.byType(ZyraAddCircle);
    expect(invitation, findsOneWidget);
    expect(find.text('Invite your Seeker'), findsOneWidget);

    final centre = tester.getCenter(invitation);
    expect(centre.dx, closeTo(215, 1));
    // The visual content centre accounts for the fixed title above and the
    // floating navigation clearance below.
    expect(centre.dy, closeTo(466, 30));
  });

  testWidgets(
    'shared Seeker slider drags and keeps all ten Seekers reachable',
    (tester) async {
      ZyraDevScenario.instance.setWaliLinkedSeekers(10);
      final wards = ZyraDevScenario.composeWaliWards();
      expect(wards, hasLength(10));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 390, child: GNSeekerSlider(wards: wards)),
            ),
          ),
        ),
      );

      // Four readable names, never ten compressed segments.
      expect(find.text('Aaliyah'), findsOneWidget);
      expect(find.text('Maryam'), findsOneWidget);
      expect(find.text('Yusuf'), findsNothing);
      expect(find.text('+6'), findsOneWidget);

      // The Dashboard uses this exact shared control: a horizontal drag
      // moves the live fill and settles the shared Seeker selection.
      await tester.timedDrag(
        find.byKey(const Key('gn-seeker-slider')),
        const Offset(-95, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      expect(GNContext.instance.selectedSeekerId, 'dev-ws1');

      // Overflow is a picker, not a hard cap: even Seeker ten remains
      // directly selectable and writes the same GNContext.
      await tester.tap(find.byKey(const Key('gn-seeker-more')));
      await tester.pumpAndSettle();
      final lastOption = find.byKey(const Key('gn-seeker-option-dev-ws9'));
      await tester.scrollUntilVisible(
        lastOption,
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(lastOption);
      await tester.pumpAndSettle();

      expect(GNContext.instance.selectedSeekerId, 'dev-ws9');
      expect(find.text('Khadija'), findsOneWidget);
      expect(find.text('+8'), findsOneWidget);
    },
  );

  testWidgets('Network modes swipe and Seeker dropdown shares GNContext', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(3);
    await pumpNetwork(tester);

    expect(find.text('Profiles'), findsOneWidget);
    expect(find.text('Sent requests'), findsOneWidget);
    expect(find.text('Received'), findsOneWidget);

    await tester.tap(find.byKey(const Key('gn-seeker-dropdown')));
    await tester.pumpAndSettle();
    expect(find.text('CHOOSE SEEKER'), findsOneWidget);
    expect(find.text('Father · Main Guardian'), findsOneWidget);
    expect(find.textContaining('Your relationship:'), findsNothing);
    expect(find.byKey(const Key('gn-seeker-picker-sheet')), findsOneWidget);
    expect(find.byType(PopupMenuButton), findsNothing);
    await tester.tap(find.byKey(const Key('gn-seeker-dropdown-dev-ws2')));
    await tester.pumpAndSettle();

    expect(GNContext.instance.selectedSeekerId, 'dev-ws2');
    expect(find.byKey(const Key('gn-served-fam-h')), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('gn-mode-page-view')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('No sent requests'), findsOneWidget);
    expect(find.byType(GNQuietNotice), findsNothing);

    await tester.drag(
      find.byKey(const Key('gn-mode-page-view')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gn-incoming-fam-m')), findsOneWidget);
  });

  testWidgets('received action and header Seeker control use current theme', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    await pumpNetwork(tester);

    final titleRow = find.byKey(const Key('gn-network-title-row'));
    final seekerControl = find.byKey(const Key('gn-seeker-header-control'));
    expect(titleRow, findsOneWidget);
    expect(seekerControl, findsOneWidget);
    expect(
      find.descendant(of: seekerControl, matching: find.text('Aaliyah')),
      findsOneWidget,
    );
    expect(find.text('SEEKER'), findsNothing);
    expect(
      tester.getCenter(find.text('Network')).dy,
      closeTo(tester.getCenter(find.text('Aaliyah')).dy, 3),
    );

    await tester.tap(find.byKey(const Key('gn-mode-received')));
    await tester.pumpAndSettle();

    final connect = tester.widget<GNActionPill>(
      find.byKey(const Key('gn-connect-family-action')),
    );
    expect(connect.goldAccent, isTrue);
    expect(connect.primary, isFalse);
  });

  testWidgets('current GNScene edge states are reachable through GNContext', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    GNContext.instance.setScene(GNScene.empty);
    await pumpNetwork(tester);
    expect(find.text('No suitable families right now'), findsOneWidget);

    GNContext.instance.setScene(GNScene.error);
    await tester.pump();
    expect(find.textContaining("Something didn't quite work"), findsOneWidget);

    GNContext.instance.setScene(GNScene.loading);
    await tester.pump();
    expect(find.text('ZYRA is choosing the next family…'), findsOneWidget);

    GNContext.instance.setScene(GNScene.capReached);
    await tester.pump();
    expect(find.text('0 of 3 live processes'), findsOneWidget);

    GNContext.instance.setScene(GNScene.merge);
    await tester.pump();
    expect(
      find.text('This family has already requested connection.'),
      findsNothing,
    );
    expect(find.byKey(const Key('gn-served-fam-h')), findsOneWidget);
  });

  testWidgets('Next advances without explanatory feedback', (tester) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    await pumpNetwork(tester);

    final wards = ZyraDevScenario.composeWaliWards();
    final ward = wards.single;
    final families = GNContext.instance.familiesFor(wards, ward);
    final firstFamily = families.first;

    final action = find.text('Next');
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pump();

    expect(GNContext.instance.stageOf(ward, firstFamily), GNStage.setAside);
    expect(
      GNContext.instance.analytics,
      contains('family_next · ${firstFamily.id}'),
    );
    expect(find.byType(SnackBar), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('gn-served-fam-s')), findsOneWidget);
  });

  testWidgets('View profile opens a full-screen dismissible photo viewer', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    await pumpNetwork(tester);

    await tester.tap(find.byKey(const Key('gn-family-photo')));
    await tester.pumpAndSettle();

    expect(find.text('PROFILE'), findsNothing);
    final viewer = find.byKey(const Key('gn-profile-photo-viewer'));
    expect(viewer, findsOneWidget);
    expect(
      find.byKey(const ValueKey('connections-profile-swipe-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('zyra_visible_back_button')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: viewer,
        matching: find.textContaining('compatibility'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: viewer,
        matching: find.textContaining('West Midlands'),
      ),
      findsNothing,
    );

    await swipeZyraBack(tester);
    expect(viewer, findsNothing);

    await tester.tap(find.text('View profile'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('connections-profile-swipe-surface')),
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();
    expect(viewer, findsOneWidget);
    await _edgeReturn(tester);
    expect(viewer, findsNothing);
  });

  testWidgets('Next is below the profile actions in the thumb zone', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    await pumpNetwork(tester);

    final next = find.byKey(const Key('gn-next-action'));
    expect(next, findsOneWidget);
    expect(
      tester.getCenter(next).dy,
      greaterThan(tester.getCenter(find.text('View profile')).dy),
    );
  });

  testWidgets('Speak to Guardian opens a full-screen dismissible page', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    await pumpNetwork(tester);

    await tester.tap(find.text('Speak to Guardian'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('gn-request-page-swipe-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('zyra_visible_back_button')),
      findsNothing,
    );
    expect(find.text('Speak to Guardian'), findsOneWidget);
    expect(find.text('Send a request to their Main Guardian?'), findsOneWidget);
    expect(find.text('Send request'), findsOneWidget);

    await swipeZyraBack(tester);
    expect(
      find.byKey(const Key('gn-request-page-swipe-surface')),
      findsNothing,
    );

    await tester.tap(find.text('Speak to Guardian'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('gn-request-page-swipe-surface')),
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('gn-request-page-swipe-surface')),
      findsOneWidget,
    );
    await _edgeReturn(tester);
    expect(
      find.byKey(const Key('gn-request-page-swipe-surface')),
      findsNothing,
    );
  });

  testWidgets('sent family leaves Browser and appears in Sent requests', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    await pumpNetwork(tester);

    expect(find.byKey(const Key('gn-served-fam-h')), findsOneWidget);
    await tester.tap(find.text('Speak to Guardian'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gn-request-page-send')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('gn-served-fam-h')), findsNothing);
    expect(find.byKey(const Key('gn-served-fam-s')), findsOneWidget);

    await tester.tap(find.byKey(const Key('gn-mode-sent')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gn-sent-fam-h')), findsOneWidget);
    expect(find.byKey(const Key('gn-served-fam-h')), findsNothing);
  });

  testWidgets('Guardian Network four-state matrix fits narrow and standard', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [320.0, 390.0]) {
      await pumpAccess(tester, width: width, entitled: false, linked: false);
      expect(
        find.byKey(const Key('guardian-network-basic-unlinked')),
        findsOneWidget,
      );
      expect(find.text('Network is part of Guardian One'), findsOneWidget);
      expect(find.text('View Guardian One'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpAccess(tester, width: width, entitled: false, linked: true);
      expect(
        find.byKey(const Key('guardian-network-basic-linked')),
        findsOneWidget,
      );
      expect(find.text('Network is part of Guardian One'), findsOneWidget);
      expect(find.text('View Guardian One'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpAccess(tester, width: width, entitled: true, linked: false);
      expect(
        find.byKey(const Key('guardian-network-entitled-unlinked')),
        findsOneWidget,
      );
      expect(find.text('Guardian One'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpAccess(tester, width: width, entitled: true, linked: true);
      expect(
        find.byKey(const Key('guardian-network-entitled-linked-unavailable')),
        findsOneWidget,
      );
      expect(
        find.text('Guardian Network is not available yet'),
        findsOneWidget,
      );
      expect(find.textContaining('£'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  for (final linked in [false, true]) {
    testWidgets('Basic Network explains held availability: linked=$linked', (
      tester,
    ) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var planOpens = 0;
      await pumpAccess(
        tester,
        width: 320,
        entitled: false,
        linked: linked,
        onPlan: () => planOpens++,
      );
      expect(
        find.text(
          'Guardian Network is not available in this build. You can view Guardian One membership details below.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('unlock Network'), findsNothing);
      expect(find.text('Network is part of Guardian One'), findsOneWidget);
      expect(planOpens, 0);
      await tester.tap(find.text('View Guardian One'));
      expect(planOpens, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('inactive access opens membership only after a user tap', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var planOpens = 0;
    await pumpAccess(
      tester,
      width: 320,
      entitled: false,
      linked: true,
      onPlan: () => planOpens++,
    );
    expect(planOpens, 0);
    expect(find.textContaining('Guardian+'), findsNothing);
    expect(find.textContaining('Preview'), findsNothing);
    expect(find.textContaining('£'), findsNothing);
    expect(find.text('Network is part of Guardian One'), findsOneWidget);
    await tester.tap(find.text('View Guardian One'));
    expect(planOpens, 1);
    expect(tester.takeException(), isNull);
  });

  test('GNContext reset clears selection, scene, stages and analytics', () {
    ZyraDevScenario.instance.setWaliLinkedSeekers(3);
    final wards = ZyraDevScenario.composeWaliWards();
    final ward = wards.first;
    final family = GNContext.instance.familiesFor(wards, ward).first;

    GNContext.instance.selectSeeker(wards.last.id);
    GNContext.instance.setScene(GNScene.error);
    GNContext.instance.setStage(ward, family, GNStage.sent);
    GNContext.instance.setNetworkCardDesign(GNNetworkCardDesign.cinematic);
    GNContext.instance.setNetworkActionLayout(GNNetworkActionLayout.speakFirst);
    GNContext.instance.setPreviewCount(GNNetworkPreviewArea.browser, 3);
    GNContext.instance.track('request_sent', family.id);
    GNContext.instance.reset();

    expect(GNContext.instance.selectedSeekerId, isNull);
    expect(GNContext.instance.scene, GNScene.standard);
    expect(GNContext.instance.stageOf(ward, family), GNStage.none);
    expect(GNContext.instance.analytics, isEmpty);
    expect(
      GNContext.instance.networkCardDesign,
      GNNetworkCardDesign.portraitFocus,
    );
    expect(
      GNContext.instance.networkActionLayout,
      GNNetworkActionLayout.current,
    );
    expect(
      GNContext.instance.previewCountFor(GNNetworkPreviewArea.browser),
      isNull,
    );
  });
}
