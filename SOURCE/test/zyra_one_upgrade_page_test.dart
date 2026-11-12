import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/dev/zyra_one_journey_monogram_presentation.dart';
import 'package:zyra/screens/subscription/upgrade_screen.dart';
import 'package:zyra/screens/subscription/zyra_one_upgrade_page.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_profile_details_page.dart';

import 'visual/baseline_capture_support.dart';

const _reviewDirectory = String.fromEnvironment('ZYRA_LOCK25_REVIEW_DIR');
Finder _key(String id) => find.byKey(ValueKey(id));

Future<void> _capture(BaselineHarness harness, String name) async {
  if (_reviewDirectory.isEmpty) return;
  final tester = harness.tester;
  final old = debugDisableShadows;
  debugDisableShadows = false;
  try {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      _key('zyra-founder-baseline-boundary'),
    );
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    repaint(boundary);
    await tester.pump();
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$_reviewDirectory/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
      } finally {
        image.dispose();
      }
    });
  } finally {
    debugDisableShadows = old;
  }
}

void main() {
  setUpAll(baselineSetUp);
  tearDownAll(baselineTearDown);

  const seekerVisible = [
    'Journey places',
    'Browse profiles',
    'Compatibility score',
    'Filters',
    'Guardians',
    'Look again at declined profiles',
    'Chaperoned video calls',
  ];
  const guardianVisible = [
    'See the Journeys your Seeker allows',
    'Family Review (Main Guardian)',
    'Chat in a Journey',
    'Compatibility score',
    'Join chaperoned video calls',
  ];
  const seekerHidden = [
    'Requests waiting at once',
    'Compatibility Unlocks',
    'Restart an ended Journey',
    'Gold ring on your profile',
  ];
  const guardianHidden = [
    'Guardian Circle',
    'Network: other families\' Seekers',
    'Introductions',
    'Connect with Guardian',
    'Your Seeker shows in Network',
    'Gold ring on your profile',
  ];

  for (final guardian in [false, true]) {
    final role = guardian ? 'Guardian' : 'Seeker';
    testWidgets(
      '$role Basic Profile opens the exact honest comparison and returns',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = BaselineHarness(tester, group: 'lock25');
        await h.mount(
          guardian: guardian,
          tab: 4,
          initialSeekerBasic: !guardian,
          initialGuardianBasic: guardian,
          seekerMembership: guardian ? 'Seeker One' : 'Seeker Basic',
          guardianMembership: guardian ? 'Guardian Basic' : 'Guardian One',
        );
        await h.tap('concept_membership');
        h.assertPage('one_upgrade');
        expect(find.text('$role One'), findsOneWidget);
        expect(find.text('BASIC'), findsOneWidget);
        expect(find.text('ONE'), findsOneWidget);
        final visible = guardian ? guardianVisible : seekerVisible;
        final hidden = guardian ? guardianHidden : seekerHidden;
        final card = _key('one-upgrade-comparison');
        double lastY = 0;
        for (final row in visible) {
          final label = find.descendant(of: card, matching: find.text(row));
          expect(label, findsOneWidget);
          final top = tester.getTopLeft(label).dy;
          expect(top, greaterThan(lastY));
          lastY = top;
        }
        for (final row in hidden) {
          expect(
            find.descendant(of: card, matching: find.text(row)),
            findsNothing,
          );
        }
        expect(find.text('Overall score'), findsOneWidget);
        expect(find.text('Every topic'), findsOneWidget);
        if (!guardian) {
          expect(find.text('Age and location'), findsOneWidget);
          expect(find.text('All filters'), findsOneWidget);
        }
        expect(find.textContaining('days free'), findsNothing);
        expect(find.textContaining('£'), findsNothing);
        expect(find.text('Coming later'), findsOneWidget);
        await _capture(h, guardian ? 'guardian-one' : 'seeker-one');

        await h.tap('one-upgrade-continue');
        expect(find.text(ZyraMembershipCatalog.availability), findsOneWidget);
        await _capture(
          h,
          guardian ? 'guardian-unavailable' : 'seeker-unavailable',
        );
        await h.tapText('OK');
        expect(find.byType(ZyraOneUpgradePage), findsOneWidget);
        await h.tapText('Not now');
        expect(find.byType(ZyraOneUpgradePage), findsNothing);
        expect(h.latest.tab, 4);
        await h.tap('concept_membership');
        await tester.tap(find.byTooltip('Back'));
        await h.flush();
        expect(find.byType(ZyraOneUpgradePage), findsNothing);
      },
    );

    testWidgets('$role One Profile keeps membership management', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = BaselineHarness(tester, group: 'lock25');
      await h.mount(guardian: guardian, tab: 4);
      await h.tap('concept_membership');
      h.assertPage('membership');
      expect(find.byType(ZyraOneUpgradePage), findsNothing);
    });
  }

  testWidgets(
    'actual Profiles card uses Design 2 and still advances to photo one',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = BaselineHarness(tester, group: 'lock25');
      await h.mount();
      final details = find.byType(ZyraProfileDetailsPage);
      expect(details, findsOneWidget);
      final profile = tester.widget<ZyraProfileDetailsPage>(details).profile;
      final avatar = _key('concept_browse_details_avatar_${profile.id}');
      expect(tester.getSize(avatar), const Size.square(124));
      expect(profile.photos, isNotEmpty);
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget as Image;
        await tester.runAsync(() => precacheImage(image.image, element));
      }
      await _capture(h, 'profiles-details-design-2');
      tester.view.physicalSize = const Size(1125, 2001);
      await h.flush();
      expect(tester.getSize(avatar), const Size.square(124));
      final ethnicity = _key('profile-detail-tile-ETHNICITY');
      await tester.ensureVisible(ethnicity);
      await h.flush();
      expect(
        tester.getBottomRight(ethnicity).dy,
        lessThanOrEqualTo(tester.getBottomRight(details).dy),
      );
      expect(tester.takeException(), isNull);
      await tester.tapAt(tester.getTopRight(details) + const Offset(-45, 48));
      await h.flush();
      expect(
        _key('concept_browse_details_avatar_${profile.id}').hitTestable(),
        findsNothing,
      );
    },
  );

  testWidgets('both locked Guardian tiles open Guardian One', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = BaselineHarness(tester, group: 'lock25');
    await h.mount(
      guardian: true,
      tab: 2,
      initialGuardianBasic: true,
      guardianMembership: 'Guardian Basic',
    );
    for (final id in ['guardian_connect', 'guardian_introductions']) {
      await h.tap(id);
      h.assertPage('one_upgrade');
      expect(find.text('Guardian One'), findsOneWidget);
      await h.tapText('Not now');
    }
  });

  testWidgets('ordinary upgrades use the same page for both roles', (
    tester,
  ) async {
    AppState.instance.resetForAccountChange();
    addTearDown(AppState.instance.resetForAccountChange);
    for (final surface in [
      ZyraTelemetrySurface.seeker,
      ZyraTelemetrySurface.guardian,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(surface),
          home: UpgradeScreen.compare(telemetrySurface: surface),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ZyraOneUpgradePage>(find.byType(ZyraOneUpgradePage))
            .guardian,
        surface == ZyraTelemetrySurface.guardian,
      );
      expect(find.text('Compatibility score'), findsNothing);
      expect(find.text('Overall score'), findsNothing);
      expect(find.text('Every topic'), findsNothing);
    }
  });

  testWidgets(
    'larger text scrolls the comparison and keeps actions on screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              padding: const EdgeInsets.only(top: 24, bottom: 20),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: ZyraOneUpgradePage(
              guardian: false,
              canContinue: () => true,
              onBack: () {},
            ),
          ),
        ),
      );
      final card = _key('one-upgrade-comparison');
      expect(find.text('Compatibility score'), findsNothing);
      expect(find.text('Filters'), findsNothing);
      final scrollable = find.descendant(
        of: card,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0));
      final button = _key('one-upgrade-continue');
      final before = tester.getCenter(button);
      await tester.drag(card, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(tester.getCenter(button), before);
      expect(find.text('Not now').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Guardian monogram only draws and announces the verified One ring',
    (tester) async {
      final semantics = tester.ensureSemantics();
      const one = ValueKey('guardian-one');
      const basic = ValueKey('guardian-basic');
      await tester.pumpWidget(
        const MaterialApp(
          home: Row(
            children: [
              ZyraGoldRingMonogram(
                key: one,
                name: 'Hassan',
                size: 48,
                fontSize: 19,
                guardianOne: true,
              ),
              ZyraGoldRingMonogram(
                key: basic,
                name: 'Yusuf',
                size: 48,
                fontSize: 19,
                guardianOne: false,
              ),
            ],
          ),
        ),
      );
      BoxDecoration decoration(Key key) =>
          tester
                  .widget<Container>(
                    find.descendant(
                      of: find.byKey(key),
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      expect((decoration(one).border as Border).top.width, 1);
      expect(decoration(basic).border, isNull);
      expect(decoration(basic).color, ZyraColors.ivoryTop);
      expect(find.bySemanticsLabel('Hassan, Guardian One'), findsOneWidget);
      expect(find.bySemanticsLabel('Yusuf, Guardian One'), findsNothing);
      semantics.dispose();
    },
  );
}
