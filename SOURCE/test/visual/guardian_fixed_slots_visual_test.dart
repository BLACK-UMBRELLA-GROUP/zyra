// Fresh review candidates only. Never updates the approved visual baselines.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';

const _capture = bool.fromEnvironment('ZYRA_GUARDIAN_FIXED_SLOTS_CAPTURE');
const _root = ValueKey('guardian-fixed-slots-candidate');

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsAudit');
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
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsAudit';
  });

  setUp(() {
    ZyraDevScenario.instance.reset();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraInteractionStyle.restoreDefaults();
    ZyraText.restoreAppFont(null);
  });

  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance.reset();
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  final mainGuardian = WaliLinkedPerson(
    id: 'main',
    firstName: 'Abdul',
    relationship: 'father',
    isMain: true,
    linkedAt: DateTime.utc(2026, 7, 12),
  );
  final additionalGuardian = WaliLinkedPerson(
    id: 'additional',
    firstName: 'Hassan',
    relationship: 'brother',
    linkedAt: DateTime.utc(2026, 7, 13),
  );

  Widget subject(int activeJourneyCount) => MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(
      body: RepaintBoundary(
        key: _root,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                child: SeekerGuardianPage(
                  people: [mainGuardian, additionalGuardian],
                  activity: const {},
                  linksAvailable: true,
                  activityAvailable: true,
                  onRetry: () {},
                  onAdd: () {},
                  onOpenMessages: () {},
                  historyConsentPreview: true,
                  previewActiveJourneyCount: activeJourneyCount,
                  comparisonNow: DateTime.utc(2026, 9, 27),
                ),
              ),
              FloatingNavBar(
                key: const ValueKey('guardian-candidate-nav'),
                currentIndex: 3,
                onTap: (_) {},
                items: const [
                  FloatingNavItem(icon: Icons.search, label: 'Browse'),
                  FloatingNavItem(
                    icon: Icons.bookmark_border,
                    label: 'Connections',
                  ),
                  FloatingNavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'My ZYRA',
                  ),
                  FloatingNavItem(
                    icon: Icons.gpp_good_outlined,
                    label: 'Guardian',
                  ),
                  FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  const viewports = [
    (
      name: 'standard',
      size: Size(390, 844),
      padding: FakeViewPadding(top: 47, bottom: 34),
    ),
    (name: 'compact', size: Size(320, 568), padding: FakeViewPadding(top: 20)),
    (
      name: 'large',
      size: Size(430, 932),
      padding: FakeViewPadding(top: 59, bottom: 34),
    ),
  ];

  for (final viewport in viewports) {
    for (final activeJourneyCount in [0, 1, 3]) {
      for (final additional in [false, true]) {
        final guardianKind = additional ? 'additional' : 'main';
        testWidgets(
          '$guardianKind with $activeJourneyCount Journeys ${viewport.name}',
          (tester) async {
            tester.view.physicalSize = viewport.size;
            tester.view.devicePixelRatio = 1;
            tester.view.padding = viewport.padding;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPadding);
            await tester.pumpWidget(subject(activeJourneyCount));
            await tester.pumpAndSettle();
            if (additional) {
              await tester.drag(
                find.byKey(const ValueKey('guardian-page-view')),
                Offset(-viewport.size.width * .9, 0),
              );
              await tester.pumpAndSettle();
            }
            expect(find.text(additional ? 'Hassan' : 'Abdul'), findsOneWidget);
            expect(
              find.byKey(ValueKey('guardian-page-static-$guardianKind')),
              findsOneWidget,
            );
            expect(find.byType(SingleChildScrollView), findsNothing);
            expect(find.text('View'), findsOneWidget);
            expect(find.text('Chat'), findsOneWidget);
            expect(
              find.text('Awaiting a Journey'),
              findsNWidgets(3 - activeJourneyCount),
            );
            for (var slot = activeJourneyCount; slot < 3; slot++) {
              expect(
                find.byKey(ValueKey('guardian-journey-pending-row-$slot')),
                findsOneWidget,
              );
              expect(
                find.byKey(ValueKey('guardian-journey-pending-view-$slot')),
                findsOneWidget,
              );
              expect(
                find.byKey(ValueKey('guardian-journey-pending-chat-$slot')),
                findsOneWidget,
              );
            }
            if (activeJourneyCount == 0) {
              expect(find.text('NO ACTIVE JOURNEYS'), findsNothing);
            }
            expect(
              find.byKey(const ValueKey('guardian-remove')).hitTestable(),
              findsOneWidget,
              reason: 'Manage must remain visible above the reserved nav area.',
            );
            expect(
              find.byKey(const ValueKey('guardian-candidate-nav')),
              findsOneWidget,
            );
            expect(
              tester
                  .getBottomLeft(find.byKey(const ValueKey('guardian-remove')))
                  .dy,
              lessThan(
                tester
                    .getTopLeft(
                      find.byKey(const ValueKey('guardian-candidate-nav')),
                    )
                    .dy,
              ),
              reason: 'The last Manage action cannot overlap navigation.',
            );
            expect(tester.takeException(), isNull);
            if (_capture) {
              await expectLater(
                find.byKey(_root),
                matchesGoldenFile(
                  'candidates/guardian_fixed_slots_2026_09_27/${guardianKind}_${activeJourneyCount}_journeys_${viewport.name}.png',
                ),
              );
            }
          },
        );
      }
    }
  }
}
